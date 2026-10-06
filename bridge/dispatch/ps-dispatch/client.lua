--[[
    ps-dispatch adapter (client). Written against ps-dispatch 3.0.0, 2.2.2 and 1.4.3;
    docs/adapters.md lists the lines.

    What to know about ps-dispatch:
      - an alert for a whole job can only be raised from a client: CustomAlert(data). The
        server half of the bridge picks the client;
      - version 1 names things differently: the jobs are `job`, `dispatchCode` is the code
        that is shown and `description` the name of the blip. From version 2 the jobs are
        `jobs`, `code` is shown and `dispatchCode` is only a name for the kind of alert;
      - from version 2 the blip of the alert is used unless `dispatchCode` is a kind the
        server owner styled in the resource's own config, so a name of our own is given;
      - `jobs` are compared with the name and with the type of a job, so job names work;
      - `length` is the blip's time on the map in minutes; `priority` 1 is red, 2 normal.
]]

local major = tonumber(tostring(GetResourceMetadata('ps-dispatch', 'version', 0) or ''):match('^(%d+)')) or 2

return {
    send = function(alert)
        local data = {
            message = alert.title,
            coords = alert.coords,
            priority = alert.priority == 'high' and 1 or 2,
            sprite = alert.blip.sprite,
            color = alert.blip.colour,
            scale = alert.blip.scale,
            length = math.max(1, math.ceil((alert.blip.seconds or 120) / 60)),
        }
        if major <= 1 then
            data.dispatchCode = alert.code or alert.title
            data.description = alert.title
            data.job = alert.jobs
        else
            data.dispatchCode = 'nexus_bridge'
            data.code = alert.code
            data.information = alert.message ~= alert.title and alert.message or nil
            data.jobs = alert.jobs
        end
        exports['ps-dispatch']:CustomAlert(data)
        return true
    end,
}
