--[[
    qbx_vehicles adapter: Qbox's own store of owned vehicles. Written against qbx_vehicles
    1.4.2 and run on it on a real server; docs/adapters.md lists every call.

    What to know about qbx_vehicles:
      - everything is keyed by the vehicle's id, not its plate: a plate is looked up first
        (GetVehicleIdByPlate);
      - a vehicle as it answers has no plate of its own. The plate is the one in its stored
        properties, which CreatePlayerVehicle always writes. A row that came from somewhere
        else (a table moved over from QBCore) may not have one there, and then the table's
        own `plate` column is read;
      - GetPlayerVehicles with an empty filter table builds broken SQL, so a filter is
        always given;
      - CreatePlayerVehicle on 1.4.2 does not look whether the plate is taken (the module
        does, before it gets here), and it raises for a character that does not exist;
      - a vehicle is "out" (state 0) unless a garage is named, then it is stored there.
]]

local h = ...
local vehicles = exports.qbx_vehicles

local GARAGED = 1

local function plateOf(row)
    local plate = type(row.props) == 'table' and row.props.plate or nil
    if type(plate) ~= 'string' or plate == '' then
        local db = h.bridge.db
        local ok, stored = pcall(function()
            return db.ready() and db.scalar('SELECT plate FROM player_vehicles WHERE id = ?', { row.id }) or nil
        end)
        plate = ok and stored or nil
    end
    if type(plate) ~= 'string' then return nil end
    plate = plate:match('^%s*(.-)%s*$')
    return plate ~= '' and plate or nil
end

local function shape(row, plate)
    plate = plate or plateOf(row)
    if not plate then return nil end
    return {
        plate = plate,
        owner = row.citizenid,
        model = row.modelName,
        hash = row.modelName and joaat(row.modelName) or nil,
        stored = row.state == GARAGED,
        garage = row.garage,
        props = type(row.props) == 'table' and row.props or {},
    }
end

local function idOf(plate)
    return vehicles:GetVehicleIdByPlate(plate)
end

local adapter = { caps = { give = true, transfer = true, remove = true } }

function adapter.get(plate)
    local id = idOf(plate)
    if not id then return nil end
    local row = vehicles:GetPlayerVehicle(id)
    return type(row) == 'table' and shape(row, plate) or nil
end

function adapter.list(id)
    local out = {}
    for _, row in ipairs(vehicles:GetPlayerVehicles({ citizenid = id }) or {}) do
        out[#out + 1] = shape(row)
    end
    return out
end

function adapter.give(id, vehicle)
    local props = {}
    for key, value in pairs(vehicle.props) do props[key] = value end
    props.plate = vehicle.plate
    local ok, created = pcall(function()
        return vehicles:CreatePlayerVehicle({ model = vehicle.model, citizenid = id, garage = vehicle.garage, props = props })
    end)
    return ok and created ~= nil and idOf(vehicle.plate) ~= nil
end

function adapter.setOwner(plate, id)
    local vehicleId = idOf(plate)
    if not vehicleId then return false end
    local ok, changed = pcall(function() return vehicles:SetPlayerVehicleOwner(vehicleId, id) end)
    if not ok or changed ~= true then return false end
    local row = vehicles:GetPlayerVehicle(vehicleId)
    return type(row) == 'table' and row.citizenid == id
end

function adapter.remove(plate)
    vehicles:DeletePlayerVehicles('plate', plate)
    return idOf(plate) == nil
end

return adapter
