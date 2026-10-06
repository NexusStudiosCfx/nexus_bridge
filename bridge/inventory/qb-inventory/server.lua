--[[
    qb-inventory adapter, server. Written against qb-inventory 2.2.3; docs/adapters.md lists
    every call. Version 1 kept its items inside qb-core and is not served by this adapter.

    What to know about qb-inventory:
      - AddItem puts an item that is not unique onto the FIRST stack of that item and keeps
        the metadata that stack already had: what was passed is lost. So the slot is chosen
        here: a stack with exactly this metadata, else a free slot;
      - a unique item given with an amount lands in one slot holding that amount. Unique
        items are added one per slot here, and taken back when not all of them fit;
      - RemoveItem without a slot only looks at the first stack. Removing by name therefore
        goes stack by stack (the module does that);
      - metadata is called `info`, a count `amount`;
      - several exports index the player without checking that there is one.
]]

local h = ...
local Bridge = h.bridge
local resource = h.adapterResource or 'qb-inventory'
local qb = exports[resource]

local major = tonumber(tostring(GetResourceMetadata(resource, 'version', 0) or ''):match('^(%d+)'))
if major and major < 2 then
    error(('%s %s is version 1, which keeps items inside qb-core: update it to 2.x'):format(resource, GetResourceMetadata(resource, 'version', 0)))
end

local function definition(name)
    if type(name) ~= 'string' then return nil end
    local core = Bridge.framework.core()
    local items = core and core.Shared and core.Shared.Items
    return items and items[name:lower()] or nil
end

local function label(name)
    local item = definition(name)
    return item and item.label or name
end

local function image(name)
    local item = definition(name)
    if not item then return nil end
    return ('nui://%s/html/images/%s'):format(resource, item.image or (name .. '.png'))
end

local function same(a, b)
    a, b = type(a) == 'table' and a or {}, type(b) == 'table' and b or {}
    for key, value in pairs(a) do
        if b[key] ~= value then return false end
    end
    for key in pairs(b) do
        if a[key] == nil then return false end
    end
    return true
end

--- The raw items of a player or a stash, and how many slots it has; nil when there is none.
local function read(inv)
    if type(inv) == 'number' then
        local player = Bridge.framework.getPlayer(inv)
        if not player then return nil end
        local used, free = qb:GetSlots(inv)
        return player.PlayerData.items or {}, (tonumber(used) or 0) + (tonumber(free) or 0)
    end
    local stash = qb:GetInventory(inv)
    if type(stash) ~= 'table' then return nil end
    return stash.items or {}, tonumber(stash.slots) or 0
end

local function toItem(held)
    if type(held) ~= 'table' or type(held.name) ~= 'string' then return nil end
    return {
        slot = tonumber(held.slot),
        name = held.name,
        label = held.label or label(held.name),
        count = math.floor(tonumber(held.amount) or 0),
        metadata = type(held.info) == 'table' and held.info or {},
        weight = (tonumber(held.weight) or 0) * (tonumber(held.amount) or 0),
        image = image(held.name),
    }
end

local inventory = {
    caps = { metadata = true, slots = true, stashes = true, weight = true, images = true, usableItems = true },
    label = label,
    image = image,
}

function inventory.weight(name)
    local item = definition(name)
    return item and tonumber(item.weight) or 0
end

function inventory.exists(name)
    return definition(name) ~= nil
end

function inventory.items(inv)
    local out = {}
    for _, held in pairs(read(inv) or {}) do
        local item = toItem(held)
        if item and item.count > 0 then out[#out + 1] = item end
    end
    table.sort(out, function(a, b) return (a.slot or 0) < (b.slot or 0) end)
    return out
end

function inventory.slot(inv, slot)
    for _, held in pairs(read(inv) or {}) do
        if tonumber(held.slot) == slot then return toItem(held) end
    end
    return nil
end

function inventory.canCarry(inv, name, count)
    if not definition(name) or not read(inv) then return false end
    return qb:CanAddItem(inv, name, count) == true
end

function inventory.add(inv, name, count, metadata)
    local item = definition(name)
    local items, capacity = read(inv)
    if not item or not items then return false end

    local taken = {}
    for _, held in pairs(items) do taken[tonumber(held.slot) or 0] = held end
    local function free()
        for slot = 1, capacity do
            if not taken[slot] then return slot end
        end
        return nil
    end

    if item.unique then
        local added = {}
        for _ = 1, count do
            local slot = free()
            if not slot or qb:AddItem(inv, name, 1, slot, metadata, h.resource) ~= true then
                for _, filled in ipairs(added) do qb:RemoveItem(inv, name, 1, filled, h.resource) end
                return false
            end
            taken[slot] = true
            added[#added + 1] = slot
        end
        return true
    end

    local slot = nil
    for _, held in pairs(items) do
        if held.name == name and same(held.info, metadata) then
            slot = tonumber(held.slot)
            break
        end
    end
    slot = slot or free()
    if not slot then return false end
    return qb:AddItem(inv, name, count, slot, metadata, h.resource) == true
end

function inventory.removeSlot(inv, slot, name, count)
    if not definition(name) or not read(inv) then return false end
    return qb:RemoveItem(inv, name, count, slot, h.resource) == true
end

--- Players only: the export reads the item from the player's data.
function inventory.setMetadata(inv, slot, metadata)
    if type(inv) ~= 'number' then return false end
    local held = inventory.slot(inv, slot)
    if not held then return false end
    return qb:SetItemData(inv, held.name, 'info', metadata, slot) == true
end

function inventory.clear(inv, keep)
    if not read(inv) then return false end
    if type(inv) == 'number' then
        qb:ClearInventory(inv, keep)
    else
        qb:ClearStash(inv)
    end
    return true
end

function inventory.registerStash(id, options)
    qb:CreateInventory(id, { label = options.label or id, slots = tonumber(options.slots) or 50, maxweight = tonumber(options.weight) or 100000 })
    return qb:GetInventory(id) ~= nil
end

--- OpenInventory answers nothing, also when the player's inventory is busy and it did not
--- open: true here means it was asked to.
function inventory.openStash(src, id, options)
    qb:OpenInventory(src, id, { label = options.label or id, slots = tonumber(options.slots) or 50, maxweight = tonumber(options.weight) or 100000 })
    return true
end

inventory.stashItems = inventory.items

function inventory.clearStash(id)
    if not qb:GetInventory(id) then return false end
    qb:ClearStash(id)
    return true
end

return inventory
