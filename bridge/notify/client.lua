--[[
    Bridge.notify (client): shows the local player a notification, in whatever the server
    shows them with.

      Bridge.notify.show(message, kind, options)
          kind      'info' (when left out), 'success', 'error' or 'warning'
          options   { title = string, duration = milliseconds }

    A resource that has no separate title shows it in front of the message, and one that has
    no warning shows it as information: supports('title') and supports('warning') tell.
    Text is plain text. For a resource that renders HTML it is escaped, so a player's name
    cannot put markup on somebody's screen.
]]

local h = ...

local KINDS = { info = true, success = true, error = true, warning = true }

return {
    adapters = true,
    caps = { 'title', 'duration', 'warning' },

    build = function(adapter)
        -- Switched off in the config: nothing is shown, and the first call says so.
        if not adapter then
            return { show = h.unavailable('show', function() return false end) }
        end
        local a = h.complete(adapter, { show = function() return false end })
        local caps = adapter.caps or {}
        local settings = h.settings()
        local notify = {}

        function notify.show(message, kind, options)
            if type(message) ~= 'string' or message == '' then return false end
            options = type(options) == 'table' and options or {}
            local title = type(options.title) == 'string' and options.title ~= '' and options.title or settings.title
            local duration = math.floor(tonumber(options.duration) or tonumber(settings.duration) or 5000)
            duration = math.max(500, math.min(duration, 60000))
            if type(title) == 'string' and not caps.title then
                message, title = ('%s: %s'):format(title, message), nil
            end
            a.show(message, KINDS[kind] and kind or 'info', type(title) == 'string' and title or nil, duration)
            return true
        end

        -- What Bridge.notify.send on the server arrives as. Only nexus_bridge listens to it.
        if h.hub then
            h.onNet('nexus_bridge:notify', function(message, kind, options)
                if type(message) ~= 'string' or #message > 1000 then return end
                notify.show(message, kind, options)
            end)
        end

        return notify
    end,

    selftest = function(notify, t)
        if not notify.available then
            t.skip('a notification', 'notifications are switched off')
            return
        end
        t.check('a notification is shown', notify.show('nexus_bridge self-test', 'success', { title = 'Bridge', duration = 3000 }) == true, notify.name)
        t.check('a message that is not text is refused', notify.show(nil) == false and notify.show(42) == false)
    end,
}
