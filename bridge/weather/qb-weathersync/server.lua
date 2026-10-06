--[[
    qb-weathersync adapter (server). Written against qb-weathersync 2.3.0; docs/adapters.md
    lists the lines.

    getWeatherState answers the type in capitals, getTime two values (hour, minute), and
    setWeather and setTime true or false. setWeather only takes the types the server owner
    left in the resource's own list.
]]

local weather = exports['qb-weathersync']

return {
    caps = { read = true, time = true, set = true },

    get = function() return weather:getWeatherState() end,
    time = function() return weather:getTime() end,
    set = function(kind) return weather:setWeather(kind) == true end,
    setTime = function(hour, minute) return weather:setTime(hour, minute) == true end,
}
