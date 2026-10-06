--[[
    BigDaddy-Fuel adapter. Written against the vendor's wiki (the resource is escrowed); see
    docs/adapters.md.

    GetFuel(vehicle) answers 0 to 100 and SetFuel(vehicle, fuelLevel) takes the same, both on
    the client with the vehicle's entity.
]]

local fuel = exports['BigDaddy-Fuel']

return {
    get = function(vehicle)
        return tonumber(fuel:GetFuel(vehicle)) or GetVehicleFuelLevel(vehicle)
    end,

    set = function(vehicle, level)
        fuel:SetFuel(vehicle, level)
        return true
    end,
}
