--[[
    sleepless_interact adapter. Written against sleepless_interact 2.4.1 (client/api.lua); see
    docs/adapters.md.

    It is a prompt next to the thing, not an eye, and it knows points but no sized zones: a
    sphere becomes a point that can be used from its radius, a box a point at its centre that
    can be used from half its longer side. Its option format follows ox_target's.
]]

local interact = exports.sleepless_interact

local GLOBALS = {
    player = { add = 'addGlobalPlayer', remove = 'removeGlobalPlayer' },
    vehicle = { add = 'addGlobalVehicle', remove = 'removeGlobalVehicle' },
    ped = { add = 'addGlobalPed', remove = 'removeGlobalPed' },
    object = { add = 'addGlobalObject', remove = 'removeGlobalObject' },
}

local function icon(name)
    if not name then return nil end
    return name:find(' ', 1, true) and name or ('fa-solid ' .. name)
end

local function convert(options, reach)
    local out, names = {}, {}
    for index, option in ipairs(options) do
        names[index] = option.name
        out[index] = {
            name = option.name,
            label = option.label,
            icon = icon(option.icon),
            distance = reach or option.distance,
            canInteract = option.can,
            onSelect = function(data)
                option.select(type(data) == 'table' and data.entity or nil)
            end,
        }
    end
    return out, names
end

local target = {
    caps = { entities = true, models = true, globals = true },
}

local function addPoint(entry, reach)
    local options, names = convert(entry.options, reach)
    return { point = interact:addCoords(entry.coords, options), names = names }
end

function target.addSphere(entry)
    return addPoint(entry, entry.radius)
end

function target.addBox(entry)
    return addPoint(entry, math.max(entry.size.x, entry.size.y) / 2)
end

function target.addEntity(entry)
    local options, names = convert(entry.options)
    if entry.netId then
        interact:addEntity(entry.netId, options)
    else
        interact:addLocalEntity(entry.entity, options)
    end
    return { names = names, netId = entry.netId }
end

function target.addModel(entry)
    local options, names = convert(entry.options)
    interact:addModel(entry.models, options)
    return { names = names }
end

function target.addGlobal(entry)
    local options, names = convert(entry.options)
    interact[GLOBALS[entry.type].add](interact, options)
    return { names = names }
end

function target.remove(entry, handle)
    if handle.point then
        -- Two resources at the same coordinates share one point there: only our options go.
        interact:removeCoords(handle.point, handle.names)
    elseif entry.kind == 'entity' then
        if handle.netId then
            interact:removeEntity(handle.netId, handle.names)
        else
            interact:removeLocalEntity(entry.entity, handle.names)
        end
    elseif entry.kind == 'model' then
        interact:removeModel(entry.models, handle.names)
    elseif entry.kind == 'global' then
        interact[GLOBALS[entry.type].remove](interact, handle.names)
    end
end

function target.disable(state)
    interact:disableInteract(state)
end

return target
