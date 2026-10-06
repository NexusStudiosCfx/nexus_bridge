--[[
    esx_ambulancejob adapter (server). Written against esx_ambulancejob 1.0.2 of ESX Legacy
    1.15; docs/adapters.md lists the lines.

    What to know about esx_ambulancejob:
      - the player state `isDead` is set by its server on death and cleared on every revive
        and respawn. It has no last stand;
      - revive and heal are client events the server sends to that player, the way the
        resource's own admin commands do. The server events of the same names are for
        medics next to the patient and are not used here;
      - heal 'big' fills health. The third argument keeps the resource from telling the
        player about it.
]]

local h = ...

return {
    caps = { heal = true, events = true },

    isDown = function(src)
        return Player(src).state.isDead == true
    end,

    revive = function(src)
        TriggerClientEvent('esx_ambulancejob:revive', src)
        return true
    end,

    heal = function(src)
        TriggerClientEvent('esx_ambulancejob:heal', src, 'big', true)
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
