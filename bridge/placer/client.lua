--[[
    Bridge.placer (client): the player sets an object down where they look.

      Bridge.placer.start({
          model = 'prop_table_03',
          reach = 6.0,                    how far from the player it may stand
          flatness = 0.85,                how level the surface has to be (1 is perfectly flat)
          canPlace = function(coords, heading) return true end,    your own rules, each frame
      }, function(result) end)
          result is { coords = vector3, heading = number }, or nil when the player cancelled.
          start answers false when a placement is already going on or the model cannot load.

      Bridge.placer.active()              true while the player is placing something
      Bridge.placer.cancel()

      Bridge.placer.settle(entity, function(ok) end)
          For an object a script has just created: it is put on the ground under it and made
          solid, once the ground is there. Until then it is not solid, so nobody stands on
          a prop that then drops, or gets pushed away by one that appears inside them.
          `ok` is false when no ground turned up within ten seconds: the object is then made
          solid where it is.

    A see-through copy follows the middle of the screen, green where it may stand and red
    where it may not. Mouse wheel or the arrow keys turn it, E or Enter sets it down,
    Backspace or the right mouse button cancels. The four words of the button bar are shown
    in the bridge's language (Config.settings.locale) where this file has them, in English
    otherwise.

    The result is what the player chose, nothing more: the server has to check it again
    (distance, zone, limits) before it creates anything.
]]

local h = ...

local KEY = { place = 38, enter = 191, cancel = 177, aim = 25, wheelUp = 241, wheelDown = 242, left = 174, right = 175, fast = 21 }
-- Attacks, aiming, the weapon wheel and the cover key would get in the way of the mouse.
local BLOCKED = { 24, 25, 37, 44, 45, 47, 58, 140, 141, 142, 143, 257, 263, 264, 14, 15, 16, 17, 81, 82, 99, 100 }

local TEXT = {
    en = { place = 'Set down', cancel = 'Cancel', rotate = 'Turn', fast = 'Turn faster' },
    de = { place = 'Abstellen', cancel = 'Abbrechen', rotate = 'Drehen', fast = 'Schneller drehen' },
    fr = { place = 'Poser', cancel = 'Annuler', rotate = 'Tourner', fast = 'Tourner plus vite' },
    es = { place = 'Colocar', cancel = 'Cancelar', rotate = 'Girar', fast = 'Girar deprisa' },
    nl = { place = 'Neerzetten', cancel = 'Annuleren', rotate = 'Draaien', fast = 'Sneller draaien' },
}

--- Where the middle of the screen points: whether something was hit, where, and how the
--- surface there is tilted.
local function aim(reach)
    local from = GetGameplayCamCoord()
    local rotation = GetGameplayCamRot(2)
    local pitch, yaw = math.rad(rotation.x), math.rad(rotation.z)
    local flat = math.abs(math.cos(pitch))
    local direction = vector3(-math.sin(yaw) * flat, math.cos(yaw) * flat, math.sin(pitch))
    local to = from + direction * (reach + 8.0)
    -- 17: the map and objects, so that something can stand on a table.
    local test = StartExpensiveSynchronousShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, 17, PlayerPedId(), 4)
    local _, hit, coords, normal = GetShapeTestResult(test)
    return hit == 1 or hit == true, coords, normal
end

local function loadModel(hash)
    if not IsModelInCdimage(hash) then return false end
    RequestModel(hash)
    local deadline = GetGameTimer() + 10000
    while not HasModelLoaded(hash) and GetGameTimer() < deadline do Wait(25) end
    return HasModelLoaded(hash)
end

return {
    build = function()
        local placer = {}
        local store = h.store
        local words = TEXT[h.language()] or TEXT.en

        local function buttons()
            local movie = RequestScaleformMovie('instructional_buttons')
            local deadline = GetGameTimer() + 2000
            while not HasScaleformMovieLoaded(movie) and GetGameTimer() < deadline do Wait(0) end
            if not HasScaleformMovieLoaded(movie) then return nil end
            BeginScaleformMovieMethod(movie, 'CLEAR_ALL')
            EndScaleformMovieMethod()
            local rows = { { KEY.place, words.place }, { KEY.cancel, words.cancel }, { KEY.right, words.rotate }, { KEY.fast, words.fast } }
            for index, row in ipairs(rows) do
                BeginScaleformMovieMethod(movie, 'SET_DATA_SLOT')
                ScaleformMovieMethodAddParamInt(index - 1)
                ScaleformMovieMethodAddParamPlayerNameString(GetControlInstructionalButton(2, row[1], true))
                BeginTextCommandScaleformString('STRING')
                AddTextComponentSubstringKeyboardDisplay(row[2])
                EndTextCommandScaleformString()
                EndScaleformMovieMethod()
            end
            BeginScaleformMovieMethod(movie, 'DRAW_INSTRUCTIONAL_BUTTONS')
            EndScaleformMovieMethod()
            return movie
        end

        function placer.active()
            return store.placing == true
        end

        function placer.cancel()
            if not store.placing then return false end
            store.cancelled = true
            return true
        end

        local function run(hash, options, onDone)
            local ped = PlayerPedId()
            local start = GetEntityCoords(ped)
            local ghost = CreateObjectNoOffset(hash, start.x, start.y, start.z - 5.0, false, false, false)
            SetModelAsNoLongerNeeded(hash)
            SetEntityAlpha(ghost, 170, false)
            SetEntityCollision(ghost, false, false)
            FreezeEntityPosition(ghost, true)
            SetEntityDrawOutline(ghost, true)
            store.ghost = ghost

            local reach = tonumber(options.reach) or 6.0
            local flatness = tonumber(options.flatness) or 0.85
            local heading = (GetEntityHeading(ped) + 180.0) % 360.0
            local movie = buttons()
            local result, shown = nil, nil

            while store.placing and not store.cancelled do
                Wait(0)
                for _, control in ipairs(BLOCKED) do DisableControlAction(0, control, true) end
                if movie then DrawScaleformMovieFullscreen(movie, 255, 255, 255, 255, 0) end

                local step = IsDisabledControlPressed(0, KEY.fast) and 6.0 or 2.0
                if IsDisabledControlPressed(0, KEY.left) then heading = heading + step end
                if IsDisabledControlPressed(0, KEY.right) then heading = heading - step end
                if IsDisabledControlJustPressed(0, KEY.wheelUp) then heading = heading + step * 4 end
                if IsDisabledControlJustPressed(0, KEY.wheelDown) then heading = heading - step * 4 end
                heading = heading % 360.0

                local hit, coords, normal = aim(reach)
                if hit then SetEntityCoordsNoOffset(ghost, coords.x, coords.y, coords.z, false, false, false) end
                SetEntityHeading(ghost, heading)

                local ok = hit and #(GetEntityCoords(PlayerPedId()) - coords) <= reach and (not normal or normal.z >= flatness)
                if ok and options.canPlace then
                    local fine, allowed = pcall(options.canPlace, coords, heading)
                    ok = fine and allowed ~= false
                end
                if ok ~= shown then
                    shown = ok
                    -- Green where it may stand, red where it may not.
                    SetEntityDrawOutlineColor(ok and 80 or 230, ok and 220 or 60, ok and 100 or 60, 255)
                end

                if IsDisabledControlJustPressed(0, KEY.cancel) or IsDisabledControlJustPressed(0, KEY.aim) then
                    break
                end
                if ok and (IsDisabledControlJustPressed(0, KEY.place) or IsDisabledControlJustPressed(0, KEY.enter)) then
                    result = { coords = vector3(coords.x, coords.y, coords.z), heading = heading }
                    break
                end
            end

            if DoesEntityExist(ghost) then DeleteEntity(ghost) end
            if movie then SetScaleformMovieAsNoLongerNeeded(movie) end
            store.ghost, store.placing, store.cancelled = nil, false, false
            if type(onDone) == 'function' then onDone(result) end
        end

        function placer.start(options, onDone)
            if store.placing or type(options) ~= 'table' then return false end
            local model = options.model
            local hash = type(model) == 'string' and joaat(model) or model
            if type(hash) ~= 'number' then return false end
            store.placing, store.cancelled = true, false
            CreateThread(function()
                if not loadModel(hash) then
                    store.placing = false
                    h.once('model:' .. tostring(model), ('%s asked to place the model "%s", which the game cannot load'):format(h.resource, tostring(model)))
                    if type(onDone) == 'function' then onDone(nil) end
                    return
                end
                run(hash, options, onDone)
            end)
            return true
        end

        function placer.settle(entity, onDone)
            if type(entity) ~= 'number' or not DoesEntityExist(entity) then
                if type(onDone) == 'function' then onDone(false) end
                return false
            end
            SetEntityCollision(entity, false, false)
            FreezeEntityPosition(entity, true)
            CreateThread(function()
                local settled = false
                -- The ground under a place the player just arrived at takes a moment to exist.
                for _ = 1, 40 do
                    if not DoesEntityExist(entity) then break end
                    local at = GetEntityCoords(entity)
                    local found = GetGroundZFor_3dCoord(at.x, at.y, at.z + 1.0, false)
                    if found then
                        PlaceObjectOnGroundProperly(entity)
                        settled = true
                        break
                    end
                    Wait(250)
                end
                if DoesEntityExist(entity) then
                    FreezeEntityPosition(entity, true)
                    SetEntityCollision(entity, true, true)
                end
                if type(onDone) == 'function' then onDone(settled) end
            end)
            return true
        end

        h.cleanup(function()
            if not h.stopping then return end
            if store.ghost and DoesEntityExist(store.ghost) then DeleteEntity(store.ghost) end
            store.ghost, store.placing = nil, false
        end)

        return placer
    end,
}
