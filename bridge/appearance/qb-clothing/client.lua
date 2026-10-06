--[[
    qb-clothing adapter. Written against qb-clothing 1.2.0; docs/adapters.md lists the lines.

    What to know about qb-clothing:
      - its menu is opened with an event and tells nobody when the player is done. It always
        shows every tab, and saves by itself;
      - reloadSkin(health) puts the saved skin back and sets the health it is given, because
        changing the model resets it;
      - nothing hands out the look the player has right now, so there is no snapshot.
]]

return {
    caps = { result = false, reload = true, snapshot = false },

    open = function()
        TriggerEvent('qb-clothing:client:openMenu')
    end,

    reload = function()
        exports['qb-clothing']:reloadSkin(GetEntityHealth(PlayerPedId()))
    end,
}
