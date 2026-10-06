--[[
    Bridge.weather (server): the weather and the time of day of the weather resource.

      get()                      the weather type in capitals ('CLEAR', 'RAIN', ...), or nil
                                 when the server cannot know it. supports('read')
      isRaining()                true for rain and thunder; false when it is dry or unknown
      getTime()                  hour, minute: two values, or nil. supports('time')
      set(weather)               changes the weather for everybody: true when it was taken.
                                 supports('set')
      setTime(hour, minute)      true when it was taken. supports('set')

    Without a weather resource the game runs its own weather on every client, which a server
    can neither read nor set: nothing is supported then, and the client half still reads
    what the local player sees.
]]

local h = ...

local WET = { RAIN = true, THUNDER = true }

return {
    adapters = true,
    caps = { 'read', 'time', 'set' },

    build = function(adapter)
        local weather = {}

        if not adapter then
            weather.get = h.unavailable('get', function() return nil end)
            weather.getTime = h.unavailable('getTime', function() return nil end)
            weather.set = h.unavailable('set', function() return false end)
            weather.setTime = h.unavailable('setTime', function() return false end)
            weather.isRaining = function() return false end
            return weather
        end

        function weather.get()
            if not adapter.get then return nil end
            local ok, kind = pcall(adapter.get)
            return ok and type(kind) == 'string' and kind ~= '' and kind:upper() or nil
        end

        function weather.isRaining()
            return WET[weather.get() or ''] == true
        end

        function weather.getTime()
            if not adapter.time then return nil end
            local ok, hour, minute = pcall(adapter.time)
            hour, minute = ok and tonumber(hour) or nil, tonumber(minute) or 0
            if not hour then return nil end
            return math.floor(hour) % 24, math.floor(minute) % 60
        end

        function weather.set(kind)
            if type(kind) ~= 'string' or kind == '' or not adapter.set then return false end
            local ok, taken = pcall(adapter.set, kind:upper())
            return ok and taken ~= false
        end

        function weather.setTime(hour, minute)
            hour, minute = tonumber(hour), tonumber(minute == nil and 0 or minute)
            if not hour or not minute or not adapter.setTime then return false end
            if hour < 0 or hour > 23 or minute < 0 or minute > 59 then return false end
            local ok, taken = pcall(adapter.setTime, math.floor(hour), math.floor(minute))
            return ok and taken ~= false
        end

        return weather
    end,

    selftest = function(weather, t)
        if not weather.available then
            t.skip('everything', 'weather is switched off')
            return
        end
        if weather.supports('read') then
            t.check('the weather is known', type(weather.get()) == 'string', weather.get())
        else
            t.note(('%s cannot tell the server what the weather is'):format(tostring(weather.name)))
        end
        t.check('a time that does not exist is refused', weather.setTime(25, 0) == false and weather.set(nil) == false)
    end,
}
