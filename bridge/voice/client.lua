--[[
    Bridge.voice (client)

      isTalking()        true while the local player's microphone is open.
                         supports('talking') tells whether the voice resource can say

    Channels are set from the server.
]]

local h = ...

return {
    adapters = true,
    caps = { 'talking' },

    build = function(adapter)
        local voice = {}

        if not adapter then
            voice.isTalking = h.unavailable('isTalking', function() return false end)
            return voice
        end

        function voice.isTalking()
            if not adapter.isTalking then return false end
            local ok, talking = pcall(adapter.isTalking)
            return ok and talking == true
        end

        return voice
    end,
}
