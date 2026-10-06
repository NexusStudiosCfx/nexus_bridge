--[[
    wasabi_notify. Written against the vendor's documentation; see docs/adapters.md.

    notify(title, message, time, type, sound, icon, id)
]]

return {
    caps = { title = true, duration = true, warning = true },

    show = function(message, kind, title, duration)
        exports.wasabi_notify:notify(title, message, duration, kind)
    end,
}
