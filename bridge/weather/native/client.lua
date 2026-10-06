--[[
    No weather resource: every client runs the game's own weather. Nothing sets it from
    outside, so there is nothing to hold off and a pause is in effect by itself.
]]

return {
    caps = { pause = true },

    pause = function() end,
}
