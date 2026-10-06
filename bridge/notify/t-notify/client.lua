--[[
    t-notify. Written against t-notify 2.1.0; see docs/adapters.md.

    Custom({ style, title, message, duration }) shows a title, Alert({ style, message, duration })
    shows a message alone. The style is required there, and one it does not know breaks its
    page: only its four standard styles are passed.
]]

return {
    caps = { title = true, duration = true, warning = true },

    show = function(message, kind, title, duration)
        local notify = exports['t-notify']
        if title then
            notify:Custom({ style = kind, title = title, message = message, duration = duration })
        else
            notify:Alert({ style = kind, message = message, duration = duration })
        end
    end,
}
