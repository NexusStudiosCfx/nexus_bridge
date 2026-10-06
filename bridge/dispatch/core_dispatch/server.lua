--[[
    core_dispatch (C8RE) adapter. Written against the vendor's documentation (the resource is
    escrowed); see docs/adapters.md.

    The server export sendAlert takes one table (the client export of the same name takes a
    row of arguments instead, which is not the one used here).

    What to know about core_dispatch:
      - `message` is the one line of an alert, so the title is used and the detail goes in
        `extraInfo`;
      - `priority` is a flag for urgent, `time` how long the alert shows in milliseconds;
      - the blip is a sprite and a colour. How long it stays is the resource's own setting.
]]

return {
    caps = { blip = true, priority = true, code = true },

    send = function(alert)
        local extra = nil
        if alert.message ~= alert.title then
            extra = { { icon = 'fa-circle-info', info = alert.message } }
        end
        exports['core_dispatch']:sendAlert({
            code = alert.code or '',
            message = alert.title,
            extraInfo = extra,
            coords = alert.coords,
            priority = alert.priority == 'high',
            job = alert.jobs,
            time = 10000,
            blip = alert.blip.sprite,
            color = alert.blip.colour,
        })
        return true
    end,
}
