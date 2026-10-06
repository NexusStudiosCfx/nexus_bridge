--[[
    Bridge.fuel (client): how full a vehicle's tank is, from 0 to 100.

      get(vehicle)            the level, or nil for something that is not a vehicle
      set(vehicle, level)     true when the fuel resource was told. A level outside 0 to 100
                              is brought inside

    `vehicle` is the entity. Without a fuel resource the game's own fuel level is used, so
    the module always works unless it is switched off.

    Set the fuel of a vehicle from the server when there is a choice: Bridge.fuel.set there
    reaches the fuel resource on its own side and the client that drives the vehicle. From a
    client it works for a vehicle this client controls.
]]

local h = ...

local VEHICLE = 2

local function isVehicle(entity)
    return type(entity) == 'number' and entity ~= 0 and DoesEntityExist(entity) and GetEntityType(entity) == VEHICLE
end

--- A level within 0 and 100, or nil. Several fuel resources ignore a value outside it.
local function within(level)
    level = tonumber(level)
    if not level or level ~= level then return nil end
    return math.max(0.0, math.min(100.0, level + 0.0))
end

return {
    adapters = true,
    caps = {},

    build = function(adapter)
        -- Switched off in the config: nothing is read or set, and the first call says so.
        if not adapter then
            return {
                get = h.unavailable('get', function() return nil end),
                set = h.unavailable('set', function() return false end),
            }
        end
        local a = h.complete(adapter, {
            get = function() return nil end,
            set = function() return false end,
        })
        local fuel = {}

        function fuel.get(vehicle)
            if not isVehicle(vehicle) then return nil end
            return within(a.get(vehicle))
        end

        function fuel.set(vehicle, level)
            level = within(level)
            if not level or not isVehicle(vehicle) then return false end
            return a.set(vehicle, level) ~= false
        end

        -- What Bridge.fuel.set on the server arrives as, on the client that controls the
        -- vehicle. Only nexus_bridge listens to it.
        if h.hub then
            h.onNet('nexus_bridge:fuel:set', function(netId, level)
                if type(netId) ~= 'number' or not NetworkDoesNetworkIdExist(netId) then return end
                local vehicle = NetworkGetEntityFromNetworkId(netId)
                level = within(level)
                if not level or not isVehicle(vehicle) then return end
                -- An adapter whose server half did part of the job has less left to do here.
                if adapter.apply then adapter.apply(vehicle, level) else a.set(vehicle, level) end
            end)
        end

        return fuel
    end,

    selftest = function(fuel, t)
        if not fuel.available then
            t.skip('everything', 'fuel is switched off')
            return
        end
        t.check('something that is not a vehicle has no fuel level', fuel.get(0) == nil and fuel.set(0, 50) == false, fuel.name)
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle == 0 then
            t.skip('reading and setting a level', 'the player is not in a vehicle')
            return
        end
        local before = fuel.get(vehicle)
        t.check('the vehicle has a level', type(before) == 'number', before)
        t.check('a level is set', fuel.set(vehicle, 55) == true)
        Wait(500)
        local now = fuel.get(vehicle)
        t.check('and read back', now ~= nil and math.abs(now - 55) < 2, now)
        fuel.set(vehicle, before or 55)
    end,
}
