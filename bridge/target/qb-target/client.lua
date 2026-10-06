--[[
    qb-target adapter. Written against qb-target 5.5.0 (registration.lua, client.lua); see
    docs/adapters.md.

    What differs from ox_target, and is handled here:
      - options are filed and removed by their label, for all resources together, so two
        options with the same label on the same entity or model replace each other;
      - one set of options is offered at a time: an entity's own, else its model's (or the
        player options), else the ones for every vehicle, ped or object, else a zone's;
      - nothing is removed when the resource that added it stops: the module does that;
      - canInteract runs outside pcall there, and one that raises stops the targeting loop,
        so it is wrapped;
      - zone names are shared by every resource, and a zone that is added again under a name
        in use is not destroyed first: every zone gets a name of its own.
]]

local qb = exports['qb-target']

local GLOBALS = {
    player = { add = 'AddGlobalPlayer', remove = 'RemoveGlobalPlayer' },
    vehicle = { add = 'AddGlobalVehicle', remove = 'RemoveGlobalVehicle' },
    ped = { add = 'AddGlobalPed', remove = 'RemoveGlobalPed' },
    object = { add = 'AddGlobalObject', remove = 'RemoveGlobalObject' },
}

local function icon(name)
    if not name then return nil end
    return name:find(' ', 1, true) and name or ('fas ' .. name)
end

--- The options in qb-target's form, their labels (its removal key) and the widest distance,
--- which caps every option of the group there.
local function convert(options)
    local out, labels, reach = {}, {}, 0.0
    for index, option in ipairs(options) do
        labels[index] = option.label
        if option.distance > reach then reach = option.distance end
        local can = option.can
        out[index] = {
            label = option.label,
            icon = icon(option.icon),
            distance = option.distance,
            action = function(entity)
                option.select(type(entity) == 'number' and entity or nil)
            end,
            canInteract = can and function(entity, distance)
                local ok, allowed = pcall(can, entity, distance)
                return ok and allowed == true
            end or nil,
        }
    end
    return { options = out, distance = reach }, labels
end

local target = {
    caps = { eye = true, boxes = true, entities = true, models = true, globals = true },
}

function target.addSphere(entry)
    qb:AddCircleZone(entry.name, entry.coords, entry.radius, { name = entry.name, debugPoly = entry.debug, useZ = true }, (convert(entry.options)))
    return { zone = entry.name }
end

function target.addBox(entry)
    local half = entry.size.z / 2
    -- PolyZone measures width along x and length along y.
    qb:AddBoxZone(entry.name, entry.coords, entry.size.y, entry.size.x, {
        name = entry.name,
        heading = entry.heading,
        debugPoly = entry.debug,
        minZ = entry.coords.z - half,
        maxZ = entry.coords.z + half,
    }, (convert(entry.options)))
    return { zone = entry.name }
end

function target.addEntity(entry)
    local parameters, labels = convert(entry.options)
    qb:AddTargetEntity(entry.entity, parameters)
    return { labels = labels }
end

function target.addModel(entry)
    local parameters, labels = convert(entry.options)
    qb:AddTargetModel(entry.models, parameters)
    return { labels = labels }
end

function target.addGlobal(entry)
    local parameters, labels = convert(entry.options)
    if entry.type == 'ped' then
        -- qb-target counts players among the peds; a 'ped' option here is for the game's own.
        for _, option in ipairs(parameters.options) do
            local can = option.canInteract
            option.canInteract = function(entity, distance)
                if IsPedAPlayer(entity) then return false end
                return can == nil or can(entity, distance)
            end
        end
    end
    qb[GLOBALS[entry.type].add](qb, parameters)
    return { labels = labels }
end

function target.remove(entry, handle)
    if handle.zone then
        qb:RemoveZone(handle.zone)
    elseif entry.kind == 'entity' then
        -- Labels are always given: without them qb-target wipes the entity for everybody.
        qb:RemoveTargetEntity(entry.entity, handle.labels)
    elseif entry.kind == 'model' then
        qb:RemoveTargetModel(entry.models, handle.labels)
    elseif entry.kind == 'global' then
        qb[GLOBALS[entry.type].remove](qb, handle.labels)
    end
end

function target.disable(state)
    qb:AllowTargeting(not state)
end

return target
