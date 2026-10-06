--[[
    bridge_test, client half: `/bridgetest` in F8 runs the client modules of nexus_bridge and
    prints one line per check.
]]

local function check(what, ok, detail)
    print(('[bridge_test] %s  %s%s'):format(ok and 'OK  ' or 'NO  ', what, detail ~= nil and (': ' .. tostring(detail)) or ''))
end

RegisterCommand('bridgetest', function()
    check('Bridge.version', type(Bridge.version) == 'string', Bridge.version)
    check('Bridge.side', Bridge.side == 'client')
    check('format.money', Bridge.format.money(1234567) ~= nil, Bridge.format.money(1234567))
end, false)
