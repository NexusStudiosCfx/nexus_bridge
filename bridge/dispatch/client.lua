--[[
    Bridge.dispatch has nothing to call on the client: an alert is sent from the server, where
    a cheater cannot make one up. This half carries out what the server half asks of one
    client: handing the alert to a dispatch resource that only takes them from a client, or
    showing the bridge's own alert.
]]

local h = ...

return {
    adapters = true,
    caps = {},

    build = function(adapter)
        if adapter and adapter.send and h.hub then
            h.onNet('nexus_bridge:dispatch:send', function(alert)
                if type(alert) ~= 'table' or type(alert.coords) ~= 'table' or type(alert.title) ~= 'string' then return end
                alert.coords = vector3(alert.coords.x + 0.0, alert.coords.y + 0.0, alert.coords.z + 0.0)
                alert.blip = type(alert.blip) == 'table' and alert.blip or {}
                alert.jobs = type(alert.jobs) == 'table' and alert.jobs or {}
                adapter.send(alert)
            end)
        end
        return {}
    end,
}
