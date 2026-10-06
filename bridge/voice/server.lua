--[[
    Bridge.voice (server): radio and call channels of the voice resource.

      setRadio(src, channel)     puts the player on a radio channel; 0 or nothing takes them
                                 off. True when the voice resource was asked
      getRadio(src)              the channel, or 0. supports('read')
      setCall(src, channel)      the same for a call channel (a phone call, an intercom)
      getCall(src)               supports('read')
      mute(src, muted)           nobody hears the player, or everybody again. supports('mute')

    A channel is a whole number above zero. A resource that needs a channel nobody else is
    on picks a high one of its own.

    With no voice resource running the module is not available and nothing is set.
]]

local h = ...

local function player(src)
    return math.type(src) == 'integer' and src > 0 and DoesPlayerExist(tostring(src))
end

--- A channel as a whole number: 0 for "none", nil for what is no channel at all.
local function channelOf(channel)
    if channel == nil or channel == false then return 0 end
    channel = tonumber(channel)
    if not channel or channel ~= channel or channel < 0 or channel > 2147483647 then return nil end
    return math.floor(channel)
end

return {
    adapters = true,
    caps = { 'read', 'mute' },

    build = function(adapter)
        local voice = {}

        if not adapter then
            for _, name in ipairs({ 'setRadio', 'setCall', 'mute' }) do
                voice[name] = h.unavailable(name, function() return false end)
            end
            voice.getRadio = h.unavailable('getRadio', function() return 0 end)
            voice.getCall = h.unavailable('getCall', function() return 0 end)
            return voice
        end

        local function set(what, fn, src, channel)
            channel = channelOf(channel)
            if not channel or not fn or not player(src) then return false end
            local ok, problem = pcall(fn, src, channel)
            if not ok then h.once(what, ('the %s adapter could not set a %s channel: %s'):format(tostring(h.adapter), what, tostring(problem))) end
            return ok
        end

        local function get(fn, src)
            if not fn or not player(src) then return 0 end
            local ok, channel = pcall(fn, src)
            return ok and math.floor(tonumber(channel) or 0) or 0
        end

        function voice.setRadio(src, channel) return set('radio', adapter.setRadio, src, channel) end
        function voice.setCall(src, channel) return set('call', adapter.setCall, src, channel) end
        function voice.getRadio(src) return get(adapter.getRadio, src) end
        function voice.getCall(src) return get(adapter.getCall, src) end

        function voice.mute(src, muted)
            if not adapter.mute or not player(src) then return false end
            return pcall(adapter.mute, src, muted == true)
        end

        return voice
    end,

    selftest = function(voice, t)
        if not voice.available then
            t.skip('everything', 'no voice resource is running')
            return
        end
        t.check('nobody is put on a channel', voice.setRadio(0, 5) == false and voice.getRadio(65000) == 0 and voice.setCall(nil, 5) == false, voice.name)
    end,
}
