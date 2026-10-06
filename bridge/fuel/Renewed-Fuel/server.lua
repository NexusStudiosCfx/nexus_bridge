--[[
    Renewed-Fuel adapter (server), from the vendor's documentation: the level is read from
    the state `fuel` on the vehicle and set with the server's SetFuel(vehicle, amount,
    fuelType), which keeps the fuel type when none is given.
]]

return {
    caps = { read = true },
    -- Its own server export does the whole job: no client has to be asked.
    complete = true,

    get = function(vehicle)
        return tonumber(Entity(vehicle).state.fuel)
    end,

    set = function(vehicle, level)
        exports['Renewed-Fuel']:SetFuel(vehicle, level)
        return true
    end,
}
