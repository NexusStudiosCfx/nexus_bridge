--[[
    pma-voice adapter (server). Written against pma-voice 7.0.1; docs/adapters.md lists the
    lines.

    What to know about pma-voice:
      - setPlayerRadio and setPlayerCall take a number and channel 0 means none. They answer
        nothing, and do nothing at all when radios or calls are switched off with the
        convars voice_enableRadios and voice_enableCalls;
      - the channel a player is on is in their player state: radioChannel and callChannel;
      - it has no export to mute somebody for everyone. Its own mute command uses the
        game's MumbleSetPlayerMuted, and so does this file.
]]

local voice = exports['pma-voice']

return {
    caps = { read = true, mute = true },

    setRadio = function(src, channel)
        voice:setPlayerRadio(src, channel)
    end,

    getRadio = function(src)
        return Player(src).state.radioChannel
    end,

    setCall = function(src, channel)
        voice:setPlayerCall(src, channel)
    end,

    getCall = function(src)
        return Player(src).state.callChannel
    end,

    mute = function(src, muted)
        MumbleSetPlayerMuted(src, muted)
    end,
}
