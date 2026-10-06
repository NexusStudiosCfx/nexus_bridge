--[[
    Bridge.notify (server): a notification for a player, in whatever the server shows them with.

      Bridge.notify.send(src, message, kind, options)
          kind      'info' (when left out), 'success', 'error' or 'warning'
          options   { title = string, duration = milliseconds }
          src       a player id, or -1 for everybody

    The message goes to the bridge's client half, which shows it: there is one place that
    knows the notification resource, and it is on the client, where those resources live.
]]

local h = ...

local KINDS = { info = true, success = true, error = true, warning = true }

return {
    adapters = true,
    caps = {},

    build = function(adapter)
        local notify = {}

        local function send(src, message, kind, options)
            src = tonumber(src)
            if not src or type(message) ~= 'string' or message == '' then return false end
            options = type(options) == 'table' and options or {}
            TriggerClientEvent('nexus_bridge:notify', src, message, KINDS[kind] and kind or 'info', {
                title = type(options.title) == 'string' and options.title or nil,
                duration = tonumber(options.duration),
            })
            return true
        end

        -- Switched off in the config: nothing is sent, and the first call says so.
        notify.send = adapter and send or h.unavailable('send', function() return false end)
        return notify
    end,
}
