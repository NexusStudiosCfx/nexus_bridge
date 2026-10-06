--[[
    wasabi_ambulance adapter (server), for the first generation of the resource. Written
    against the vendor's documentation (the resource is escrowed); see docs/adapters.md. The
    second generation is another resource, wasabi_ambulance_v2, with an adapter of its own.

    What to know about wasabi_ambulance:
      - the player state `dead` is the text 'dead' or 'laststand' while the player is down,
        and false or empty otherwise;
      - RevivePlayer(serverId) is the server export. There is no server call that heals
        somebody who is up, so heal is not offered.
]]

local h = ...

local function down(value)
    return value == 'dead' or value == 'laststand'
end

return {
    caps = { heal = false, events = true },

    isDown = function(src)
        return down(Player(src).state.dead)
    end,

    revive = function(src)
        exports.wasabi_ambulance:RevivePlayer(src)
        return true
    end,

    watch = function(emit)
        local cookie = AddStateBagChangeHandler('dead', '', function(bagName, _, value)
            local src = GetPlayerFromStateBagName(bagName)
            if src and src ~= 0 then emit(src, down(value)) end
        end)
        h.cleanup(function() RemoveStateBagChangeHandler(cookie) end)
    end,
}
