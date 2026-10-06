--[[
    Bridge.ped (client): a ped that stands somewhere and can be talked to. It exists only
    while the player is near, so a hundred of them across the map cost nothing.

      local id = Bridge.ped.add({
          model = 'a_m_m_business_01',
          coords = vector4(25.7, -1347.3, 28.5, 270.0),     the last number is the heading
          distance = 50.0,                   how near the player has to be for it to exist
          scenario = 'WORLD_HUMAN_CLIPBOARD',               what it does while standing there
          options = { { label = 'Open the shop', icon = 'fa-solid fa-store', onSelect = function(ped) end } },
          onSpawn = function(ped) end,       for clothes, a prop in its hand
      })
      Bridge.ped.remove(id)
      Bridge.ped.entity(id)                  the ped while it exists, or nil

    The ped is local to this client, cannot be hurt or pushed and does not react to what
    happens around it. `options` are target options (Bridge.target), put on the ped each time
    it appears. `coords.z` is where its feet are.
]]

local h = ...

return {
    build = function()
        local api = {}
        local Bridge = h.bridge
        local store = h.store
        store.peds = store.peds or {}
        local peds = store.peds

        local function despawn(entry)
            if entry.target then
                Bridge.target.remove(entry.target)
                entry.target = nil
            end
            if entry.entity then
                if DoesEntityExist(entry.entity) then DeleteEntity(entry.entity) end
                entry.entity = nil
            end
        end

        local function spawn(entry)
            if entry.entity or entry.loading then return end
            local model = entry.hash
            if not IsModelInCdimage(model) then
                h.once('model:' .. tostring(entry.model), ('%s asked for a ped with the model "%s", which the game does not have'):format(h.resource, tostring(entry.model)))
                return
            end
            entry.loading = true
            RequestModel(model)
            local deadline = GetGameTimer() + 10000
            while not HasModelLoaded(model) and GetGameTimer() < deadline do Wait(50) end
            entry.loading = false
            -- The player may have left, or the ped may have been removed, while the model loaded.
            if not HasModelLoaded(model) or not entry.wanted or not peds[entry.id] then return end

            local at = entry.coords
            local ped = CreatePed(4, model, at.x, at.y, at.z, entry.heading, false, false)
            SetModelAsNoLongerNeeded(model)
            if not ped or ped == 0 then return end
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            FreezeEntityPosition(ped, true)
            SetPedCanRagdoll(ped, false)
            if entry.scenario then TaskStartScenarioInPlace(ped, entry.scenario, 0, true) end
            entry.entity = ped

            if entry.options then entry.target = Bridge.target.addEntity(ped, entry.options) end
            if entry.onSpawn then
                local ok, problem = pcall(entry.onSpawn, ped)
                if not ok then h.once('spawn', ('a ped of %s raised in onSpawn: %s'):format(h.resource, tostring(problem))) end
            end
        end

        function api.add(def)
            if type(def) ~= 'table' or type(def.coords) == 'nil' then return nil end
            local coords = def.coords
            local x, y, z = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z)
            if not x or not y or not z or (type(def.model) ~= 'string' and type(def.model) ~= 'number') then return nil end

            local entry = {
                model = def.model,
                hash = type(def.model) == 'string' and joaat(def.model) or def.model,
                coords = vector3(x + 0.0, y + 0.0, z + 0.0),
                heading = (tonumber(coords.w) or tonumber(def.heading) or 0.0) + 0.0,
                scenario = type(def.scenario) == 'string' and def.scenario or nil,
                options = type(def.options) == 'table' and def.options or nil,
                onSpawn = type(def.onSpawn) == 'function' and def.onSpawn or nil,
                wanted = false,
            }
            entry.point = Bridge.point.add({
                coords = entry.coords,
                distance = tonumber(def.distance) or 50.0,
                onEnter = function()
                    entry.wanted = true
                    -- Loading a model waits, and the loop that watches the points must not.
                    CreateThread(function() spawn(entry) end)
                end,
                onExit = function()
                    entry.wanted = false
                    despawn(entry)
                end,
            })
            if not entry.point then return nil end
            entry.id = entry.point
            peds[entry.id] = entry
            return entry.id
        end

        function api.remove(id)
            local entry = peds[id]
            if not entry then return false end
            peds[id] = nil
            entry.wanted = false
            Bridge.point.remove(entry.point)
            despawn(entry)
            return true
        end

        function api.entity(id)
            local entry = peds[id]
            return entry and entry.entity or nil
        end

        h.cleanup(function()
            if not h.stopping then return end
            for id in pairs(peds) do api.remove(id) end
        end)

        return api
    end,
}
