--[[
    NPWD adapter (client). Written against npwd 3.16.0; docs/adapters.md lists the lines.

    A notification that belongs to no app is a "system notification". It needs an id of its
    own as text, and NPWD raises when `keepOpen` or `duration` are missing. The duration is
    in milliseconds.
]]

local count = 0

return {
    caps = { open = true },

    isOpen = function()
        return exports.npwd:isPhoneVisible() == true
    end,

    notify = function(note)
        count = count + 1
        exports.npwd:createSystemNotification({
            uniqId = ('nexus_bridge_%d'):format(count),
            content = note.message,
            secondaryTitle = note.title,
            keepOpen = false,
            duration = 5000,
        })
    end,
}
