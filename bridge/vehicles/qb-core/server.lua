--[[
    QBCore adapter for owned vehicles. QBCore has no function for this: its own garages and
    vehicle shop read and write the table `player_vehicles`, and so does this file, with the
    statements those two resources use (qb-garages 2.0.0, qb-vehicleshop 2.1.0).
    docs/adapters.md lists where each one comes from.

    What to know about the table:
      - it belongs to qb-garages or qb-vehicleshop, so a server without both has no such
        table. Then nothing is owned and nothing can be given, and the console says so once;
      - `vehicle` is the model's name, `mods` the vehicle's properties as JSON, `state` 0 for
        out and 1 for in a garage;
      - `license` sits next to `citizenid` and has to follow it when the owner changes;
      - a server that ran the vehicle shop's SQL refuses a row for a character that does not
        exist (a foreign key), which the database reports by raising.
]]

local h = ...
local db = h.bridge.db

local TABLE = 'player_vehicles'
local known, asked = false, nil

--- True once the table has been seen. While it is missing the catalogue is asked again at
--- most twice a minute, so that a table added on a running server is found.
local function present()
    if known then return true end
    if not db.ready() then return false end
    local now = GetGameTimer()
    if asked and now - asked < 30000 then return false end
    asked = now
    known = db.columns(TABLE) ~= nil
    if not known then
        h.once('table', 'QBCore keeps owned vehicles in the table `player_vehicles`, and this database has none (it comes with qb-garages or qb-vehicleshop). Bridge.vehicles answers "not owned" until it exists.')
    end
    return known
end

local function shape(row)
    local decoded = type(row.mods) == 'string' and row.mods ~= '' and json.decode(row.mods) or nil
    return {
        plate = row.plate,
        owner = row.citizenid,
        model = row.vehicle,
        hash = tonumber(row.hash) or (row.vehicle and joaat(row.vehicle)) or nil,
        stored = tonumber(row.state) == 1,
        garage = row.garage,
        props = type(decoded) == 'table' and decoded or {},
    }
end

local adapter = { caps = { give = true, transfer = true, remove = true } }

function adapter.get(plate)
    if not present() then return nil end
    local row = db.single('SELECT * FROM player_vehicles WHERE plate = ? LIMIT 1', { plate })
    return type(row) == 'table' and shape(row) or nil
end

function adapter.list(id)
    if not present() then return {} end
    local out = {}
    for _, row in ipairs(db.query('SELECT * FROM player_vehicles WHERE citizenid = ?', { id }) or {}) do
        out[#out + 1] = shape(row)
    end
    return out
end

function adapter.give(id, vehicle)
    if not present() then return false end
    local license = db.scalar('SELECT license FROM players WHERE citizenid = ? LIMIT 1', { id })
    if not license then return false end
    local props = {}
    for key, value in pairs(vehicle.props) do props[key] = value end
    props.plate = vehicle.plate
    local ok = pcall(db.insert, 'INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        license, id, vehicle.model, joaat(vehicle.model), json.encode(props), vehicle.plate,
        vehicle.garage or 'pillboxgarage', vehicle.garage and 1 or 0,
    })
    return ok and adapter.get(vehicle.plate) ~= nil
end

function adapter.setOwner(plate, id)
    if not present() then return false end
    local license = db.scalar('SELECT license FROM players WHERE citizenid = ? LIMIT 1', { id })
    if not license then return false end
    local ok = pcall(db.update, 'UPDATE player_vehicles SET citizenid = ?, license = ? WHERE plate = ?', { id, license, plate })
    if not ok then return false end
    local now = adapter.get(plate)
    return now ~= nil and now.owner == id
end

function adapter.remove(plate)
    if not present() then return false end
    db.update('DELETE FROM player_vehicles WHERE plate = ?', { plate })
    return adapter.get(plate) == nil
end

return adapter
