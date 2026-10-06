--[[
    Bridge.log (server): a line for the server's log, wherever the owner keeps it.

      Bridge.log.send(channel, entry)       true when the line was handed over
          channel   what it is about, in one word: 'shop', 'admin', 'money'. The owner
                    decides in config.lua where each channel goes
          entry     a text, or a table:
                      title      a few words
                      message    the line itself
                      fields     details, as { key = value } or { { name = 'Item', value = 'water' } }
                      level      'info' (when left out), 'warn' or 'error'
                      player     a player id: their name and character id are added

    Without anything else the line goes to a Discord webhook from config.lua. The webhooks
    are read by nexus_bridge only and never leave the server: every other resource hands its
    lines to nexus_bridge, which also keeps them from arriving faster than Discord takes them.

    A channel with no webhook and no 'default' is dropped without a word: an owner who wants
    no logs gets none.
]]

local h = ...

local LEVELS = { info = true, warn = true, error = true }

local function text(value, limit)
    if value == nil then return nil end
    value = tostring(value)
    if value == '' then return nil end
    return #value > limit and (value:sub(1, limit - 3) .. '...') or value
end

--- Details as a list of { name, value }, whichever way they were given, in a steady order.
local function fieldList(fields)
    local out = {}
    if type(fields) ~= 'table' then return out end
    if fields[1] ~= nil then
        for _, field in ipairs(fields) do
            if type(field) == 'table' and field.name ~= nil and #out < 20 then
                out[#out + 1] = { name = text(field.name, 80) or '?', value = text(field.value, 500) or '-' }
            end
        end
        return out
    end
    local keys = {}
    for key in pairs(fields) do keys[#keys + 1] = tostring(key) end
    table.sort(keys)
    for _, key in ipairs(keys) do
        if #out < 20 then out[#out + 1] = { name = text(key, 80), value = text(fields[key], 500) or '-' } end
    end
    return out
end

return {
    adapters = true,
    caps = {},

    build = function(adapter)
        local log = {}

        if not adapter then
            log.send = function() return false end
            return log
        end

        if not h.hub then
            function log.send(channel, entry)
                local ok, sent = pcall(function() return exports.nexus_bridge:LogSend(channel, entry) end)
                return ok and sent == true
            end
            return log
        end

        local framework = h.bridge.framework

        function log.send(channel, entry)
            if type(channel) ~= 'string' or channel == '' then return false end
            if type(entry) == 'string' then entry = { message = entry } end
            if type(entry) ~= 'table' or not adapter.send then return false end
            local title, message = text(entry.title, 120), text(entry.message, 1800)
            if not title and not message then return false end

            local clean = {
                title = title or channel,
                message = message,
                fields = fieldList(entry.fields),
                level = LEVELS[entry.level] and entry.level or 'info',
                resource = GetInvokingResource() or h.resource,
            }
            local src = math.type(entry.player) == 'integer' and entry.player > 0 and entry.player or nil
            if src and DoesPlayerExist(tostring(src)) then
                clean.player = { src = src, name = GetPlayerName(tostring(src)), id = framework.getIdentifier(src) }
            end

            local ok, sent = pcall(adapter.send, channel, clean)
            if not ok then
                h.once('send', ('the %s adapter could not take a log line: %s'):format(tostring(h.adapter), tostring(sent)))
                return false
            end
            return sent ~= false
        end

        return log
    end,

    selftest = function(log, t)
        t.check('what is no log line is refused', log.send(nil, 'x') == false and log.send('selftest', nil) == false and log.send('selftest', {}) == false, log.name)
        t.note('no line is sent by the self-test')
    end,
}
