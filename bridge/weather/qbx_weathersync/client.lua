--[[
    qbx_weathersync (client): it kept the event names of qb-weathersync. While the sync is
    stopped this fork keeps setting clear weather and 18:00 every few seconds, so a script
    that wants another sky has to keep setting its own as well.
]]

return {
    caps = { pause = true },

    pause = function(state)
        TriggerEvent(state and 'qb-weathersync:client:DisableSync' or 'qb-weathersync:client:EnableSync')
    end,
}
