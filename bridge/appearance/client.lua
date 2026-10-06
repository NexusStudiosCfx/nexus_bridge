--[[
    Bridge.appearance (client): the clothing resource of the server.

      open(options, onDone)    opens its editor for the local player: true when it opened
          options.full         true: face, hair and body as well. Left out: clothes only
          onDone(saved)        called once when the player is done, with whether they kept
                               the change, where the resource tells: supports('result')
      reload()                 puts the look the player saved back on. supports('reload')
      get()                    the look the player has right now, as the clothing resource's
                               own table, or nil. supports('snapshot')
      set(look)                puts a look from get() back on: true when it was handed over

    A look is a different table on every clothing resource. Keep one to put it back (a
    uniform, a disguise, a minigame outfit), and do not read what is in it.

    What the editor saves is the clothing resource's business: where it only hands the
    result back, the adapter saves it the way that resource's own shops do.
]]

local h = ...

return {
    adapters = true,
    caps = { 'result', 'reload', 'snapshot' },

    build = function(adapter)
        local appearance = {}

        if not adapter then
            appearance.open = h.unavailable('open', function() return false end)
            appearance.reload = h.unavailable('reload', function() return false end)
            appearance.get = h.unavailable('get', function() return nil end)
            appearance.set = h.unavailable('set', function() return false end)
            return appearance
        end

        local function guarded(what, fn, ...)
            local ok, result = pcall(fn, ...)
            if ok then return true, result end
            h.once(what, ('the %s adapter could not %s: %s'):format(tostring(h.adapter), what, tostring(result)))
            return false
        end

        function appearance.open(options, onDone)
            if type(options) == 'function' then options, onDone = nil, options end
            if not adapter.open then return false end
            local full = type(options) == 'table' and options.full == true
            local told = false
            local function done(saved)
                if told then return end
                told = true
                if type(onDone) == 'function' then onDone(saved == true) end
            end
            return (guarded('open the editor', adapter.open, full, done))
        end

        function appearance.reload()
            if not adapter.reload then return false end
            return (guarded('reload the look', adapter.reload))
        end

        function appearance.get()
            if not adapter.get then return nil end
            local ok, look = guarded('read the look', adapter.get)
            return ok and type(look) == 'table' and look or nil
        end

        function appearance.set(look)
            if type(look) ~= 'table' or not adapter.set then return false end
            return (guarded('put a look on', adapter.set, look))
        end

        -- What Bridge.appearance.reload on the server arrives as. Only nexus_bridge listens.
        if h.hub then
            h.onNet('nexus_bridge:appearance:reload', function() appearance.reload() end)
        end

        return appearance
    end,
}
