--[[
    Bridge.medical (client)

      isDown()        true while the local player is dead or in last stand

    The two events exist here as well, for the local player:

      Bridge.on('playerDied', function() end)
      Bridge.on('playerRevived', function() end)
]]

local h = ...

return {
    adapters = true,
    caps = {},

    build = function(adapter)
        local medical = {}

        if not adapter then
            medical.isDown = h.unavailable('isDown', function() return false end)
            return medical
        end

        function medical.isDown()
            if not adapter.isDown then return false end
            local ok, down = pcall(adapter.isDown)
            return ok and down == true
        end

        -- The server half noticed the change. Only nexus_bridge listens to it.
        if h.hub then
            h.onNet('nexus_bridge:internal:down', function(down)
                TriggerEvent(down == true and 'nexus_bridge:playerDied' or 'nexus_bridge:playerRevived')
            end)
        end

        return medical
    end,
}
