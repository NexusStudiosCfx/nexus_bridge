--[[
    qs-fuelstations (Quasar) adapter. Written against the vendor's documentation (the
    resource is escrowed); see docs/adapters.md.

    GetFuel(vehicle) answers the level as a percentage and SetFuel(vehicle, fuelLevel) takes
    one, both on the client with the vehicle's entity. The vendor's example allows for
    GetFuel answering nothing, and then the game's own level is used.
]]

local fuel = exports['qs-fuelstations']

return {
    get = function(vehicle)
        return tonumber(fuel:GetFuel(vehicle)) or GetVehicleFuelLevel(vehicle)
    end,

    set = function(vehicle, level)
        fuel:SetFuel(vehicle, level)
        return true
    end,
}
