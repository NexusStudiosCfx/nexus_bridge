--[[
    mythic_notify. Written against the JayMontana36 fork, v1.0.3 (the original repository is
    gone); see docs/adapters.md.

    DoCustomHudText(type, text, length). It knows three kinds: inform, success and error, so
    a warning is shown as information. It has no title. And it puts the text into its page
    as HTML, so the text is escaped here.
]]

local KINDS = { info = 'inform', warning = 'inform', success = 'success', error = 'error' }
local ESCAPES = { ['&'] = '&amp;', ['<'] = '&lt;', ['>'] = '&gt;', ['"'] = '&quot;', ["'"] = '&#39;' }

return {
    caps = { duration = true },

    show = function(message, kind, _, duration)
        exports['mythic_notify']:DoCustomHudText(KINDS[kind], (message:gsub('[&<>"\']', ESCAPES)), duration)
    end,
}
