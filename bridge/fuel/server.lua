--[[
    Bridge.fuel (server): how full a vehicle's tank is, from 0 to 100.

      set(vehicle, level)     true when the level was set, or the client that controls the
                              vehicle was asked to set it
      get(vehicle)            the level, or nil when the server cannot know it.
                              supports('read') tells whether it ever can

    `vehicle` is the server's entity. Most fuel resources live on the client, so the server
    hands the level to the client that controls the vehicle, which sets it through the fuel
    resource there. Where the fuel resource has a server side of its own (a state on the
    vehicle), that is written as well, and then the server can read the level too.

    A vehicle no client controls (nobody is near it) cannot be reached on a client: with a
    resource that keeps the level in a state it is set anyway, with the others set answers
    false.
]]

local h = ...

local VEHICLE = 2

local function isVehicle(entity)
    return type(entity) == 'number' and entity ~= 0 and DoesEntityExist(entity) and GetEntityType(entity) == VEHICLE
end

local function within(level)
    level = tonumber(level)
    if not level or level ~= level then return nil end
    return math.max(0.0, math.min(100.0, level + 0.0))
end

return {
    adapters = true,
    caps = { 'read' },

    build = function(adapter)
        local fuel = {}

        if not adapter then
            fuel.get = h.unavailable('get', function() return nil end)
            fuel.set = h.unavailable('set', function() return false end)
            return fuel
        end

        function fuel.get(vehicle)
            if not adapter.get or not isVehicle(vehicle) then return nil end
            return within(adapter.get(vehicle))
        end

        function fuel.set(vehicle, level)
            level = within(level)
            if not level or not isVehicle(vehicle) then return false end

            local written = false
            if adapter.set then written = adapter.set(vehicle, level) ~= false end
            -- An adapter whose server call does everything says so with `complete`.
            if written and adapter.complete then return true end

            local owner = NetworkGetEntityOwner(vehicle)
            if type(owner) == 'number' and owner > 0 then
                TriggerClientEvent('nexus_bridge:fuel:set', owner, NetworkGetNetworkIdFromEntity(vehicle), level)
                return true
            end
            return written
        end

        return fuel
    end,

    selftest = function(fuel, t)
        if not fuel.available then
            t.skip('everything', 'fuel is switched off')
            return
        end
        t.check('something that is not a vehicle is refused', fuel.set(0, 50) == false and fuel.get(0) == nil, fuel.name)
    end,
}
