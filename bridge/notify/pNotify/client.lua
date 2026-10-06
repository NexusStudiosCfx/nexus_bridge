--[[
    pNotify. Written against the last commit of Nick78111/pNotify (2017, unmaintained); see
    docs/adapters.md.

    SendNotification({ text, type, timeout }). It has no title, and its text is HTML, so the
    text is escaped here.
]]

local ESCAPES = { ['&'] = '&amp;', ['<'] = '&lt;', ['>'] = '&gt;', ['"'] = '&quot;', ["'"] = '&#39;' }

return {
    caps = { duration = true, warning = true },

    show = function(message, kind, _, duration)
        exports.pNotify:SendNotification({ text = (message:gsub('[&<>"\']', ESCAPES)), type = kind, timeout = duration })
    end,
}
