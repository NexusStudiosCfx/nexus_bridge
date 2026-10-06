--[[
    qbx_vehiclekeys adapter. Written against qbx_vehiclekeys 1.0.3; see docs/adapters.md.

    It goes by the vehicle's entity. GiveKeys answers true when the keys are new and nothing
    when the player already had them, which is success just the same: HasKeys decides.
    Its exports under the name qb-vehiclekeys go by plate, and in the 1.0.3 release that
    comparison matches every vehicle, so they are not used.
]]

local keys = exports.qbx_vehiclekeys

return {
    caps = { has = true },
    by = 'entity',

    give = function(src, vehicle)
        keys:GiveKeys(src, vehicle, true)
        return keys:HasKeys(src, vehicle) == true
    end,

    remove = function(src, vehicle)
        keys:RemoveKeys(src, vehicle, true)
        return keys:HasKeys(src, vehicle) ~= true
    end,

    has = function(src, vehicle)
        return keys:HasKeys(src, vehicle) == true
    end,
}
