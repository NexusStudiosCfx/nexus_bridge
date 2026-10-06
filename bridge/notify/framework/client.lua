--[[
    The framework's own notification: what a server shows when it runs no notification
    resource of its own. The framework module knows how each framework does it.
]]

local h = ...

return {
    caps = { duration = true, warning = true },

    show = function(message, kind, _, duration)
        h.bridge.framework.notify(message, kind, duration)
    end,
}
