--[[
    The bridge's own alert on the client of somebody on duty: a notification through
    Bridge.notify and a blip that goes away by itself.
]]

local h = ...

local blips = {}

local function remove(blip)
    if blips[blip] then
        blips[blip] = nil
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
end

h.cleanup(function()
    for blip in pairs(blips) do remove(blip) end
end)

return {
    send = function(alert)
        local label = alert.code and ('%s %s'):format(alert.code, alert.title) or alert.title
        local urgent = alert.priority == 'high'
        h.bridge.notify.show(alert.message or alert.title, urgent and 'error' or 'info', { title = label, duration = 10000 })

        local look = alert.blip
        local blip = AddBlipForCoord(alert.coords.x, alert.coords.y, alert.coords.z)
        SetBlipSprite(blip, tonumber(look.sprite) or 161)
        SetBlipColour(blip, tonumber(look.colour) or 1)
        SetBlipScale(blip, (tonumber(look.scale) or 1.0) + 0.0)
        SetBlipAsShortRange(blip, false)
        if urgent then SetBlipFlashes(blip, true) end
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(label)
        EndTextCommandSetBlipName(blip)

        blips[blip] = true
        SetTimeout((tonumber(look.seconds) or 120) * 1000, function() remove(blip) end)
        return true
    end,
}
