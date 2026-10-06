--[[
    ESX adapter for owned vehicles. ESX has no function that answers who owns a plate: its
    garage and vehicle shop read and write the table `owned_vehicles`, and so does this file,
    with the statements those resources use (ESX Legacy 1.15.2 and its addons).
    docs/adapters.md lists where each one comes from.

    What to know about the table:
      - `plate` is the primary key and `owner` the character's identifier;
      - `vehicle` is the vehicle's properties as JSON. It holds the model as a hash, so there
        is no model name to give back;
      - `stored` is 1 while the vehicle is in a garage. The column `parking` (which garage)
        exists on a database made from the ESX recipe and not on one made from the vehicle
        shop's own SQL, so it is only written where it exists;
      - nothing stops a row for a character that does not exist, so `users` is asked first;
      - a vehicle that the core spawned and tracks (ESX 1.15) remembers its owner. Changing
        the owner goes through that object when there is one, or the core would lose track.
]]

local h = ...
local db = h.bridge.db

local ESX = exports['es_extended']:getSharedObject()

local TABLE = 'owned_vehicles'
local columns, asked = nil, nil

--- The table's columns once it has been seen. While it is missing the catalogue is asked
--- again at most twice a minute, so that a table added on a running server is found.
local function present()
    if columns then return columns end
    if not db.ready() then return nil end
    local now = GetGameTimer()
    if asked and now - asked < 30000 then return nil end
    asked = now
    columns = db.columns(TABLE)
    if not columns then
        h.once('table', 'ESX keeps owned vehicles in the table `owned_vehicles`, and this database has none. Bridge.vehicles answers "not owned" until it exists.')
    end
    return columns
end

local function shape(row)
    local decoded = type(row.vehicle) == 'string' and row.vehicle ~= '' and json.decode(row.vehicle) or nil
    local props = type(decoded) == 'table' and decoded or {}
    local model = props.model
    return {
        plate = row.plate,
        owner = row.owner,
        model = type(model) == 'string' and model or nil,
        hash = type(model) == 'string' and joaat(model) or tonumber(model),
        stored = row.stored == true or tonumber(row.stored) == 1,
        garage = row.parking,
        props = props,
    }
end

local function character(id)
    return db.scalar('SELECT identifier FROM users WHERE identifier = ? LIMIT 1', { id }) ~= nil
end

--- The core's object for a vehicle it spawned itself, or nil.
local function tracked(plate)
    local found = nil
    pcall(function()
        found = ESX.GetExtendedVehicleFromPlate and ESX.GetExtendedVehicleFromPlate(plate) or nil
    end)
    return type(found) == 'table' and found or nil
end

local adapter = { caps = { give = true, transfer = true, remove = true } }

function adapter.get(plate)
    if not present() then return nil end
    local row = db.single('SELECT * FROM owned_vehicles WHERE plate = ? LIMIT 1', { plate })
    return type(row) == 'table' and shape(row) or nil
end

function adapter.list(id)
    if not present() then return {} end
    local out = {}
    for _, row in ipairs(db.query('SELECT * FROM owned_vehicles WHERE owner = ?', { id }) or {}) do
        out[#out + 1] = shape(row)
    end
    return out
end

function adapter.give(id, vehicle)
    local has = present()
    if not has or not character(id) then return false end
    local props = {}
    for key, value in pairs(vehicle.props) do props[key] = value end
    props.model, props.plate = joaat(vehicle.model), vehicle.plate

    local ok
    if vehicle.garage and has.parking then
        ok = pcall(db.insert, 'INSERT INTO owned_vehicles (owner, plate, vehicle, stored, parking) VALUES (?, ?, ?, ?, ?)',
            { id, vehicle.plate, json.encode(props), 1, vehicle.garage })
    else
        ok = pcall(db.insert, 'INSERT INTO owned_vehicles (owner, plate, vehicle, stored) VALUES (?, ?, ?, ?)',
            { id, vehicle.plate, json.encode(props), vehicle.garage and 1 or 0 })
    end
    return ok and adapter.get(vehicle.plate) ~= nil
end

function adapter.setOwner(plate, id)
    if not present() or not character(id) then return false end
    local current = adapter.get(plate)
    if not current then return false end
    if current.owner == id then return true end

    local out = tracked(plate)
    if out then
        local ok, changed = pcall(function() return out:setOwner(id) end)
        if not ok or changed ~= true then return false end
    else
        db.update('UPDATE owned_vehicles SET owner = ? WHERE plate = ?', { id, plate })
    end
    local now = adapter.get(plate)
    return now ~= nil and now.owner == id
end

function adapter.remove(plate)
    if not present() then return false end
    db.update('DELETE FROM owned_vehicles WHERE plate = ?', { plate })
    return adapter.get(plate) == nil
end

return adapter
