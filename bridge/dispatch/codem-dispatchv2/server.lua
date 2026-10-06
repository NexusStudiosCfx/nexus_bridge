--[[
    codem-dispatchv2 adapter (CodeM's Dispatch v2). Written against the vendor's
    documentation (the resource is escrowed); see docs/adapters.md. The older codem-dispatch
    is another resource with another call, and is not covered.

    The server export SendDispatchAlert(data) answers the id of the call, or false.

    What to know about codem-dispatchv2:
      - from the server `street` has to be text: `true`, which makes the client look it up,
        is for the client export only. It is left out without a `location` in the alert;
      - `priority` is a flag for the red card, `duration` the seconds a card stays on screen
        (3 to 120) and `blip.length` the minutes a blip stays on the map;
      - the card shows one text, so title and detail share it.
]]

return {
    caps = { blip = true, priority = true, code = true },

    send = function(alert)
        local line = alert.message ~= alert.title and ('%s: %s'):format(alert.title, alert.message) or alert.title
        local id = exports['codem-dispatchv2']:SendDispatchAlert({
            code = alert.code,
            message = line,
            coords = alert.coords,
            street = alert.location,
            jobs = alert.jobs,
            priority = alert.priority == 'high',
            duration = 15,
            blip = {
                sprite = alert.blip.sprite,
                color = alert.blip.colour,
                scale = alert.blip.scale,
                length = math.max(1, math.ceil(alert.blip.seconds / 60)),
                flash = alert.priority == 'high',
            },
        })
        return id ~= false and id ~= nil
    end,
}
