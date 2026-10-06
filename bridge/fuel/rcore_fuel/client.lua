--[[
    rcore_fuel adapter. Written against the vendor's documentation (the resource is
    escrowed); see docs/adapters.md.

    rcore_fuel counts in litres with a tank size per vehicle. Its documentation names two
    client exports that work in percent, and those are the ones used here:
    GetVehicleFuelPercentage(vehicle) and SetVehicleFuel(vehicle, percentage).
]]

local fuel = exports['rcore_fuel']

return {
    get = function(vehicle)
        return tonumber(fuel:GetVehicleFuelPercentage(vehicle)) or GetVehicleFuelLevel(vehicle)
    end,

    set = function(vehicle, level)
        fuel:SetVehicleFuel(vehicle, level)
        return true
    end,
}
