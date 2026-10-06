--[[
    Nexus EMS adapter (server), on the exports and events its README documents for other
    resources: IsDown(src), Revive(src), Heal(src, 'full' | 'partial') and the server events
    nexus_ems:playerDown (src, stage) and nexus_ems:playerUp (src).
]]

local h = ...
local ems = exports.nexus_ems

return {
    caps = { heal = true, events = true },

    isDown = function(src)
        return ems:IsDown(src) == true
    end,

    revive = function(src)
        return ems:Revive(src) == true
    end,

    heal = function(src)
        return ems:Heal(src, 'full') == true
    end,

    watch = function(emit)
        h.on('nexus_ems:playerDown', function(src) emit(src, true) end)
        h.on('nexus_ems:playerUp', function(src) emit(src, false) end)
    end,
}
