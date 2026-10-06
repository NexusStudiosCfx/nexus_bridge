--[[
    okokNotify. Written against the vendor's documentation (the resource is escrowed); see
    docs/adapters.md.

    Alert(title, message, time, type, playSound): the title comes first and is not optional
    there, so a notification without one gets an empty title.
]]

return {
    caps = { title = true, duration = true, warning = true },

    show = function(message, kind, title, duration)
        exports['okokNotify']:Alert(title or '', message, duration, kind, false)
    end,
}
