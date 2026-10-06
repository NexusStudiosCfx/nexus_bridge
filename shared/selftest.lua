--[[
    The self-test: `bridge selftest`, once `set nexus_bridge_selftest 1` is in server.cfg
    (`setr` to run the client half from F8 as well).

    Each module says how to try itself in the `selftest` function of its definition. The steps
    call the real resource behind the adapter and are harmless: they read, they ask about
    players and accounts that do not exist, and what they create they remove again. Where the
    resource behind an adapter has no way to remove something (a bank cannot delete an
    account), the step says in a NOTE line what it left. A step that would need a connected
    player is skipped on an empty server and says so.
]]

local internal = Bridge.internal
local registry = BridgeRegistry

local function run()
    local passed, total, skipped = 0, 0, 0

    local function tryModule(name)
        local record = internal.records[name]
        if not record or type(record.def.selftest) ~= 'function' then return end

        local t = {}

        function t.check(label, ok, detail)
            total = total + 1
            if ok then passed = passed + 1 end
            print(('%s  %s (%s): %s%s'):format(ok and 'PASS' or 'FAIL', name, record.api.name, label,
                detail ~= nil and (' [' .. tostring(detail) .. ']') or ''))
        end

        function t.skip(label, why)
            skipped = skipped + 1
            print(('SKIP  %s (%s): %s [%s]'):format(name, record.api.name, label, why))
        end

        --- Something the owner should know that is neither a pass nor a miss.
        function t.note(text)
            print(('NOTE  %s (%s): %s'):format(name, record.api.name, text))
        end

        local ok, problem = pcall(record.def.selftest, record.api, t, record.helper)
        if not ok then t.check('ran to the end', false, problem) end
    end

    for _, name in ipairs(registry.modules) do tryModule(name) end
    for _, name in ipairs(registry.utilities) do tryModule(name) end

    if passed == total then
        print(('nexus_bridge selftest (%s): %d of %d steps passed, %d skipped'):format(Bridge.side, passed, total, skipped))
    else
        -- The word "failed" is there on purpose: log scanners look for it.
        print(('nexus_bridge selftest (%s): %d of %d steps passed, %d failed, %d skipped'):format(Bridge.side, passed, total, total - passed, skipped))
    end
    return passed == total
end

function internal.selftest()
    if GetConvarInt('nexus_bridge_selftest', 0) ~= 1 then
        print('nexus_bridge: the self-test is off. Turn it on with "set nexus_bridge_selftest 1" ("setr" for the client half).')
        return
    end
    -- Steps may wait on a database or a callback, which only a thread can do.
    CreateThread(run)
end
