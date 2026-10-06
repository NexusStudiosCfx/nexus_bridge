--[[
    saltychat adapter (server). Written against saltychat-fivem 1.2.4; docs/adapters.md
    lists the lines.

    What to know about saltychat:
      - channels have names, not numbers: the bridge's channel number is used as the name;
      - leaving needs the name of the channel that is left, for radio and for calls alike,
        so this file remembers where it put each player. A channel somebody joined through
        saltychat itself is not known here, which is why the channels cannot be read;
      - a player has a primary and a secondary radio. The bridge uses the primary one;
      - voice runs through TeamSpeak, so the game cannot mute a player.
]]

local h = ...
local voice = exports['saltychat']

-- Where each player was put has to be remembered in one place, and every resource has a
-- memory of its own: all of them ask nexus_bridge, which is the one that talks to saltychat.
if not h.hub then
    return {
        caps = { read = false, mute = false },
        setRadio = function(src, channel) exports.nexus_bridge:VoiceSetRadio(src, channel) end,
        setCall = function(src, channel) exports.nexus_bridge:VoiceSetCall(src, channel) end,
    }
end

local radios, calls = {}, {}

h.on('playerDropped', function()
    radios[source], calls[source] = nil, nil
end)

return {
    caps = { read = false, mute = false },

    setRadio = function(src, channel)
        if radios[src] then
            voice:RemovePlayerRadioChannel(src, radios[src])
            radios[src] = nil
        end
        if channel > 0 then
            radios[src] = tostring(channel)
            voice:SetPlayerRadioChannel(src, radios[src], true)
        end
    end,

    setCall = function(src, channel)
        if calls[src] then
            voice:RemovePlayerFromCall(calls[src], src)
            calls[src] = nil
        end
        if channel > 0 then
            calls[src] = tostring(channel)
            voice:AddPlayerToCall(calls[src], src)
        end
    end,
}
