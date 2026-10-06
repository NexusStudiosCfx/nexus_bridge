--[[
    Renewed-Fuel adapter (client). Written against the vendor's documentation (the resource
    is paid and has no public source); see docs/adapters.md.

    The documentation recommends reading the state `fuel` on the vehicle, or the game's own
    level, over its GetFuel export. SetFuel(vehicle, amount, fuelType) keeps the vehicle's
    fuel type when none is given.
]]

return {
    get = function(vehicle)
        return tonumber(Entity(vehicle).state.fuel) or GetVehicleFuelLevel(vehicle)
    end,

    set = function(vehicle, level)
        exports['Renewed-Fuel']:SetFuel(vehicle, level)
        return true
    end,
}
