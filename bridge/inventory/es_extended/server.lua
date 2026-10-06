--[[
    The plain ESX inventory (the one inside es_extended), server. Written against ESX Legacy
    1.15.2; docs/adapters.md lists every call. Served only when no other inventory runs: with
    ox_inventory on an ESX server, the ox_inventory adapter is the one in use.

    What to know about it:
      - an item is a name and a count. There are no slots, no metadata and no stashes;
      - "slot" here is the item's place in the list of what the player carries, sorted by
        name. It is good for picking a stack in a menu; removal is by name and count;
      - an add that asks for metadata is refused: the inventory could not keep it;
      - removeInventoryItem raises for a count that is not above zero, and older releases
        answer nothing at all, so the count before and after decides.
]]

local h = ...
local Bridge = h.bridge

local definitions, fetched = nil, -100000

local function read(ESX)
    return ESX.GetItems and ESX.GetItems() or ESX.Items or {}
end

--- The item list of the server. Asked for again when a name is missing: an owner may have
--- added items since.
local function definition(name)
    if type(name) ~= 'string' then return nil end
    if definitions and definitions[name] then return definitions[name] end
    if GetGameTimer() - fetched < 5000 then return nil end
    local ESX = Bridge.framework.core()
    if not ESX then return nil end

    local items = read(ESX)
    -- ESX reads its items from the database after it has started, and tells nobody when it
    -- is done. An empty list in the first seconds means "not yet": wait for it, where the
    -- caller is somewhere that can wait (a thread, an event handler).
    if next(items) == nil and coroutine.isyieldable() then
        local deadline = GetGameTimer() + 10000
        while next(items) == nil and GetGameTimer() < deadline do
            Wait(100)
            items = read(ESX)
        end
    end
    if next(items) == nil then return nil end

    definitions, fetched = items, GetGameTimer()
    return definitions[name]
end

local function label(name)
    local item = definition(name)
    return item and item.label or name
end

local function playerOf(inv)
    return type(inv) == 'number' and Bridge.framework.getPlayer(inv) or nil
end

local function held(xPlayer, name)
    local item = xPlayer.getInventoryItem(name)
    return item and math.floor(tonumber(item.count) or 0) or 0
end

local function list(inv)
    local xPlayer = playerOf(inv)
    local out = {}
    if not xPlayer then return out end
    for _, item in pairs(xPlayer.getInventory() or {}) do
        local count = math.floor(tonumber(item.count) or 0)
        if type(item.name) == 'string' and count > 0 then
            out[#out + 1] = {
                name = item.name,
                label = item.label or label(item.name),
                count = count,
                metadata = {},
                weight = (tonumber(item.weight) or 0) * count,
            }
        end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    for index, item in ipairs(out) do item.slot = index end
    return out
end

local function take(xPlayer, name, count)
    local before = held(xPlayer, name)
    if before < count then return false end
    pcall(xPlayer.removeInventoryItem, name, count)
    return before - held(xPlayer, name) >= count
end

local inventory = {
    caps = { weight = true, usableItems = true },
    label = label,
    items = list,
}

function inventory.weight(name)
    local item = definition(name)
    return item and tonumber(item.weight) or 0
end

function inventory.exists(name)
    return definition(name) ~= nil
end

function inventory.slot(inv, slot)
    return list(inv)[slot]
end

function inventory.count(inv, name)
    local xPlayer = playerOf(inv)
    return xPlayer and definition(name) and held(xPlayer, name) or 0
end

function inventory.canCarry(inv, name, count)
    local xPlayer = playerOf(inv)
    if not xPlayer or not definition(name) then return false end
    if not xPlayer.canCarryItem then return true end
    return xPlayer.canCarryItem(name, count) == true
end

function inventory.add(inv, name, count, metadata)
    local xPlayer = playerOf(inv)
    if not xPlayer or not definition(name) then return false end
    if type(metadata) == 'table' and next(metadata) ~= nil then
        h.once('metadata', ('%s gave "%s" metadata, which the plain ESX inventory cannot keep: the item was not added. Check Bridge.inventory.supports(\'metadata\') first.'):format(h.resource, name))
        return false
    end
    local before = held(xPlayer, name)
    pcall(xPlayer.addInventoryItem, name, count)
    return held(xPlayer, name) - before >= count
end

function inventory.remove(inv, name, count)
    local xPlayer = playerOf(inv)
    if not xPlayer or not definition(name) then return false end
    return take(xPlayer, name, count)
end

function inventory.removeSlot(inv, slot, name, count)
    local xPlayer = playerOf(inv)
    local item = xPlayer and list(inv)[slot]
    if not item or item.name ~= name or item.count < count then return false end
    return take(xPlayer, name, count)
end

function inventory.clear(inv, keep)
    local xPlayer = playerOf(inv)
    if not xPlayer then return false end
    local kept = {}
    for _, name in ipairs(type(keep) == 'table' and keep or { keep }) do kept[name] = true end
    for _, item in ipairs(list(inv)) do
        if not kept[item.name] then take(xPlayer, item.name, item.count) end
    end
    return true
end

return inventory
