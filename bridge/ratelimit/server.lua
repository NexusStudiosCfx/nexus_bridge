--[[
    Bridge.ratelimit: how often a player may do something, and a lock against doing it twice
    at once. For the events a client can trigger.

      Bridge.ratelimit.check(src, name, limit, window)
          true when the player is within `limit` calls per `window` milliseconds for `name`.
          Defaults: 6 calls per 1000 ms. A token bucket: short bursts pass, a flood does not.

      Bridge.ratelimit.guard(event, handler, limit, window)
          Registers a net event whose handler only runs within the limit. The handler receives
          the player id first, then the event's arguments: handler(src, ...).

      Bridge.ratelimit.lock(id, name)     true when `id` now holds the lock, false when it is taken
      Bridge.ratelimit.unlock(id, name)
      Bridge.ratelimit.locked(id, name)
          For "one purchase at a time per character": take the lock, do the work in pcall,
          release it. A lock taken with a player id is released when that player leaves.

    Everything lives in memory and is dropped when the player is. It limits by server id, which a
    client cannot choose.
]]

local h = ...

return {
    build = function()
        local ratelimit = {}
        local buckets = {}  -- [src] = { [name] = { tokens, at } }
        local locks = {}    -- [id] = { [name] = true }

        function ratelimit.check(src, name, limit, window)
            limit = tonumber(limit) or 6
            window = tonumber(window) or 1000
            name = name or 'default'
            local now = GetGameTimer()

            local mine = buckets[src]
            if not mine then
                mine = {}
                buckets[src] = mine
            end
            local bucket = mine[name]
            if not bucket then
                mine[name] = { tokens = limit - 1, at = now }
                return true
            end

            local tokens = math.min(limit, bucket.tokens + (now - bucket.at) * limit / window)
            bucket.at = now
            if tokens < 1 then
                bucket.tokens = tokens
                return false
            end
            bucket.tokens = tokens - 1
            return true
        end

        function ratelimit.guard(event, handler, limit, window)
            return RegisterNetEvent(event, function(...)
                local src = source
                if not ratelimit.check(src, event, limit, window) then return end
                handler(src, ...)
            end)
        end

        function ratelimit.lock(id, name)
            name = name or 'default'
            local mine = locks[id]
            if not mine then
                mine = {}
                locks[id] = mine
            end
            if mine[name] then return false end
            mine[name] = true
            return true
        end

        function ratelimit.unlock(id, name)
            local mine = locks[id]
            if not mine then return end
            mine[name or 'default'] = nil
            if next(mine) == nil then locks[id] = nil end
        end

        function ratelimit.locked(id, name)
            local mine = locks[id]
            return mine ~= nil and mine[name or 'default'] == true
        end

        --- Forgets what is known about a player. Happens by itself when they leave.
        function ratelimit.reset(src)
            buckets[src] = nil
            locks[src] = nil
        end

        h.on('playerDropped', function()
            ratelimit.reset(source)
        end)

        return ratelimit
    end,

    selftest = function(ratelimit, t)
        local src = -9001
        local passed = 0
        for _ = 1, 10 do
            if ratelimit.check(src, 'selftest', 3, 60000) then passed = passed + 1 end
        end
        t.check('3 of 10 calls pass a limit of 3', passed == 3, passed)
        t.check('a lock is taken once', ratelimit.lock(src, 'selftest') and not ratelimit.lock(src, 'selftest'))
        ratelimit.reset(src)
        t.check('reset frees it', not ratelimit.locked(src, 'selftest'))
    end,
}
