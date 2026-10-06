--[[
    Renewed-Vehiclekeys adapter. Written against the vendor's documentation (the resource has
    no public source); see docs/adapters.md.

    addKey(source, plate), removeKey(source, plate), hasKey(source, plate). The documentation
    does not say what the first two answer, so hasKey decides.
]]

local keys = exports['Renewed-Vehiclekeys']

return {
    caps = { has = true },
    by = 'plate',

    give = function(src, _, plate)
        keys:addKey(src, plate)
        return keys:hasKey(src, plate) == true
    end,

    remove = function(src, _, plate)
        keys:removeKey(src, plate)
        return keys:hasKey(src, plate) ~= true
    end,

    has = function(src, _, plate)
        return keys:hasKey(src, plate) == true
    end,
}
