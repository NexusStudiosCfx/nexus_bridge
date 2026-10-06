--[[
    Fivemanage SDK (fmsdk) adapter. Written against fmsdk 3.2.0 and its documentation;
    docs/adapters.md lists the lines.

    LogMessage(level, message, metadata) writes to the default dataset. A dataset of its own
    has to exist in the owner's Fivemanage account first, so the channel goes into the
    metadata instead, where it can be filtered on. The SDK's levels are error, warn, info
    and debug, and it reads the player from `playerSource` in the metadata.
]]

return {
    send = function(channel, entry)
        local metadata = { channel = channel, resource = entry.resource, title = entry.title }
        for _, field in ipairs(entry.fields) do metadata[field.name] = field.value end
        if entry.player then
            metadata.playerSource = entry.player.src
            metadata.character = entry.player.id
        end
        exports.fmsdk:LogMessage(entry.level, entry.message or entry.title, metadata)
        return true
    end,
}
