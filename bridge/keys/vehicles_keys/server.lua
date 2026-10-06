--[[
    vehicles_keys (jaksam) adapter. Written against the vendor's documentation (the resource
    is escrowed); see docs/adapters.md.

    giveVehicleKeysToPlayerId(playerId, plate, type) hands out a key of the type 'temporary'
    unless told otherwise, which is the right one for a key a script hands out: it does not
    make the player the owner. isPlayerOwnerOfVehiclePlate(playerId, plate, false) also counts
    such keys.
]]

local keys = exports['vehicles_keys']

local function has(src, plate)
    return keys:isPlayerOwnerOfVehiclePlate(src, plate, false) == true
end

return {
    caps = { has = true },
    by = 'plate',

    give = function(src, _, plate)
        keys:giveVehicleKeysToPlayerId(src, plate, 'temporary')
        return has(src, plate)
    end,

    remove = function(src, _, plate)
        keys:removeKeysFromPlayerId(src, plate)
        return not has(src, plate)
    end,

    has = function(src, _, plate)
        return has(src, plate)
    end,
}
