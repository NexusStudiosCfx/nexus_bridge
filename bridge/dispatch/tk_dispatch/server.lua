--[[
    tk_dispatch adapter. Written against the vendor's documentation (the resource is
    escrowed); see docs/adapters.md.

    The server export addCall(data) takes other fields than the client export of the same
    name: the server hands over the facts (`location`, `message`) where the client asks the
    resource to look them up.

    What to know about tk_dispatch:
      - `removeTime` and `showTime` are in milliseconds;
      - `priority` is free text that the documentation gives no list for, so it is left out
        and an urgent alert flashes instead.
]]

return {
    caps = { blip = true, priority = false, code = true },

    send = function(alert)
        local urgent = alert.priority == 'high'
        exports.tk_dispatch:addCall({
            title = alert.title,
            code = alert.code,
            message = alert.message ~= alert.title and alert.message or nil,
            coords = alert.coords,
            location = alert.location,
            removeTime = alert.blip.seconds * 1000,
            showTime = 10000,
            flash = urgent,
            playSound = true,
            jobs = alert.jobs,
            blip = {
                sprite = alert.blip.sprite,
                scale = alert.blip.scale,
                color = alert.blip.colour,
                flash = urgent,
            },
        })
        return true
    end,
}
