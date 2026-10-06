--[[
    Runs in nexus_bridge itself, on both sides, once the adapters are decided.

    It loads every module into the bridge's own Lua state. Two things depend on that: the
    exports, for resources that would rather call an export than include the loader (and for
    JavaScript and C#), and the bridge's events, which the modules raise from here so that a
    hundred resources listening cost one framework event handler, not a hundred.

    Every function of every module is an export named <Module><Function>:

        Bridge.inventory.addItem(src, 'water', 1)
        exports.nexus_bridge:InventoryAddItem(src, 'water', 1)

    and exports.nexus_bridge:Call('inventory.addItem', src, 'water', 1) reaches the same
    function by its path.
]]

local internal = Bridge.internal
local registry = BridgeRegistry

local function pascal(name)
    return (name:gsub('^%l', string.upper))
end

local function open(name)
    local ok, record = pcall(internal.find, name)
    if not ok then
        print(('[nexus_bridge] the %s module did not load on the %s: %s'):format(name, Bridge.side, tostring(record)))
        return
    end
    if not record then return end

    local api = record.api
    for key, value in pairs(api) do
        if type(value) == 'function' then
            -- Looked up on every call: the table is refilled when the adapter changes.
            exports(pascal(name) .. pascal(key), function(...)
                return api[key](...)
            end)
        end
    end
end

for _, name in ipairs(registry.modules) do open(name) end
for _, name in ipairs(registry.utilities) do open(name) end

exports('Call', function(path, ...)
    local module, fn = tostring(path):match('^(%a[%w_]*)%.(%a[%w_]*)$')
    local record = module and internal.find(module)
    local target = record and record.api[fn]
    if type(target) ~= 'function' then
        error(('nexus_bridge has no %s on the %s'):format(tostring(path), Bridge.side), 2)
    end
    return target(...)
end)

exports('Version', function()
    return Bridge.version
end)

exports('Supports', function(module, feature)
    return Bridge.supports(module, feature)
end)
