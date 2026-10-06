--[[
    ox_inventory adapter, server. Written against ox_inventory 2.47.9 (overextended) and 2.45.0
    (CommunityOx); docs/adapters.md lists every call.

    What to know about ox_inventory:
      - AddItem does not look at the weight (ask canCarry first), and for an item that does
        not stack it fills one slot each: when the slots run out it adds fewer and still
        answers true. The slots it returns are counted here, and a partial add is taken back;
      - RemoveItem with a slot removes from another stack, on one of the two lines of
        development, when that slot does not hold the item. So the slot is read first;
      - SetMetadata replaces the whole table;
      - an item may carry a weight of its own in its metadata (`weight`). Carried, that is
        added to what the item weighs; asked whether it fits, CanCarryItem takes it for the
        whole weight. So the question is asked with both added up;
      - an item used through the framework's usable items only reaches a script when its
        definition has no `consume` and no export of its own.
]]

local h = ...
local ox = exports.ox_inventory
local imagePath = GetConvar('inventory:imagepath', 'nui://ox_inventory/web/images')

local function definition(name)
    if type(name) ~= 'string' then return nil end
    local item = ox:Items(name)
    return type(item) == 'table' and item or nil
end

local function label(name)
    local item = definition(name)
    return item and item.label or name
end

--- The picture the inventory itself would show: a slot may carry its own, else the item's.
local function image(name, metadata)
    if type(metadata) == 'table' then
        if type(metadata.imageurl) == 'string' and metadata.imageurl:match('^https?://') then return metadata.imageurl end
        if type(metadata.image) == 'string' and metadata.image ~= '' then return ('%s/%s.png'):format(imagePath, metadata.image) end
    end
    return ('%s/%s.png'):format(imagePath, name)
end

local function toItem(held)
    if type(held) ~= 'table' or type(held.name) ~= 'string' then return nil end
    local metadata = type(held.metadata) == 'table' and held.metadata or {}
    return {
        slot = held.slot,
        name = held.name,
        label = held.label or label(held.name),
        count = math.floor(tonumber(held.count) or 0),
        metadata = metadata,
        weight = tonumber(held.weight) or 0,
        image = image(held.name, metadata),
    }
end

local inventory = {
    caps = { metadata = true, slots = true, stashes = true, weight = true, images = true, usableItems = true },
    label = label,
    image = image,
}

function inventory.exists(name)
    return definition(name) ~= nil
end

function inventory.items(inv)
    local out = {}
    for _, held in pairs(ox:GetInventoryItems(inv) or {}) do
        local item = toItem(held)
        if item and item.count > 0 then out[#out + 1] = item end
    end
    table.sort(out, function(a, b) return (a.slot or 0) < (b.slot or 0) end)
    return out
end

function inventory.slot(inv, slot)
    return toItem(ox:GetSlot(inv, slot))
end

function inventory.count(inv, name)
    return ox:GetItemCount(inv, name) or 0
end

function inventory.weight(name)
    local item = definition(name)
    return item and tonumber(item.weight) or 0
end

function inventory.canCarry(inv, name, count, metadata)
    local asked = metadata
    if type(metadata) == 'table' and tonumber(metadata.weight) then
        asked = {}
        for key, value in pairs(metadata) do asked[key] = value end
        asked.weight = tonumber(metadata.weight) + inventory.weight(name)
    end
    return ox:CanCarryItem(inv, name, count, asked) == true
end

function inventory.add(inv, name, count, metadata)
    local ok, response = ox:AddItem(inv, name, count, metadata)
    if ok ~= true then return false end
    -- A list of slots means the item does not stack: each slot holds one of them.
    if type(response) == 'table' and response[1] ~= nil then
        local arrived = 0
        for _, held in ipairs(response) do arrived = arrived + (tonumber(held.count) or 1) end
        if arrived < count then
            for _, held in ipairs(response) do
                ox:RemoveItem(inv, name, tonumber(held.count) or 1, nil, held.slot)
            end
            return false
        end
    end
    return true
end

function inventory.remove(inv, name, count)
    return ox:RemoveItem(inv, name, count) == true
end

function inventory.removeSlot(inv, slot, name, count)
    local held = ox:GetSlot(inv, slot)
    if type(held) ~= 'table' or held.name ~= name or (tonumber(held.count) or 0) < count then return false end
    return ox:RemoveItem(inv, name, count, nil, slot) == true
end

function inventory.setMetadata(inv, slot, metadata)
    if type(ox:GetSlot(inv, slot)) ~= 'table' then return false end
    ox:SetMetadata(inv, slot, metadata)
    return true
end

function inventory.clear(inv, keep)
    ox:ClearInventory(inv, keep)
    return true
end

function inventory.registerStash(id, options)
    ox:RegisterStash(id, options.label or id, math.floor(tonumber(options.slots) or 50), math.floor(tonumber(options.weight) or 100000))
    return true
end

function inventory.openStash(src, id, options)
    inventory.registerStash(id, options)
    return ox:forceOpenInventory(src, 'stash', id) ~= nil
end

inventory.stashItems = inventory.items

function inventory.clearStash(id)
    ox:ClearInventory(id)
    return true
end

--- A consumable that was used up: ox_inventory says so by itself.
function inventory.listen(used)
    h.on('ox_inventory:usedItem', function(playerId, name, slot, metadata)
        used(playerId, name, slot, metadata)
    end)
end

return inventory
