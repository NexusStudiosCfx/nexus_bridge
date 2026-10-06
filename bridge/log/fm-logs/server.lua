--[[
    fm-logs (Fivemerr) adapter. Written against fm-logs 1.0.3 and its documentation;
    docs/adapters.md lists the lines.

    createLog(data) wants LogType and Message; Level, Resource, Source (a player id, for the
    player's details) and Metadata are optional. The channel is the LogType.
]]

return {
    send = function(channel, entry)
        local metadata = { title = entry.title }
        for _, field in ipairs(entry.fields) do metadata[field.name] = field.value end
        if entry.player then metadata.character = entry.player.id end
        exports['fm-logs']:createLog({
            LogType = channel,
            Message = entry.message or entry.title,
            Level = entry.level,
            Resource = entry.resource,
            Source = entry.player and entry.player.src or nil,
            Metadata = metadata,
        })
        return true
    end,
}
