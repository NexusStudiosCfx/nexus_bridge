--[[
    No dispatch resource: the bridge's own alert. Everybody on duty in one of the jobs gets a
    notification and a blip, drawn by the client half of this adapter.

    Who is on duty comes from Bridge.framework, so a framework without duty reaches everybody
    with the job, and a server without a framework nobody.
]]

local h = ...

return {
    caps = { blip = true, priority = true, code = true },

    send = function(alert)
        local framework = h.bridge.framework
        local payload = {
            title = alert.title,
            message = alert.message,
            code = alert.code,
            priority = alert.priority,
            blip = alert.blip,
            coords = { x = alert.coords.x, y = alert.coords.y, z = alert.coords.z },
        }
        local reached = {}
        for _, job in ipairs(alert.jobs) do
            for _, src in ipairs(framework.getOnDuty(job)) do
                if not reached[src] then
                    reached[src] = true
                    TriggerClientEvent('nexus_bridge:dispatch:send', src, payload)
                end
            end
        end
        return framework.available == true
    end,
}
