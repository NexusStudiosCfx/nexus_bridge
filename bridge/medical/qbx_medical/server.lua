--[[
    qbx_medical adapter (server). Written against qbx_medical 1.0.0; docs/adapters.md lists
    the lines.

    What to know about qbx_medical:
      - the player state `isDead` is true for dead and for last stand alike, which is what
        the bridge calls down. The server sets it, so it can be trusted here;
      - Revive and Heal only tell that player's client. Heal clears injuries and bleeding;
        it does not refill health.
]]

local h = ...
local medical = exports.qbx_medical

return {
    caps = { heal = true, events = true },

    isDown = function(src)
        return Player(src).state.isDead == true
    end,

    revive = function(src)
        medical:Revive(src)
        return true
    end,

    heal = function(src)
        medical:Heal(src)
        return true
    end,

    watch = function(emit)
        local cookie = AddStateBagChangeHandler('isDead', '', function(bagName, _, value)
            local src = GetPlayerFromStateBagName(bagName)
            if src and src ~= 0 then emit(src, value == true) end
        end)
        h.cleanup(function() RemoveStateBagChangeHandler(cookie) end)
    end,
}
