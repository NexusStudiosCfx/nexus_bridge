--[[
    The key prompt of Bridge.target, for servers without a target resource.

    A point or a box shows its option as a help text while the player stands in it; the key
    (E by default) uses it, and with several options the second key steps through them.
    Options on entities, models and "every vehicle" have no place to stand in, so they hang on
    a key binding of their own (G by default, changeable in the game's settings): pressed next
    to such a thing, it shows that thing's options the same way for a few seconds.

    One slow loop looks for the nearest point. It runs only while points exist, wakes once a
    second when nothing is close, and draws only while the player is inside one.

    exports.nexus_bridge:PromptAdd(target)      -> handle
    exports.nexus_bridge:PromptRemove(handle)
    exports.nexus_bridge:PromptDisable(state)
]]

local internal = Bridge.internal

local points = {}    -- handle -> a sphere or a box
local reaches = {}   -- handle -> an entity, a model list or a kind of entity
local handles = 0
local started = GetGameTimer()
local disabledBy = {}
local looping, attending, bound = false, false, false

local NEXT_OPTION = 47  -- INPUT_DETONATE, G by default

local function settings()
    local target = internal.state.s.target
    return type(target) == 'table' and target or {}
end

local function disabled()
    return next(disabledBy) ~= nil
end

local function help(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, false, -1)
end

local function contains(point, pos)
    local offset = pos - point.coords
    if point.kind == 'sphere' then return #offset <= point.radius end
    -- A box: the offset turned into the box's own axes.
    local angle = math.rad(-point.heading)
    local x = offset.x * math.cos(angle) - offset.y * math.sin(angle)
    local y = offset.x * math.sin(angle) + offset.y * math.cos(angle)
    return math.abs(x) <= point.size.x / 2 and math.abs(y) <= point.size.y / 2 and math.abs(offset.z) <= point.size.z / 2
end

--- The options of a target the player may use right now. `can` belongs to another resource:
--- a call that raises there hides the option.
local function usable(options, entity, distance)
    local out = {}
    for _, option in ipairs(options) do
        local allowed = true
        if option.can then
            local ok, answer = pcall(option.can, entity or 0, distance)
            allowed = ok and answer == true
        end
        if allowed and (not entity or distance <= option.distance) then out[#out + 1] = option end
    end
    return out
end

local function line(option, index, total)
    local label = tostring(option.label):sub(1, 80)
    if total > 1 then return ('~INPUT_CONTEXT~ %s~n~~INPUT_DETONATE~ %d / %d'):format(label, index, total) end
    return ('~INPUT_CONTEXT~ %s'):format(label)
end

local function choose(option, entity)
    -- In a thread of its own: what the script does on select may wait, and the prompt must not.
    CreateThread(function() option.select(entity or 0) end)
end

--- Shows the options of one target until one is used, `stillThere` says no, or time runs out.
local function attend(options, entity, stillThere, timeout, slack)
    if attending then return end
    attending = true
    local key = tonumber(settings().promptKey) or 38
    local index, list, checked = 1, {}, -1000
    local deadline = timeout and (GetGameTimer() + timeout) or nil

    while not disabled() and stillThere() and (not deadline or GetGameTimer() < deadline) do
        local now = GetGameTimer()
        if now - checked > 300 then
            local distance = 0.0
            if entity then
                distance = math.max(0.0, #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(entity)) - (slack or 0.0))
            end
            list, checked = usable(options, entity, distance), now
            if index > #list then index = 1 end
        end
        local option = list[index]
        if option then
            help(line(option, index, #list))
            if IsControlJustReleased(0, key) then
                choose(option, entity)
                break
            end
            if #list > 1 and IsControlJustReleased(0, NEXT_OPTION) then
                index = index % #list + 1
                if deadline then deadline = GetGameTimer() + timeout end
            end
        end
        Wait(0)
    end
    attending = false
end

local function loop()
    if looping then return end
    looping = true
    CreateThread(function()
        while next(points) do
            local wait = 1000
            if not disabled() and not attending then
                local pos = GetEntityCoords(PlayerPedId())
                for handle, point in pairs(points) do
                    local distance = #(pos - point.coords)
                    if contains(point, pos) then
                        attend(point.options, nil, function()
                            return points[handle] ~= nil and contains(point, GetEntityCoords(PlayerPedId()))
                        end)
                        -- After a select the player is usually in a menu: do not prompt again at once.
                        wait = 500
                        break
                    elseif distance < 15.0 then
                        wait = 250
                    end
                end
            end
            Wait(wait)
        end
        looping = false
    end)
end

local POOLS = { 'CPed', 'CVehicle', 'CObject' }

local function matches(reach, entity, pool)
    if reach.kind == 'entity' then return reach.entity == entity end
    if reach.kind == 'model' then return reach.hashes[GetEntityModel(entity)] == true end
    if reach.type == 'vehicle' then return pool == 'CVehicle' end
    if reach.type == 'object' then return pool == 'CObject' end
    if pool ~= 'CPed' then return false end
    local player = IsPedAPlayer(entity)
    return (player == true or player == 1) == (reach.type == 'player')
end

--- The nearest entity that has an option the player may use, and those options.
local function nearest()
    local me = PlayerPedId()
    local pos = GetEntityCoords(me)
    local best, bestReach, bestRaw, bestOptions, bestSlack = nil, nil, nil, nil, 0.0
    for _, pool in ipairs(POOLS) do
        -- A vehicle is measured from its middle, which can be metres from its door.
        local slack = pool == 'CVehicle' and 2.5 or 0.0
        for _, entity in ipairs(GetGamePool(pool)) do
            if entity ~= me then
                local raw = #(pos - GetEntityCoords(entity))
                local reach = math.max(0.0, raw - slack)
                -- Among things equally in reach, the one the player stands closest to wins.
                local closer = not best or reach < bestReach or (reach == bestReach and raw < bestRaw)
                if reach <= 4.0 and closer then
                    local options = {}
                    for _, target in pairs(reaches) do
                        if matches(target, entity, pool) then
                            for _, option in ipairs(usable(target.options, entity, reach)) do
                                options[#options + 1] = option
                            end
                        end
                    end
                    if #options > 0 then
                        best, bestReach, bestRaw, bestOptions, bestSlack = entity, reach, raw, options, slack
                    end
                end
            end
        end
    end
    return best, bestOptions, bestSlack
end

local function bind()
    if bound then return end
    bound = true
    RegisterCommand('nexus_bridge_interact', function()
        if attending or disabled() or not next(reaches) then return end
        local entity, options, slack = nearest()
        if not entity then return end
        attend(options, entity, function() return DoesEntityExist(entity) end, 6000, slack)
    end, false)
    local key = settings().entityKey
    RegisterKeyMapping('nexus_bridge_interact', 'Interact with what is next to you', 'keyboard', type(key) == 'string' and key or 'G')
end

exports('PromptAdd', function(target)
    if type(target) ~= 'table' or type(target.options) ~= 'table' then return nil end
    handles = handles + 1
    -- Not a bare number: a handle from before a restart of the bridge must never match a
    -- target that somebody else has added since.
    local handle = ('%d:%d'):format(started, handles)
    target.owner = GetInvokingResource() or Bridge.name

    if target.kind == 'sphere' or target.kind == 'box' then
        if target.kind == 'sphere' then
            -- A little more than asked for: the player's position is their middle, not their feet.
            target.radius = (tonumber(target.radius) or 1.5) + 0.4
        end
        points[handle] = target
        loop()
    else
        if target.kind == 'model' then
            target.hashes = {}
            for _, model in ipairs(target.models or {}) do
                target.hashes[type(model) == 'string' and joaat(model) or model] = true
            end
        end
        reaches[handle] = target
        bind()
    end
    return handle
end)

exports('PromptRemove', function(handle)
    points[handle] = nil
    reaches[handle] = nil
end)

exports('PromptDisable', function(state)
    disabledBy[GetInvokingResource() or Bridge.name] = state and true or nil
end)

AddEventHandler('onClientResourceStop', function(resource)
    disabledBy[resource] = nil
    for handle, point in pairs(points) do
        if point.owner == resource then points[handle] = nil end
    end
    for handle, reach in pairs(reaches) do
        if reach.owner == resource then reaches[handle] = nil end
    end
end)
