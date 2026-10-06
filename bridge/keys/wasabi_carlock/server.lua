--[[
    wasabi_carlock adapter. Written against the vendor's documentation (the resource is
    escrowed); see docs/adapters.md.

    GiveKey(serverId, plate) answers the plate, RemoveKey and HasKey true or false.
]]

local keys = exports.wasabi_carlock

return {
    caps = { has = true },
    by = 'plate',

    give = function(src, _, plate)
        keys:GiveKey(src, plate)
        return keys:HasKey(src, plate) == true
    end,

    remove = function(src, _, plate)
        keys:RemoveKey(src, plate)
        return keys:HasKey(src, plate) ~= true
    end,

    has = function(src, _, plate)
        return keys:HasKey(src, plate) == true
    end,
}
