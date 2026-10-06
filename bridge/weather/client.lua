--[[
    Bridge.weather (client): what the local player sees, and holding the weather resource
    off while a script shows something else.

      get()              the weather type in capitals, read from the game itself
      isRaining()        true while rain falls
      getTime()          hour, minute: two values, the game's clock
      pause(state)       true: the weather resource stops setting weather and time for this
                         player, so an interior or a scene can set its own. false: it takes
                         over again. Answers true when the weather resource was told

    Pauses are counted per resource: while two resources hold the weather off it stays off
    until both have let go, and a resource that stops lets go by stopping.
]]

local h = ...

local TYPES = {
    'CLEAR', 'EXTRASUNNY', 'CLOUDS', 'OVERCAST', 'RAIN', 'CLEARING', 'THUNDER', 'SMOG', 'FOGGY',
    'XMAS', 'SNOW', 'SNOWLIGHT', 'BLIZZARD', 'HALLOWEEN', 'NEUTRAL',
}

local byHash = nil

local function nameOf(hash)
    if not byHash then
        byHash = {}
        for _, name in ipairs(TYPES) do byHash[joaat(name)] = name end
    end
    return byHash[hash] or byHash[hash & 0xFFFFFFFF] or byHash[hash - 0x100000000]
end

return {
    adapters = true,
    caps = { 'pause' },

    build = function(adapter)
        local weather = {}

        if not adapter then
            weather.get = h.unavailable('get', function() return nil end)
            weather.getTime = h.unavailable('getTime', function() return nil end)
            weather.pause = h.unavailable('pause', function() return false end)
            weather.isRaining = function() return false end
            return weather
        end

        function weather.get()
            return nameOf(GetPrevWeatherTypeHashName())
        end

        function weather.isRaining()
            return GetRainLevel() > 0.05
        end

        function weather.getTime()
            return GetClockHours(), GetClockMinutes()
        end

        if not h.hub then
            -- The count is kept in nexus_bridge, which knows who asked.
            function weather.pause(state)
                local ok, done = pcall(function() return exports.nexus_bridge:WeatherPause(state == true) end)
                return ok and done == true
            end
            return weather
        end

        -- Who holds the weather off outlives a change of adapter.
        local holding = h.store.holding or {}
        h.store.holding = holding

        local function apply()
            local held = next(holding) ~= nil
            if adapter.pause then pcall(adapter.pause, held) end
        end

        if next(holding) ~= nil then apply() end

        function weather.pause(state)
            local who = GetInvokingResource() or h.resource
            local was = next(holding) ~= nil
            holding[who] = state == true or nil
            if (next(holding) ~= nil) ~= was then apply() end
            return adapter.pause ~= nil
        end

        h.on('onClientResourceStop', function(resource)
            if not holding[resource] then return end
            holding[resource] = nil
            if next(holding) == nil then apply() end
        end)

        h.cleanup(function()
            if next(holding) ~= nil and adapter.pause then pcall(adapter.pause, false) end
        end)

        return weather
    end,
}
