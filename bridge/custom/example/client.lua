--[[
    A template for the client half of your own adapter. This folder is called "example",
    which is no category, so the bridge never loads it: copy it to bridge/custom/<category>/
    (bridge/custom/notify/, bridge/custom/target/ ...) and set that category to 'custom' in
    config.lua. docs/adding-an-adapter.md lists the functions each category expects.

    The file returns a table of functions. This one would be a notification adapter.
]]

local h = ...

return {
    -- What the resource behind this adapter can do. Scripts ask with supports('title').
    caps = { title = true, duration = true },

    show = function(message, kind, title, duration)
        -- exports.my_notify:Send({ text = message, type = kind, header = title, time = duration })
        h.debug(('a notification would be shown here: %s'):format(message))
    end,
}
