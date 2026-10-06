--[[
    qbx_weathersync adapter (server). Written against qbx_weathersync 2.0.0, the Qbox fork of
    qb-weathersync that was archived in 2023; docs/adapters.md lists the lines.

    It has the exports of qb-weathersync under its own name, without getTime: the server
    cannot read the clock here.
]]

local weather = exports.qbx_weathersync

return {
    caps = { read = true, time = false, set = true },

    get = function() return weather:getWeatherState() end,

    set = function(kind)
        weather:setWeather(kind)
        return true
    end,

    setTime = function(hour, minute)
        weather:setTime(hour, minute)
        return true
    end,
}
