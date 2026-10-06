--[[
    MrNewbVehicleKeys adapter. Written against the vendor's documentation (the resource is
    escrowed); see docs/adapters.md.

    Its plain exports go by the vehicle's network id, the ...ByPlate ones by the plate. The
    plate ones are used: they also work for a vehicle that is not spawned. What giving and
    removing answer is not documented, so HasKeysByPlate decides.
]]

local keys = exports.MrNewbVehicleKeys

return {
    caps = { has = true },
    by = 'plate',

    give = function(src, _, plate)
        keys:GiveKeysByPlate(src, plate)
        return keys:HasKeysByPlate(src, plate) == true
    end,

    remove = function(src, _, plate)
        keys:RemoveKeysByPlate(src, plate)
        return keys:HasKeysByPlate(src, plate) ~= true
    end,

    has = function(src, _, plate)
        return keys:HasKeysByPlate(src, plate) == true
    end,
}
