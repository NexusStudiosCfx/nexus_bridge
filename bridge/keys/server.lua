--[[
    Bridge.keys (server): the keys of a vehicle, for a player.

      give(src, vehicle, plate)      true when the keys were handed over
      remove(src, vehicle, plate)    true when they were taken away
      has(src, vehicle, plate)       true when the player has them. supports('has')

    `vehicle` is the entity of the vehicle on the server, `plate` its plate. One of the two is
    enough: some key resources go by the entity and some by the plate, and the module finds
    the one from the other. A plate is given without the spaces around it.

    On a server without a key resource `give` answers false and the vehicle is simply not
    locked for anybody: Bridge.keys.available tells.
]]

local h = ...

local function no() return false end

--- A plate without the blanks the game pads it with, or nil.
local function trimmed(plate)
    if type(plate) ~= 'string' then return nil end
    plate = plate:match('^%s*(.-)%s*$')
    return plate ~= '' and plate or nil
end

local function exists(vehicle)
    return type(vehicle) == 'number' and vehicle ~= 0 and DoesEntityExist(vehicle)
end

--- The vehicle that carries a plate, or nil. Looks at every vehicle of the server, which is
--- fine for something that happens when a player is handed a car.
local function byPlate(plate)
    for _, vehicle in ipairs(GetAllVehicles()) do
        if trimmed(GetVehicleNumberPlateText(vehicle)) == plate then return vehicle end
    end
    return nil
end

return {
    adapters = true,
    caps = { 'has' },

    build = function(adapter)
        local a = h.complete(adapter, { give = no, remove = no, has = no })
        local needsEntity = adapter ~= nil and adapter.by == 'entity'

        --- What the adapter needs to know the vehicle by, or nil when it cannot be told.
        local function identify(vehicle, plate)
            plate = trimmed(plate)
            if not exists(vehicle) then vehicle = nil end
            if needsEntity then
                vehicle = vehicle or (plate and byPlate(plate))
                if not vehicle then return nil end
                return vehicle, plate or trimmed(GetVehicleNumberPlateText(vehicle))
            end
            plate = plate or (vehicle and trimmed(GetVehicleNumberPlateText(vehicle)))
            if not plate then return nil end
            return vehicle, plate
        end

        local function call(fn)
            return function(src, vehicle, plate)
                src = tonumber(src)
                if not src then return false end
                local entity, text = identify(vehicle, plate)
                if not entity and not text then return false end
                return fn(src, entity, text) == true
            end
        end

        return { give = call(a.give), remove = call(a.remove), has = call(a.has) }
    end,

    selftest = function(keys, t)
        if not keys.available then
            t.skip('everything', 'no key resource is running')
            return
        end
        t.check('a vehicle that cannot be told is refused', keys.give(65534, nil, nil) == false and keys.give(65534, nil, '   ') == false)
        t.check('so is a call without a player', keys.give(nil, nil, 'NXBRIDGE') == false)
        t.skip('giving and taking keys', 'it needs a connected player and a vehicle')
    end,
}
