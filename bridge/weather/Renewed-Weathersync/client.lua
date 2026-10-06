--[[
    Renewed-Weathersync (client): the player state `syncWeather` switches the sync for the
    local player. While it is off the resource holds the weather named in the player state
    `playerWeather` and stops the clock.
]]

return {
    caps = { pause = true },

    pause = function(state)
        LocalPlayer.state.syncWeather = not state
    end,
}
