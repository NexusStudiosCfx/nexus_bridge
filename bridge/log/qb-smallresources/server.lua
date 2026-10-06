--[[
    qb-smallresources adapter: QBCore's own Discord log. Written against qb-smallresources
    1.5.0; docs/adapters.md lists the lines. Only used when config.lua names it, because
    nearly every QBCore server runs the resource and few have filled in its webhooks.

    What to know about it:
      - the server event qb-log:server:CreateLog takes the name of a webhook from the list
        in the resource's own server/logs.lua. A name that is not in that list is dropped,
        so every line goes to 'default' unless Config.log.names says where a channel goes:
            Config.log.names = { shop = 'shops', admin = 'anticheat' }
      - a line is a title and one text: the details are written under the message;
      - the colour is one of its own words: blue, orange, red.
]]

local COLOURS = { info = 'blue', warn = 'orange', error = 'red' }

return {
    send = function(channel, entry)
        local names = type(Config) == 'table' and type(Config.log) == 'table' and Config.log.names or nil
        local name = type(names) == 'table' and names[channel] or 'default'

        local lines = { entry.message }
        if entry.player then
            lines[#lines + 1] = ('**Player:** %s (%d)%s'):format(entry.player.name or 'unknown', entry.player.src, entry.player.id and (', ' .. entry.player.id) or '')
        end
        for _, field in ipairs(entry.fields) do
            lines[#lines + 1] = ('**%s:** %s'):format(field.name, field.value)
        end

        TriggerEvent('qb-log:server:CreateLog', name, ('%s (%s / %s)'):format(entry.title, entry.resource, channel), COLOURS[entry.level], table.concat(lines, '\n'))
        return true
    end,
}
