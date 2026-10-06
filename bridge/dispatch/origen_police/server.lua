--[[
    origen_police adapter. Written against the vendor's documentation (the resource is
    escrowed); see docs/adapters.md.

    The server export SendAlert takes one table, of which `coords`, `title` and `type` must
    be there.

    What to know about origen_police:
      - `job` is one job, so an alert for several jobs is sent once for each;
      - `type` sorts alerts in the resource's dashboard: GENERAL is the one for everything
        that is not a radar, drugs or a shooting;
      - there is no field for a code (it goes in front of the title), and none for a
        priority or a blip.
]]

return {
    caps = { blip = false, priority = false, code = true },

    send = function(alert)
        local title = alert.code and ('%s %s'):format(alert.code, alert.title) or alert.title
        for _, job in ipairs(alert.jobs) do
            exports['origen_police']:SendAlert({
                coords = alert.coords,
                title = title,
                type = 'GENERAL',
                message = alert.message,
                job = job,
            })
        end
        return true
    end,
}
