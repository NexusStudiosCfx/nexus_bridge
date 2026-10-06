--[[
    Says once, at start-up, when a newer release is on GitHub. Switch it off with
    Config.updateCheck = false. A server without internet access simply hears nothing.
]]

if Config.updateCheck == false then return end

local RELEASES = 'https://api.github.com/repos/NexusStudiosCfx/nexus_bridge/releases/latest'
local internal = Bridge.internal

SetTimeout(5000, function()
    PerformHttpRequest(RELEASES, function(status, body)
        if status ~= 200 or type(body) ~= 'string' then return end
        local ok, release = pcall(json.decode, body)
        if not ok or type(release) ~= 'table' or type(release.tag_name) ~= 'string' then return end

        local latest = internal.parseVersion(release.tag_name)
        local installed = internal.parseVersion(Bridge.version)
        if not latest or not installed or internal.compareVersions(installed, latest) >= 0 then return end

        print(('[nexus_bridge] release %s is out and %s is installed: https://github.com/NexusStudiosCfx/nexus_bridge/releases')
            :format(release.tag_name, Bridge.version))
    end, 'GET', '', { ['User-Agent'] = 'nexus_bridge' })
end)
