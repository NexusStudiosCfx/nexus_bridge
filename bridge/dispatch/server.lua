--[[
    Bridge.dispatch (server): an alert for the police, the ambulance or any other job, in
    whatever the server shows them with.

      Bridge.dispatch.send(alert)     true when the alert was handed over

      alert = {
          title = 'Store robbery',            what happened, in a few words (required)
          coords = vector3(25.7, -1347.3, 29.5),                           (required)
          message = 'The silent alarm of a store went off',   a line of detail
          code = '10-90',
          location = 'Innocence Blvd',        a name for the place, where one is shown
          jobs = { 'police' },                who receives it; without it the jobs in config.lua
          priority = 'low' | 'medium' | 'high',               'medium' when left out
          blip = { sprite = 161, colour = 1, scale = 1.0, seconds = 120 },
          source = 12,                        the player it is about, when there is one
      }

    With no dispatch resource running the bridge shows the alert itself: whoever is on duty in
    one of the jobs gets a notification and a blip on the map. supports('blip') tells whether
    the blip of the alert is used; a resource that draws its own ignores it.

    A dispatch resource that only takes alerts from a client gets it through one: the player
    the alert is about, or without one any player who is connected.
]]

local h = ...

local PRIORITIES = { low = true, medium = true, high = true }

local function text(value, limit)
    if type(value) ~= 'string' or value == '' then return nil end
    return #value > limit and value:sub(1, limit) or value
end

--- Positions arrive as a vector3, a vector4 or a table with x, y and z.
local function position(coords)
    local kind = type(coords)
    if kind ~= 'vector3' and kind ~= 'vector4' and kind ~= 'table' then return nil end
    local x, y, z = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z)
    if not x or not y then return nil end
    return vector3(x + 0.0, y + 0.0, (z or 0.0) + 0.0)
end

local function jobList(jobs, default)
    if type(jobs) == 'string' then jobs = { jobs } end
    if type(jobs) ~= 'table' then jobs = default end
    local out, seen = {}, {}
    for _, job in ipairs(type(jobs) == 'table' and jobs or {}) do
        if type(job) == 'string' and job ~= '' and not seen[job] then
            seen[job] = true
            out[#out + 1] = job
        end
    end
    return out
end

local function blipOf(blip)
    blip = type(blip) == 'table' and blip or {}
    return {
        sprite = math.floor(tonumber(blip.sprite) or 161),
        colour = math.floor(tonumber(blip.colour or blip.color) or 1),
        scale = (tonumber(blip.scale) or 1.0) + 0.0,
        seconds = math.max(5, math.min(math.floor(tonumber(blip.seconds) or 120), 3600)),
    }
end

return {
    adapters = true,
    caps = { 'blip', 'priority', 'code' },

    build = function(adapter)
        local dispatch = {}

        if not adapter then
            dispatch.send = h.unavailable('send', function() return false end)
            return dispatch
        end

        local settings = h.settings()

        function dispatch.send(alert)
            if type(alert) ~= 'table' then return false end
            local title, coords = text(alert.title, 120), position(alert.coords)
            if not title or not coords then return false end

            local jobs = jobList(alert.jobs, settings.jobs or { 'police' })
            if #jobs == 0 then return false end

            local clean = {
                title = title,
                message = text(alert.message, 500) or title,
                code = text(alert.code, 16),
                location = text(alert.location, 80),
                coords = coords,
                jobs = jobs,
                priority = PRIORITIES[alert.priority] and alert.priority or 'medium',
                blip = blipOf(alert.blip),
                source = math.type(alert.source) == 'integer' and alert.source > 0 and alert.source or nil,
            }

            if adapter.send then
                local ok, sent = pcall(adapter.send, clean)
                if not ok then
                    h.once('send', ('the %s adapter could not send an alert: %s'):format(tostring(h.adapter), tostring(sent)))
                    return false
                end
                return sent ~= false
            end

            -- The resource takes alerts from a client only.
            local through = clean.source and DoesPlayerExist(tostring(clean.source)) and clean.source or nil
            if not through then
                local players = GetPlayers()
                through = players[1] and tonumber(players[1]) or nil
            end
            if not through then return false end
            clean.coords = { x = coords.x, y = coords.y, z = coords.z }
            TriggerClientEvent('nexus_bridge:dispatch:send', through, clean)
            return true
        end

        return dispatch
    end,

    selftest = function(dispatch, t)
        if not dispatch.available then
            t.skip('everything', 'dispatch is switched off')
            return
        end
        t.check('an alert without a title or a place is refused',
            dispatch.send({ coords = vector3(0.0, 0.0, 0.0) }) == false and dispatch.send({ title = 'x' }) == false and dispatch.send(nil) == false,
            dispatch.name)
        t.note('no alert is sent by the self-test: it would reach the people on duty')
    end,
}
