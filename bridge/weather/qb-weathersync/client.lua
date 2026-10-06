--[[
    qb-weathersync (client): two events stop and start the sync for the local player. When
    it stops, the resource sets clear weather and 18:00 once and then leaves the sky alone.
]]

return {
    caps = { pause = true },

    pause = function(state)
        TriggerEvent(state and 'qb-weathersync:client:DisableSync' or 'qb-weathersync:client:EnableSync')
    end,
}
