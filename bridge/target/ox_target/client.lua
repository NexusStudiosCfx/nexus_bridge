--[[
    ox_target adapter. Written against ox_target 1.18.1 (client/api.lua); see docs/adapters.md.

    ox_target files an option under the resource that called its export, and removes by option
    name within that resource. The names the module hands over are already unique, so they are
    passed through. A select callback receives one table there; the entity is taken out of it.
]]

local ox = exports.ox_target

local GLOBALS = {
    player = { add = 'addGlobalPlayer', remove = 'removeGlobalPlayer' },
    vehicle = { add = 'addGlobalVehicle', remove = 'removeGlobalVehicle' },
    ped = { add = 'addGlobalPed', remove = 'removeGlobalPed' },
    object = { add = 'addGlobalObject', remove = 'removeGlobalObject' },
}

local function icon(name)
    if not name then return nil end
    -- A bare name gets the solid style; a full class list is used as it is.
    return name:find(' ', 1, true) and name or ('fa-solid ' .. name)
end

local function convert(options)
    local out, names = {}, {}
    for index, option in ipairs(options) do
        names[index] = option.name
        out[index] = {
            name = option.name,
            label = option.label,
            icon = icon(option.icon),
            distance = option.distance,
            canInteract = option.can,
            onSelect = function(data)
                option.select(type(data) == 'table' and data.entity or nil)
            end,
        }
    end
    return out, names
end

local target = {
    caps = { eye = true, boxes = true, entities = true, models = true, globals = true },
}

-- A zone is removed by its name, which is ours alone, and not by the number ox_target hands
-- out: after a restart of ox_target that number may belong to another resource's zone.
function target.addSphere(entry)
    local options = convert(entry.options)
    ox:addSphereZone({ name = entry.name, coords = entry.coords, radius = entry.radius, debug = entry.debug, options = options })
    return { zone = entry.name }
end

function target.addBox(entry)
    local options = convert(entry.options)
    ox:addBoxZone({ name = entry.name, coords = entry.coords, size = entry.size, rotation = entry.heading, debug = entry.debug, options = options })
    return { zone = entry.name }
end

function target.addEntity(entry)
    local options, names = convert(entry.options)
    if entry.netId then
        ox:addEntity(entry.netId, options)
    else
        ox:addLocalEntity(entry.entity, options)
    end
    return { names = names, netId = entry.netId }
end

function target.addModel(entry)
    local options, names = convert(entry.options)
    ox:addModel(entry.models, options)
    return { names = names }
end

function target.addGlobal(entry)
    local options, names = convert(entry.options)
    ox[GLOBALS[entry.type].add](ox, options)
    return { names = names }
end

function target.remove(entry, handle)
    if handle.zone then
        ox:removeZone(handle.zone, true)
    elseif entry.kind == 'entity' then
        -- Names are always given: without them ox_target drops the options of every resource.
        if handle.netId then
            ox:removeEntity(handle.netId, handle.names)
        else
            ox:removeLocalEntity(entry.entity, handle.names)
        end
    elseif entry.kind == 'model' then
        ox:removeModel(entry.models, handle.names)
    elseif entry.kind == 'global' then
        ox[GLOBALS[entry.type].remove](ox, handle.names)
    end
end

function target.disable(state)
    ox:disableTargeting(state)
end

return target
