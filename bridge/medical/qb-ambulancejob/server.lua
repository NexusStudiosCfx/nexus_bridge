--[[
    qb-ambulancejob adapter (server). Written against qb-ambulancejob 1.2.4;
    docs/adapters.md lists the lines.

    What to know about qb-ambulancejob:
      - it keeps death in the character's metadata: `isdead` and `inlaststand`. Both mean
        down here;
      - a dying client tells the server with hospital:server:SetDeathStatus (true, and false
        on a revive) and hospital:server:SetLaststandStatus. Listening to the same two
        events is how the bridge notices;
      - a player who dies out of last stand is, for a moment between two events, neither:
        last stand ends first and death is reported right after. "Up again" is therefore
        only believed when it still holds half a second later;
      - revive and heal are client events the server sends to that player, as the
        resource's own admin commands do. hospital:server:RevivePlayer is for medics and
        bans a caller without the job, so it is never used;
      - HealInjuries 'full' clears wounds and bleeding. It does not refill health.
]]

local h = ...

return {
    caps = { heal = true, events = true },

    isDown = function(src)
        local framework = h.bridge.framework
        return framework.getMetadata(src, 'isdead') == true or framework.getMetadata(src, 'inlaststand') == true
    end,

    revive = function(src)
        TriggerClientEvent('hospital:client:Revive', src)
        return true
    end,

    heal = function(src)
        TriggerClientEvent('hospital:client:HealInjuries', src, 'full')
        return true
    end,

    watch = function(emit)
        local dead, lastStand = {}, {}

        local function changed(src)
            if dead[src] or lastStand[src] then
                emit(src, true)
                return
            end
            SetTimeout(500, function()
                if not dead[src] and not lastStand[src] then emit(src, false) end
            end)
        end

        h.onNet('hospital:server:SetDeathStatus', function(isDead)
            local src = source
            dead[src] = isDead == true or nil
            changed(src)
        end)
        h.onNet('hospital:server:SetLaststandStatus', function(inLastStand)
            local src = source
            lastStand[src] = inLastStand == true or nil
            changed(src)
        end)
        h.on('playerDropped', function()
            dead[source], lastStand[source] = nil, nil
        end)
    end,
}
