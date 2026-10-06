--[[
    qb-inventory adapter, client. Written against qb-inventory 2.2.3 and qb-core 1.3.0; see
    docs/adapters.md.

    Item definitions are QBCore's shared item list, and what the player carries is in the
    player data the framework module already keeps. Pictures are files of the inventory:
    nui://<inventory>/html/images/<the image the item names>.
]]

local h = ...
local Bridge = h.bridge
local resource = h.adapterResource or 'qb-inventory'

local shared = nil

--- QBCore's item list. A copy: fetched again when qb-core says its shared data changed.
local function definitions()
    if not shared then
        local core = exports['qb-core']:GetCoreObject()
        shared = core and core.Shared and core.Shared.Items or {}
    end
    return shared
end

h.on('QBCore:Client:UpdateObject', function() shared = nil end)

local function definition(name)
    return type(name) == 'string' and definitions()[name:lower()] or nil
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
    local data = Bridge.framework.getPlayerData()
    for _, held in pairs(type(data) == 'table' and type(data.items) == 'table' and data.items or {}) do
        if type(held) == 'table' and type(held.name) == 'string' and (tonumber(held.amount) or 0) > 0 then
            out[#out + 1] = {
                slot = tonumber(held.slot),
                name = held.name,
                label = held.label or label(held.name),
                count = math.floor(tonumber(held.amount) or 0),
                metadata = type(held.info) == 'table' and held.info or {},
                image = image(held.name),
            }
        end
    end
    table.sort(out, function(a, b) return (a.slot or 0) < (b.slot or 0) end)
    return out
end

return inventory
