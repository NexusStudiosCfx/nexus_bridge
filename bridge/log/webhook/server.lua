--[[
    The bridge's own log adapter: Discord webhooks from Config.log in config.lua.

    A channel goes to the webhook of its own name, or to 'default' when it has none. A
    channel set to an empty text is dropped. Lines are collected for a moment and sent
    together, at most ten to a request and one request every second and a half for each
    webhook, which stays below what Discord accepts. When Discord asks for a pause the
    lines wait; after three tries a batch is given up, and the console says so once
    without naming the address.

    Nothing runs while there is nothing to send.
]]

local h = ...

local COLOURS = { info = 3447003, warn = 15105570, error = 15158332 }
local BATCH, GAP, KEPT = 10, 1500, 200

local queues, waiting = {}, {}

local function settings()
    return type(Config) == 'table' and type(Config.log) == 'table' and Config.log or {}
end

local function urlFor(channel)
    local hooks = settings().webhooks
    if type(hooks) ~= 'table' then return nil end
    local url = hooks[channel]
    if url == nil then url = hooks.default end
    if type(url) ~= 'string' or not url:match('^https://') then return nil end
    return url
end

local flush

local function later(url, ms)
    if waiting[url] then return end
    waiting[url] = true
    SetTimeout(ms, function()
        waiting[url] = nil
        flush(url)
    end)
end

function flush(url)
    local queue = queues[url]
    if not queue or #queue == 0 then
        queues[url] = nil
        return
    end
    local batch = {}
    for _ = 1, math.min(BATCH, #queue) do batch[#batch + 1] = table.remove(queue, 1) end

    local tries = (batch[1].tries or 0) + 1
    local embeds = {}
    for index, item in ipairs(batch) do embeds[index] = item.embed end

    PerformHttpRequest(url, function(status)
        status = tonumber(status) or 0
        if status == 429 and tries < 3 then
            for index = #batch, 1, -1 do
                batch[index].tries = tries
                table.insert(queue, 1, batch[index])
            end
            queues[url] = queue
            later(url, 10000)
            return
        end
        if status < 200 or status >= 300 then
            h.once('http', ('a Discord webhook answered %d and %d log lines were not delivered. Check the addresses under Config.log.webhooks.'):format(status, #batch))
        end
    end, 'POST', json.encode({ username = settings().username, embeds = embeds }), { ['Content-Type'] = 'application/json' })

    if #queue > 0 then later(url, GAP) end
end

return {
    send = function(channel, entry)
        local url = urlFor(channel)
        if not url then return false end

        local fields = {}
        if entry.player then
            local who = ('%s (%d)'):format(entry.player.name or 'unknown', entry.player.src)
            if entry.player.id then who = ('%s, %s'):format(who, entry.player.id) end
            fields[#fields + 1] = { name = 'Player', value = who, inline = true }
        end
        for _, field in ipairs(entry.fields) do
            fields[#fields + 1] = { name = field.name, value = field.value, inline = true }
        end

        local queue = queues[url] or {}
        queues[url] = queue
        -- A webhook that stays unreachable must not grow a list without end.
        while #queue >= KEPT do table.remove(queue, 1) end
        queue[#queue + 1] = { embed = {
            title = entry.title,
            description = entry.message,
            color = COLOURS[entry.level] or COLOURS.info,
            fields = fields,
            footer = { text = ('%s / %s'):format(entry.resource, channel) },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        } }
        later(url, 500)
        return true
    end,
}
