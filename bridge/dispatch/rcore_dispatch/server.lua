--[[
    rcore_dispatch adapter. Written against the vendor's documentation (the resource is
    escrowed); see docs/adapters.md.

    From a server script an alert is the server event rcore_dispatch:server:sendAlert, raised
    with TriggerEvent. Its priority has the same three words the bridge uses, `blip_time` is
    in seconds, and `type` is the heading the alert is counted under in the resource's
    statistics: 'alerts' is the general one.
]]

return {
    caps = { blip = true, priority = true, code = true },

    send = function(alert)
        local line = alert.message ~= alert.title and ('%s: %s'):format(alert.title, alert.message) or alert.title
        TriggerEvent('rcore_dispatch:server:sendAlert', {
            code = alert.code or '',
            default_priority = alert.priority,
            coords = alert.coords,
            job = alert.jobs,
            text = line,
            type = 'alerts',
            blip_time = alert.blip.seconds,
            blip = {
                sprite = alert.blip.sprite,
                colour = alert.blip.colour,
                scale = alert.blip.scale,
                text = alert.title,
                flashes = alert.priority == 'high',
                radius = 0,
            },
        })
        return true
    end,
}
