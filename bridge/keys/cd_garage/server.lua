--[[
    cd_garage adapter (it has keys built in). Written against the vendor's documentation (the
    resource is escrowed); see docs/adapters.md.

    The server hands a key over by sending the player's client an event:
    cd_garage:AddKeys (plate) and cd_garage:RemoveKeys (plate). Whether a player has a key can
    only be asked on that player's client, so the server cannot say: no `has` here, and
    give and remove answer true for "asked".
]]

return {
    caps = {},
    by = 'plate',

    give = function(src, _, plate)
        TriggerClientEvent('cd_garage:AddKeys', src, plate)
        return true
    end,

    remove = function(src, _, plate)
        TriggerClientEvent('cd_garage:RemoveKeys', src, plate)
        return true
    end,
}
