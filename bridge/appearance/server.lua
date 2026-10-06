--[[
    Bridge.appearance (server)

      reload(src)        puts the look the player saved back on: true when their client was
                         asked. For the end of a sentence, a shift, a scene.

    Everything else about clothes happens on the client.
]]

local h = ...

return {
    adapters = true,
    caps = {},

    build = function(adapter)
        if not adapter then
            return { reload = h.unavailable('reload', function() return false end) }
        end
        return {
            reload = function(src)
                if math.type(src) ~= 'integer' or src <= 0 or not DoesPlayerExist(tostring(src)) then return false end
                TriggerClientEvent('nexus_bridge:appearance:reload', src)
                return true
            end,
        }
    end,
}
