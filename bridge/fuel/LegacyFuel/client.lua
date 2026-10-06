--[[
    Adapter for LegacyFuel and the fuel resources that kept its two client exports:
    cdn-fuel, ps-fuel, qb-fuel and lc_fuel. All five were read in source; docs/adapters.md
    lists the versions and lines.

        exports[resource]:GetFuel(vehicle)
        exports[resource]:SetFuel(vehicle, level)

    What to know about them:
      - LegacyFuel, cdn-fuel and ps-fuel ignore a level outside 0 to 100 instead of bringing
        it inside. The module does that before it gets here;
      - all but qb-fuel read the level from a decorator that a vehicle only gets once
        somebody drove it. Until then GetFuel answers 0 while the tank is not empty, and the
        game's own level is the truth;
      - qb-fuel and lc_fuel also answer under the name LegacyFuel, so they are asked for
        first: the doctor then names the resource that really runs.
]]

local h = ...
local resource = h.adapterResource or 'LegacyFuel'

return {
    get = function(vehicle)
        local level = tonumber(exports[resource]:GetFuel(vehicle))
        if not level or level <= 0 then return GetVehicleFuelLevel(vehicle) end
        return level
    end,

    set = function(vehicle, level)
        exports[resource]:SetFuel(vehicle, level)
        return true
    end,
}
