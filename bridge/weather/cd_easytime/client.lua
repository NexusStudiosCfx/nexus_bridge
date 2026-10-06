--[[
    cd_easytime (client): one event pauses and resumes the sync for the local player. While
    paused the resource holds the clock at 20:00 and leaves the weather to whoever paused it.
]]

return {
    caps = { pause = true },

    pause = function(state)
        TriggerEvent('cd_easytime:PauseSync', state == true)
    end,
}
