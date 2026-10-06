--[[
    wasabi_ambulance_v2 adapter (server). Written against the vendor's documentation (the
    resource is escrowed); see docs/adapters.md.

    What to know about wasabi_ambulance_v2:
      - the player state `wasabi:deathState` is 1 in last stand and 2 when dead, and the
        state `isDead` is its plain flag for dead. A server owner can rename the first in
        the resource's config, so both are read and either one means down;
      - RevivePlayer(serverId) clears death, injuries and restores health;
      - ApplyHeal(serverId, options) answers true, or false and why. The options here are
        the full heal of the vendor's example without the part that refills hunger and
        thirst, which a heal through the bridge has no business changing.
]]

local h = ...
local ambulance = exports['wasabi_ambulance_v2']

local function isDown(src)
    local state = Player(src).state
    return (tonumber(state['wasabi:deathState']) or 0) > 0 or state.isDead == true
end

return {
    caps = { heal = true, events = true },

    isDown = isDown,

    revive = function(src)
        ambulance:RevivePlayer(src)
        return true
    end,

    heal = function(src)
        local done = ambulance:ApplyHeal(src, {
            health = 200,
            injuries = { { type = 'all', limb = 'all' } },
            limbHealth = 100,
        })
        return done == true
    end,

    watch = function(emit)
        -- A handler runs before the state holds the new value, so the key that changed is
        -- taken from the handler and only the other one is read.
        local function listen(key)
            return AddStateBagChangeHandler(key, '', function(bagName, _, value)
                local src = GetPlayerFromStateBagName(bagName)
                if not src or src == 0 then return end
                local state = Player(src).state
                local stage, flag = state['wasabi:deathState'], state.isDead
                if key == 'isDead' then flag = value else stage = value end
                emit(src, (tonumber(stage) or 0) > 0 or flag == true)
            end)
        end
        local first, second = listen('wasabi:deathState'), listen('isDead')
        h.cleanup(function()
            RemoveStateBagChangeHandler(first)
            RemoveStateBagChangeHandler(second)
        end)
    end,
}
