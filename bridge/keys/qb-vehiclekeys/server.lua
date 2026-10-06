--[[
    qb-vehiclekeys adapter. Written against qb-vehiclekeys 1.6.0; see docs/adapters.md.

    It goes by the plate. GiveKeys and RemoveKeys answer nothing, so HasKeys decides. The
    exports are used and not the event qb-vehiclekeys:server:AcquireVehicleKeys, which since
    late 2026 wants a network id and refuses a plate.
]]

local keys = exports['qb-vehiclekeys']

return {
    caps = { has = true },
    by = 'plate',

    give = function(src, _, plate)
        keys:GiveKeys(src, plate)
        return keys:HasKeys(src, plate) == true
    end,

    remove = function(src, _, plate)
        keys:RemoveKeys(src, plate)
        return keys:HasKeys(src, plate) ~= true
    end,

    has = function(src, _, plate)
        return keys:HasKeys(src, plate) == true
    end,
}
