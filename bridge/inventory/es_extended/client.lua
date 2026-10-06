--[[
    The plain ESX inventory, client. Written against ESX Legacy 1.15.2; see docs/adapters.md.

    The player's inventory there is a list with one entry per item the server defines, also
    the ones the player has none of. So the same list answers "what does the player carry"
    and "does this item exist, and what is it called". There are no pictures.
]]

local ESX = nil

local function list()
    ESX = ESX or exports['es_extended']:getSharedObject()
    local data = ESX.GetPlayerData and ESX.GetPlayerData() or nil
    return type(data) == 'table' and type(data.inventory) == 'table' and data.inventory or {}
end

local function entry(name)
    for _, item in ipairs(list()) do
        if item.name == name then return item end
    end
    return nil
end

local inventory = { caps = {} }

function inventory.exists(name)
    return entry(name) ~= nil
end

function inventory.label(name)
    local item = entry(name)
    return item and item.label or name
end

function inventory.items()
    local out = {}
    for _, item in ipairs(list()) do
        local count = math.floor(tonumber(item.count) or 0)
        if type(item.name) == 'string' and count > 0 then
            out[#out + 1] = { name = item.name, label = item.label or item.name, count = count, metadata = {} }
        end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    for index, item in ipairs(out) do item.slot = index end
    return out
end

function inventory.count(name)
    local item = entry(name)
    return item and item.count or 0
end

return inventory
