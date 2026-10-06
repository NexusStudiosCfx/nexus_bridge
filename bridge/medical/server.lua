--[[
    Bridge.medical (server): whether a player is down, and getting them up again, with
    whatever ambulance resource the server runs.

      isDown(src)        true while the player is dead or in last stand: on the ground and
                         unable to do anything. False for somebody who is not there
      revive(src)        brings the player back on their feet: true when the medical resource
                         was asked
      heal(src)          a full heal for somebody who is up: true when it was asked.
                         supports('heal') tells whether the resource has one

    The bridge raises two events, the same on every medical resource:

      Bridge.on('playerDied', function(src) end)       the player went down
      Bridge.on('playerRevived', function(src) end)    and is up again

    "Died" is the moment a player goes down, which for most resources is the last stand:
    that is when a robbery stops, a carried item drops, a minigame ends. A resource that
    needs the difference between last stand and death asks the medical resource itself.

    With no medical resource running the module is not available: nobody is down as far as
    the bridge knows, and nothing is revived.
]]

local h = ...

local function player(src)
    return math.type(src) == 'integer' and src > 0 and DoesPlayerExist(tostring(src))
end

--- Runs in nexus_bridge only: turns what the medical resource announces into the two
--- events, once per change.
local function listen(adapter)
    local down = {}

    local function emit(src, isDown)
        src = tonumber(src)
        if not src or src <= 0 then return end
        isDown = isDown == true
        if (down[src] == true) == isDown then return end
        down[src] = isDown or nil
        TriggerEvent(isDown and 'nexus_bridge:playerDied' or 'nexus_bridge:playerRevived', src)
        TriggerClientEvent('nexus_bridge:internal:down', src, isDown)
    end

    -- Somebody who was down when the bridge (re)started is known as down, without an event.
    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)
        local ok, isDown = pcall(adapter.isDown, src)
        if ok and isDown == true then down[src] = true end
    end

    adapter.watch(emit)
    h.on('playerDropped', function()
        down[source] = nil
    end)
end

return {
    adapters = true,
    caps = { 'heal', 'events' },

    build = function(adapter)
        local medical = {}

        if not adapter then
            medical.isDown = h.unavailable('isDown', function() return false end)
            medical.revive = h.unavailable('revive', function() return false end)
            medical.heal = h.unavailable('heal', function() return false end)
            return medical
        end

        local function guarded(what, fn, ...)
            local ok, result = pcall(fn, ...)
            if ok then return result end
            h.once(what, ('the %s adapter could not %s: %s'):format(tostring(h.adapter), what, tostring(result)))
            return nil
        end

        function medical.isDown(src)
            if not player(src) or not adapter.isDown then return false end
            return guarded('tell whether a player is down', adapter.isDown, src) == true
        end

        function medical.revive(src)
            if not player(src) or not adapter.revive then return false end
            return guarded('revive a player', adapter.revive, src) ~= false
        end

        function medical.heal(src)
            if not player(src) or not adapter.heal then return false end
            return guarded('heal a player', adapter.heal, src) ~= false
        end

        if h.hub and adapter.watch and adapter.isDown then listen(adapter) end

        return medical
    end,

    selftest = function(medical, t)
        if not medical.available then
            t.skip('everything', 'no medical resource is running')
            return
        end
        t.check('nobody is not down, and is not revived', medical.isDown(0) == false and medical.revive(0) == false and medical.heal(65000) == false, medical.name)
    end,
}
