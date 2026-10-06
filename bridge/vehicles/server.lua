--[[
    Bridge.vehicles (server): which character owns which vehicle.

      get(plate)                the stored vehicle, or nil:
                                { plate, owner, model, hash, stored, garage, props }
      owner(plate)              the character id of its owner, or nil when nobody owns that plate
      isOwned(plate)            true when the plate belongs to a stored vehicle
      owns(id, plate)           true when that character owns it
      list(id)                  every vehicle of a character
      give(id, vehicle)         adds a vehicle to a character: { model = 'sultan', plate, props, garage }.
                                Answers the plate it got, or false. A plate that is taken is refused
      setOwner(plate, id)       hands a vehicle to another character: true when it changed hands
      remove(plate)             deletes the stored vehicle. supports('remove')
      plate()                   a plate nobody owns yet

    `model` is the model's name where the framework stores one (ESX stores only the hash),
    `hash` always a number, `stored` true while the vehicle is in a garage and `garage` that
    garage's name where the framework keeps one. `props` is the framework's own table of
    vehicle properties, handed through untouched.

    A vehicle given with a garage is stored there; one given without is "out", for the
    resource that spawns it straight away.

    Everything here reads or writes the database, so it belongs in a thread or an event handler.
]]

local h = ...

local function none() return nil end
local function no() return false end
local function empty() return {} end

local fallbacks = { get = none, list = empty, give = no, setOwner = no, remove = no }

--- A plate without the blanks around it, or nil. Blanks inside a plate are part of it.
local function trimmed(plate)
    if type(plate) ~= 'string' then return nil end
    plate = plate:match('^%s*(.-)%s*$')
    return plate ~= '' and plate or nil
end

local LETTERS = 'ABCDEFGHJKLMNPQRSTUVWXYZ0123456789'

return {
    adapters = true,
    caps = { 'give', 'transfer', 'remove' },

    build = function(adapter)
        local a = h.complete(adapter, fallbacks)
        local vehicles = {}

        function vehicles.get(plate)
            plate = trimmed(plate)
            if not plate then return nil end
            return a.get(plate)
        end

        function vehicles.owner(plate)
            local vehicle = vehicles.get(plate)
            return vehicle and vehicle.owner or nil
        end

        function vehicles.isOwned(plate)
            return vehicles.get(plate) ~= nil
        end

        function vehicles.owns(id, plate)
            return type(id) == 'string' and vehicles.owner(plate) == id
        end

        function vehicles.list(id)
            if type(id) ~= 'string' or id == '' then return {} end
            return a.list(id) or {}
        end

        --- Eight characters, none of them easy to mistake for another, that no stored
        --- vehicle carries.
        function vehicles.plate()
            for _ = 1, 25 do
                local out = {}
                for index = 1, 8 do
                    local pick = math.random(#LETTERS)
                    out[index] = LETTERS:sub(pick, pick)
                end
                local plate = table.concat(out)
                if not vehicles.isOwned(plate) then return plate end
            end
            return nil
        end

        function vehicles.give(id, vehicle)
            if type(id) ~= 'string' or id == '' or type(vehicle) ~= 'table' then return false end
            if type(vehicle.model) ~= 'string' or vehicle.model == '' then return false end
            -- A plate that was asked for and makes no sense is not quietly replaced by another.
            local plate
            if vehicle.plate ~= nil then plate = trimmed(vehicle.plate) else plate = vehicles.plate() end
            if not plate or vehicles.isOwned(plate) then return false end
            local props = type(vehicle.props) == 'table' and vehicle.props or {}
            local done = a.give(id, {
                model = vehicle.model,
                plate = plate,
                props = props,
                garage = type(vehicle.garage) == 'string' and vehicle.garage or nil,
            })
            return done == true and plate or false
        end

        function vehicles.setOwner(plate, id)
            plate = trimmed(plate)
            if not plate or type(id) ~= 'string' or id == '' then return false end
            if not a.get(plate) then return false end
            return a.setOwner(plate, id) == true
        end

        function vehicles.remove(plate)
            plate = trimmed(plate)
            if not plate or not a.get(plate) then return false end
            return a.remove(plate) == true
        end

        return vehicles
    end,

    selftest = function(vehicles, t)
        if not vehicles.available then
            t.skip('everything', 'no framework with stored vehicles is running')
            return
        end
        t.check('a plate nobody owns has no owner', vehicles.owner('NXB0NONE') == nil and vehicles.isOwned('NXB0NONE') == false)
        t.check('a character nobody is owns nothing', #vehicles.list('nexus_bridge_nobody') == 0)
        t.check('a free plate can be made', type(vehicles.plate()) == 'string', vehicles.plate())
        t.check('a vehicle without a model is refused', vehicles.give('nexus_bridge_nobody', { plate = 'NXB0NONE' }) == false)
    end,
}
