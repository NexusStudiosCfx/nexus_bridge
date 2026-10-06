--[[
    ESX adapter: the Discord log inside es_extended. Written against ESX Legacy 1.15.2;
    docs/adapters.md lists the lines. Only used when config.lua names it, because every ESX
    server has it and few have filled in its webhooks.

    ESX.DiscordLogFields(name, title, color, fields) takes the name of a webhook from ESX's
    own config, and falls back to its 'default' for a name it does not know, so the channel
    is handed over as it is. The fields are { name, value, inline }; a colour ESX does not
    know becomes its default one.
]]

local ESX = exports['es_extended']:getSharedObject()

local COLOURS = { info = 'default', warn = 'orange', error = 'red' }

return {
    send = function(channel, entry)
        if type(ESX) ~= 'table' or not ESX.DiscordLogFields then return false end
        local fields = {}
        if entry.message then fields[#fields + 1] = { name = 'Message', value = entry.message, inline = false } end
        if entry.player then
            local who = ('%s (%d)'):format(entry.player.name or 'unknown', entry.player.src)
            fields[#fields + 1] = { name = 'Player', value = entry.player.id and (who .. ', ' .. entry.player.id) or who, inline = true }
        end
        for _, field in ipairs(entry.fields) do
            fields[#fields + 1] = { name = field.name, value = field.value, inline = true }
        end
        fields[#fields + 1] = { name = 'Resource', value = entry.resource, inline = true }
        ESX.DiscordLogFields(channel, entry.title, COLOURS[entry.level], fields)
        return true
    end,
}
