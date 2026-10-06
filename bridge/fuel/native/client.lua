--[[
    No fuel resource: the game's own fuel level. Vehicles do not use any of it by themselves,
    so on such a server this is only ever what a script set it to.
]]

return {
    get = function(vehicle)
        return GetVehicleFuelLevel(vehicle)
    end,

    set = function(vehicle, level)
        SetVehicleFuelLevel(vehicle, level)
        return true
    end,
}
