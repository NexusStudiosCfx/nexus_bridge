--[[
    brutal_notify. Written against the vendor's documentation (the resource is escrowed); see
    docs/adapters.md.

    SendAlert(title, message, time, type, sound)
]]

return {
    caps = { title = true, duration = true, warning = true },

    show = function(message, kind, title, duration)
        exports['brutal_notify']:SendAlert(title or '', message, duration, kind, false)
    end,
}
