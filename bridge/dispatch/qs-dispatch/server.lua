--[[
    qs-dispatch (Quasar) adapter. Written against the vendor's documentation (the resource is
    escrowed); see docs/adapters.md.

    From a server script an alert is the server event qs-dispatch:server:CreateDispatchCall,
    raised with TriggerEvent. `callCode` holds the code and a short text next to it, and
    `blip.time` is in milliseconds.
]]

return {
    caps = { blip = true, priority = true, code = true },

    send = function(alert)
        local urgent = alert.priority == 'high'
        TriggerEvent('qs-dispatch:server:CreateDispatchCall', {
            job = alert.jobs,
            callLocation = alert.coords,
            callCode = { code = alert.code or '', snippet = alert.title },
            message = alert.message,
            flashes = urgent,
            blip = {
                sprite = alert.blip.sprite,
                scale = alert.blip.scale,
                colour = alert.blip.colour,
                flashes = urgent,
                text = alert.title,
                time = alert.blip.seconds * 1000,
            },
        })
        return true
    end,
}
