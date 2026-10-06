--[[
    ox_lib notifications. Written against ox_lib 3.39.0; see docs/adapters.md.

    Through the export, not lib.notify: that global only exists in a resource that includes
    ox_lib, and the bridge does not ask that of anybody.
]]

return {
    caps = { title = true, duration = true, warning = true },

    show = function(message, kind, title, duration)
        exports.ox_lib:notify({
            title = title,
            description = message,
            -- ox_lib's own word for the plain kind.
            type = kind == 'info' and 'inform' or kind,
            duration = duration,
        })
    end,
}
