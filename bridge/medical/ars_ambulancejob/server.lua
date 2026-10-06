--[[
    ars_ambulancejob adapter (server). Written against ars_ambulancejob 1.0.4;
    docs/adapters.md lists the lines.

    What to know about ars_ambulancejob:
      - the player state `dead` is true while the player is down. The dying client sets it;
      - revive and heal are one client event, ars_ambulancejob:healPlayer, with a table that
        says which: { revive = true } or { heal = true }. That is what the resource's own
        admin commands send. The server events of similar names are for medics next to the
        patient;
      - its heal fills health, hunger and thirst.
]]

local h = ...

return {
    caps = { heal = true, events = true },

    isDown = function(src)
        return Player(src).state.dead == true
    end,

    revive = function(src)
        TriggerClientEvent('ars_ambulancejob:healPlayer', src, { revive = true })
        return true
    end,

    heal = function(src)
        TriggerClientEvent('ars_ambulancejob:healPlayer', src, { heal = true })
        return true
    end,

    watch = function(emit)
        local cookie = AddStateBagChangeHandler('dead', '', function(bagName, _, value)
            local src = GetPlayerFromStateBagName(bagName)
            if src and src ~= 0 then emit(src, value == true) end
        end)
        h.cleanup(function() RemoveStateBagChangeHandler(cookie) end)
    end,
}
