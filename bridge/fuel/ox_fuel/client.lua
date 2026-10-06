--[[
    ox_fuel adapter (client). ox_fuel has no function for this: the level is the state `fuel`
    on the vehicle, next to the game's own fuel level. Written against ox_fuel 1.5.2
    (CommunityOx) and 1.5.4 (overextended); docs/adapters.md lists the lines.

    What to know about ox_fuel:
      - the state is empty until somebody drove the vehicle. Until then the game's level is
        the answer, as it is for ox_fuel itself;
      - while somebody drives, their client keeps copying the game's level into the state, so
        a new level has to be given to the game as well or it is overwritten within a second;
      - a client may write the state of a vehicle it controls, and on a server with
        sv_stateBagStrictMode not at all. The server's write always works, which is why the
        server half of this adapter does it and this half then only tells the game.
]]

return {
    get = function(vehicle)
        return tonumber(Entity(vehicle).state.fuel) or GetVehicleFuelLevel(vehicle)
    end,

    set = function(vehicle, level)
        SetVehicleFuelLevel(vehicle, level)
        Entity(vehicle).state:set('fuel', level, true)
        return true
    end,

    -- The server wrote the state already.
    apply = function(vehicle, level)
        SetVehicleFuelLevel(vehicle, level)
        return true
    end,
}
