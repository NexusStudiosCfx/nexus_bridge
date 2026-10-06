--[[
    ox_fuel adapter (server): the state `fuel` on the vehicle, written the way ox_fuel's own
    server writes it. The state is empty until somebody drove the vehicle.
]]

return {
    caps = { read = true },

    get = function(vehicle)
        return tonumber(Entity(vehicle).state.fuel)
    end,

    set = function(vehicle, level)
        Entity(vehicle).state:set('fuel', level, true)
        return true
    end,
}
