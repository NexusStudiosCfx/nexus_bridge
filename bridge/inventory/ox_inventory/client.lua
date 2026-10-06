--[[
    ox_inventory adapter, client. Written against ox_inventory 2.47.9 and 2.45.0; see
    docs/adapters.md.

    The picture of an item follows the same rule as the inventory's own page: a slot may carry
    its own (metadata.imageurl, metadata.image), an item definition may name one
    (client.image), and otherwise it is <imagepath>/<name>.png. Only the client knows
    client.image, which is why pictures are looked up on this side.
]]

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

local function image(name, metadata)
    if type(metadata) == 'table' then
        if type(metadata.imageurl) == 'string' and metadata.imageurl:match('^https?://') then return metadata.imageurl end
        if type(metadata.image) == 'string' and metadata.image ~= '' then return ('%s/%s.png'):format(imagePath, metadata.image) end
    end
    local item = definition(name)
    if not item then return nil end
    local own = type(item.client) == 'table' and item.client.image
    if type(own) == 'string' and own ~= '' then
        -- A full address is used as it is, a file name lies in the image folder.
        if own:match('^%a[%w+.-]*://') then return own end
        return ('%s/%s'):format(imagePath, own)
    end
    return ('%s/%s.png'):format(imagePath, name)
end

local inventory = {
    caps = { metadata = true, slots = true, images = true },
    label = label,
    image = image,
}

function inventory.exists(name)
    return definition(name) ~= nil
end

function inventory.items()
    local out = {}
    for _, held in pairs(ox:GetPlayerItems() or {}) do
        if type(held) == 'table' and type(held.name) == 'string' and (tonumber(held.count) or 0) > 0 then
            local metadata = type(held.metadata) == 'table' and held.metadata or {}
            out[#out + 1] = {
                slot = held.slot,
                name = held.name,
                label = held.label or label(held.name),
                count = math.floor(tonumber(held.count) or 0),
                metadata = metadata,
                image = image(held.name, metadata),
            }
        end
    end
    table.sort(out, function(a, b) return (a.slot or 0) < (b.slot or 0) end)
    return out
end

function inventory.count(name)
    return ox:GetItemCount(name) or 0
end

return inventory
