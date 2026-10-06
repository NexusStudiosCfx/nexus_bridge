--[[
    cd_dispatch (Codesign) adapter. Written against the vendor's documentation (the resource
    is escrowed); see docs/adapters.md.

    From a server script an alert is the client event cd_dispatch:AddNotification sent to
    everybody (-1): each client decides from `job_table` whether it is shown.

    What to know about cd_dispatch:
      - there is no field for a code: it goes in front of the title;
      - `blip.time` is in minutes;
      - `flash` 1 makes the screen of the receivers flash, `sound` 1 is the plain alert
        sound and 2 the double one.
]]

return {
    caps = { blip = true, priority = true, code = true },

    send = function(alert)
        local urgent = alert.priority == 'high'
        TriggerClientEvent('cd_dispatch:AddNotification', -1, {
            job_table = alert.jobs,
            coords = alert.coords,
            title = alert.code and ('%s - %s'):format(alert.code, alert.title) or alert.title,
            message = alert.message,
            flash = urgent and 1 or 0,
            unique_id = tostring(math.random(0, 9999999)),
            sound = urgent and 2 or 1,
            blip = {
                sprite = alert.blip.sprite,
                scale = alert.blip.scale,
                colour = alert.blip.colour,
                flashes = urgent,
                text = alert.title,
                time = math.max(1, math.ceil(alert.blip.seconds / 60)),
                radius = 0,
            },
        })
        return true
    end,
}
