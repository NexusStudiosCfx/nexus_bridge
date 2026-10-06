--[[
    The game's own feed, above the minimap: what is left when a server runs neither a
    notification resource nor a framework. It has no kinds and no duration; an error or a
    warning is told apart by its colour.
]]

local COLOURS = { error = '~r~', warning = '~o~', success = '~g~' }

return {
    caps = {},

    show = function(message, kind)
        local text = (COLOURS[kind] or '') .. message
        BeginTextCommandThefeedPost('STRING')
        -- One text component takes 99 characters.
        for start = 1, #text, 99 do
            AddTextComponentSubstringPlayerName(text:sub(start, start + 98))
        end
        EndTextCommandThefeedPostTicker(false, true)
    end,
}
