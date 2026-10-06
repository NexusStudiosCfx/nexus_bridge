--[[
    lation_ui notifications. Written against the vendor's documentation; see docs/adapters.md.

    notify({ title, message, type, duration })
]]

return {
    caps = { title = true, duration = true, warning = true },

    show = function(message, kind, title, duration)
        exports.lation_ui:notify({ title = title, message = message, type = kind, duration = duration })
    end,
}
