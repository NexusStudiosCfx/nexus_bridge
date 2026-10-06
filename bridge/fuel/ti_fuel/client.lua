--[[
    ti_fuel (Tebit) adapter. Written against the vendor's documentation (the resource is
    escrowed); see docs/adapters.md.

    The exports start with a small letter. getFuel(vehicle) answers two values, the level and
    the fuel type; setFuel(vehicle, level, type) takes the type as well, so the one the
    vehicle has is handed back and a refuel through the bridge never changes what is in the
    tank.
]]

local fuel = exports['ti_fuel']

return {
    get = function(vehicle)
        local level = fuel:getFuel(vehicle)
        return tonumber(level) or GetVehicleFuelLevel(vehicle)
    end,

    set = function(vehicle, level)
        local _, kind = fuel:getFuel(vehicle)
        fuel:setFuel(vehicle, level, kind)
        return true
    end,
}
