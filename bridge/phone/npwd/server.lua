--[[
    NPWD adapter (server). Written against npwd 3.16.0; docs/adapters.md lists the lines.

    What to know about NPWD:
      - getPlayerData finds a player by one of source, identifier or phone number, and only
        somebody NPWD has loaded, which means online. It answers through a promise, so the
        call waits;
      - there is no mail app, and notifications exist on the client only: the client half of
        this adapter shows them.
]]

return {
    caps = { mail = false, offline = false },

    number = function(who)
        if not who.src then return nil end
        local data = exports.npwd:getPlayerData({ source = who.src })
        return type(data) == 'table' and data.phoneNumber or nil
    end,
}
