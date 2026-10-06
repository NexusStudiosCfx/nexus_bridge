--[[
    Bridge.target (client): options a player can use on a spot in the world, an entity, a model
    or every player, vehicle, ped or object. Served by the server's target resource, or by a
    key prompt when it has none.

      local id = Bridge.target.addPoint({ coords = vector3(...), radius = 1.5, options = {...} })
      local id = Bridge.target.addBox({ coords = vector3(...), size = vector3(1.0, 2.0, 2.0), heading = 90.0, options = {...} })
      local id = Bridge.target.addEntity(entity, options)
      local id = Bridge.target.addModel({ 'prop_atm_01', 'prop_atm_02' }, options)
      local id = Bridge.target.addGlobal('player', options)     -- 'player', 'vehicle', 'ped', 'object'

      Bridge.target.remove(id)
      Bridge.target.clear()              everything this resource added
      Bridge.target.disable(true)        no targeting while a menu or a scene has the player

    An option:

      {
          label = 'Open the till',                  what the player reads
          icon = 'fa-cash-register',                a Font Awesome name; ignored by the key prompt
          distance = 2.0,                           how close the player must be
          onSelect = function(entity) end,          entity is nil for a point or a box
          canInteract = function(entity, distance)  optional: return false to hide the option
          groups = 'police',                        optional: a job or gang, a list, or { police = 2 }
      }

    The module remembers what was added. When the target resource restarts, or another one
    takes over, everything is added again without the script noticing. When the script stops,
    everything it added is removed, also on target resources that do not do that themselves.
]]

local h = ...
local Bridge = h.bridge

local KINDS = { player = true, vehicle = true, ped = true, object = true }

local function nothing() end

local none = {
    addSphere = nothing,
    addBox = nothing,
    addEntity = nothing,
    addModel = nothing,
    addGlobal = nothing,
    remove = nothing,
    disable = nothing,
}

--- True when the local character holds one of `groups`: a name, a list of names, or a table
--- of name and lowest grade.
local function inGroups(groups)
    local framework = Bridge.framework
    if type(groups) == 'string' then return framework.hasGroup(groups) end
    for key, value in pairs(groups) do
        if type(key) == 'number' then
            if framework.hasGroup(value) then return true end
        elseif framework.hasGroup(key, value) then
            return true
        end
    end
    return false
end

return {
    adapters = true,
    caps = { 'eye', 'boxes', 'entities', 'models', 'globals' },

    build = function(adapter)
        local a = h.complete(adapter, none)
        local store = h.store
        store.entries = store.entries or {}
        store.count = store.count or 0
        local entries = store.entries
        local settings = h.settings()
        local defaultDistance = tonumber(settings.distance) or 2.0

        --- The options in the one form every adapter is given: a unique name, a select that
        --- takes the entity, and a `can` that already includes the group check.
        local function normalise(id, options, owner, spatial)
            if type(options) ~= 'table' then error('options is a table of options', 3) end
            if options.label then options = { options } end
            local out = {}
            for index, option in ipairs(options) do
                if type(option.label) ~= 'string' then error('every option needs a label', 3) end
                local onSelect, canInteract, groups = option.onSelect, option.canInteract, option.groups
                local can = nil
                if canInteract or groups then
                    can = function(entity, distance)
                        if groups and not inGroups(groups) then return false end
                        if not canInteract then return true end
                        -- A target resource reports whatever the eye rests on, also inside a
                        -- zone. A point or a box has no entity.
                        if spatial or entity == 0 then entity = nil end
                        return canInteract(entity, distance) and true or false
                    end
                end
                out[index] = {
                    name = ('%s:%d:%d'):format(owner, id, index),
                    label = option.label,
                    icon = type(option.icon) == 'string' and option.icon or nil,
                    distance = tonumber(option.distance) or defaultDistance,
                    can = can,
                    select = function(entity)
                        if spatial or entity == 0 then entity = nil end
                        if onSelect then onSelect(entity) end
                    end,
                }
            end
            if #out == 0 then error('give at least one option', 3) end
            return out
        end

        local function apply(entry)
            entry.handle = nil
            local ok, handle = pcall(function()
                if entry.kind == 'sphere' then return a.addSphere(entry) end
                if entry.kind == 'box' then return a.addBox(entry) end
                if entry.kind == 'model' then return a.addModel(entry) end
                if entry.kind == 'global' then return a.addGlobal(entry) end
                if not DoesEntityExist(entry.entity) then return nil end
                -- The id an entity has on the network can change while the handle stays.
                entry.netId = NetworkGetEntityIsNetworked(entry.entity) and NetworkGetNetworkIdFromEntity(entry.entity) or nil
                return a.addEntity(entry)
            end)
            if ok then
                entry.handle = handle or true
            else
                h.once('add', ('the %s adapter did not take a %s: %s'):format(tostring(h.adapter), entry.kind, tostring(handle)))
            end
        end

        local function withdraw(entry)
            if not entry.handle then return end
            local handle = entry.handle
            entry.handle = nil
            pcall(a.remove, entry, handle)
        end

        local function add(entry, options)
            store.count = store.count + 1
            entry.id = store.count
            entry.owner = h.owner()
            entry.name = ('nexus:%s:%d'):format(entry.owner, entry.id)
            entry.options = normalise(entry.id, options, entry.owner, entry.kind == 'sphere' or entry.kind == 'box')
            entries[entry.id] = entry
            apply(entry)
            return entry.id
        end

        local target = {}

        function target.addPoint(def)
            if type(def) ~= 'table' or not def.coords then error('Bridge.target.addPoint({ coords, radius, options })', 2) end
            return add({
                kind = 'sphere',
                coords = vector3(def.coords.x, def.coords.y, def.coords.z),
                radius = tonumber(def.radius) or 1.5,
                debug = def.debug == true,
            }, def.options)
        end

        function target.addBox(def)
            if type(def) ~= 'table' or not def.coords then error('Bridge.target.addBox({ coords, size, heading, options })', 2) end
            local size = def.size or {}
            return add({
                kind = 'box',
                coords = vector3(def.coords.x, def.coords.y, def.coords.z),
                size = vector3(tonumber(size.x) or 1.5, tonumber(size.y) or 1.5, tonumber(size.z) or 2.0),
                heading = (tonumber(def.heading) or 0.0) + 0.0,
                debug = def.debug == true,
            }, def.options)
        end

        function target.addEntity(entity, options)
            if type(entity) ~= 'number' then error('Bridge.target.addEntity(entity, options): entity is an entity handle', 2) end
            return add({ kind = 'entity', entity = entity }, options)
        end

        function target.addModel(models, options)
            if type(models) ~= 'table' then models = { models } end
            if #models == 0 then error('Bridge.target.addModel(models, options): give at least one model', 2) end
            return add({ kind = 'model', models = models }, options)
        end

        function target.addGlobal(kind, options)
            if not KINDS[kind] then error("Bridge.target.addGlobal(kind, options): kind is 'player', 'vehicle', 'ped' or 'object'", 2) end
            return add({ kind = 'global', type = kind }, options)
        end

        function target.remove(id)
            local entry = entries[id]
            if not entry then return false end
            withdraw(entry)
            entries[id] = nil
            return true
        end

        --- Removes everything the calling resource added.
        function target.clear()
            local owner = h.owner()
            for id, entry in pairs(entries) do
                if entry.owner == owner then
                    withdraw(entry)
                    entries[id] = nil
                end
            end
        end

        function target.disable(state)
            pcall(a.disable, state == true)
        end

        --- How many targets are registered, for the doctor.
        function target.count()
            local total = 0
            for _ in pairs(entries) do total = total + 1 end
            return total
        end

        -- A rebuild: put back what was there before the adapter changed or restarted.
        for _, entry in pairs(entries) do apply(entry) end

        h.cleanup(function()
            for _, entry in pairs(entries) do withdraw(entry) end
        end)

        -- Through the bridge's exports every resource shares this state: what one of them added
        -- goes when it stops.
        if h.hub then
            h.on('onClientResourceStop', function(resource)
                for id, entry in pairs(entries) do
                    if entry.owner == resource then
                        withdraw(entry)
                        entries[id] = nil
                    end
                end
            end)
        end

        return target
    end,

    selftest = function(target, t)
        local before = target.count()
        local coords = GetEntityCoords(PlayerPedId())
        local id = target.addPoint({ coords = coords, radius = 1.0, options = { label = 'nexus_bridge self-test', onSelect = function() end } })
        t.check('a point is added', type(id) == 'number' and target.count() == before + 1)
        local box = target.addBox({ coords = coords, size = vector3(1.0, 1.0, 2.0), options = { label = 'nexus_bridge self-test box' } })
        t.check('a box is added', type(box) == 'number')
        local ped = target.addEntity(PlayerPedId(), { label = 'nexus_bridge self-test entity' })
        t.check('an entity is added', type(ped) == 'number')
        t.check('they are removed', target.remove(id) and target.remove(box) and target.remove(ped) and target.count() == before)
    end,
}
