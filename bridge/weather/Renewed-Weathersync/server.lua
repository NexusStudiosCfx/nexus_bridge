--[[
    Renewed-Weathersync adapter (server). Written against Renewed-Weathersync 1.1.8;
    docs/adapters.md lists the lines.

    It keeps everything in global state, and takes changes the same way: its server follows
    what another resource writes there.
      GlobalState.weather        { weather = 'RAIN', time = minutes this weather lasts, ... }
      GlobalState.currentTime    { hour, minute }
    A weather that is set gets a very long time to last, as in the resource's own
    compatibility code, or its schedule would replace it within minutes.
]]

return {
    caps = { read = true, time = true, set = true },

    get = function()
        local now = GlobalState.weather
        return type(now) == 'table' and now.weather or nil
    end,

    time = function()
        local now = GlobalState.currentTime
        if type(now) ~= 'table' then return nil end
        return now.hour, now.minute
    end,

    set = function(kind)
        GlobalState.weather = { weather = kind, time = 9999999999 }
        return true
    end,

    setTime = function(hour, minute)
        GlobalState.currentTime = { hour = hour, minute = minute }
        return true
    end,
}
