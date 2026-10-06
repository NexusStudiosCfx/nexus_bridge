--[[
    The doctor: `bridge doctor` in the server console (or F8 for the client half).

    It prints what was detected, the resource and version behind each adapter, what each adapter
    can and cannot do, and what the resources that use the bridge asked for in vain. A server
    owner pastes it into a support ticket; a script author reads it to see why a feature is off.

    `bridge selftest` and `bridge version` live here too.
    exports.nexus_bridge:Doctor() returns the same lines as a table.
]]

local internal = Bridge.internal
local registry = BridgeRegistry
local SERVER = IsDuplicityVersion()

-- usage[resource] = { uses = { module = adapter }, misses = { 'module.fn', ... }, seen = {},
-- broken = { module = message }, requires = range }
local usage = {}

AddEventHandler('nexus_bridge:internal:usage', function(resource, kind, module, detail)
    if type(resource) ~= 'string' or resource == Bridge.name then return end
    local entry = usage[resource]
    if not entry then
        entry = { uses = {}, misses = {}, seen = {}, broken = {} }
        usage[resource] = entry
    end
    if kind == 'use' then
        entry.uses[module] = detail
    elseif kind == 'miss' then
        local what = ('%s.%s'):format(tostring(module), tostring(detail))
        if not entry.seen[what] then
            entry.seen[what] = true
            entry.misses[#entry.misses + 1] = what
        end
    elseif kind == 'require' then
        entry.requires = detail
    elseif kind == 'broken' then
        entry.broken[module] = detail
    end
end)

AddEventHandler(SERVER and 'onResourceStop' or 'onClientResourceStop', function(resource)
    usage[resource] = nil
end)

local function sortedKeys(map)
    local keys = {}
    for key in pairs(map) do keys[#keys + 1] = key end
    table.sort(keys)
    return keys
end

local function evidenceOf(module, adapter)
    for _, entry in ipairs(registry.adapters[module] or {}) do
        if entry.name == adapter then return entry.evidence or 'built in' end
    end
    return 'yours'
end

--- "yes: metadata, slots  no: stashes" for the adapter the bridge itself has loaded.
local function capabilities(module)
    local record = internal.records[module]
    if not record then return '' end
    local has = record.api.capabilities()
    local yes, no = {}, {}
    for _, name in ipairs(record.def.caps or {}) do
        if has[name] ~= nil and has[name] ~= false then
            yes[#yes + 1] = has[name] == true and name or ('%s=%s'):format(name, tostring(has[name]))
        else
            no[#no + 1] = name
        end
    end
    local parts = {}
    if #yes > 0 then parts[#parts + 1] = 'yes: ' .. table.concat(yes, ', ') end
    if #no > 0 then parts[#parts + 1] = 'no: ' .. table.concat(no, ', ') end
    return table.concat(parts, '   ')
end

local function report()
    local lines = {}
    local function add(text, ...)
        lines[#lines + 1] = select('#', ...) > 0 and text:format(...) or text
    end
    local notes = internal.resolved and internal.resolved.notes or {}

    add('nexus_bridge %s, %s side', Bridge.version, Bridge.side)
    add('')
    add('%-11s %-20s %-30s %-9s %s', 'module', 'adapter', 'resource', 'evidence', 'capabilities')
    for _, module in ipairs(registry.modules) do
        local entry = internal.state.a[module]
        if type(entry) == 'table' then
            local resource = entry[2]
            local behind = 'needs no resource'
            if resource then
                behind = ('%s %s'):format(resource, GetResourceMetadata(resource, 'version', 0) or '(no version)')
            end
            add('%-11s %-20s %-30s %-9s %s', module, entry[1], behind, evidenceOf(module, entry[1]), capabilities(module))
        elseif entry == 'off' then
            add('%-11s %-20s %s', module, 'off', 'switched off in config.lua')
        else
            add('%-11s %-20s %s', module, 'none', notes[module] or 'no resource the bridge knows for it is running')
        end
    end

    local resources = sortedKeys(usage)
    add('')
    if #resources == 0 then
        add('No other resource has used the bridge on this side yet.')
        return lines
    end
    add('Resources using the bridge:')
    for _, resource in ipairs(resources) do
        local entry = usage[resource]
        local uses = {}
        for _, module in ipairs(sortedKeys(entry.uses)) do
            uses[#uses + 1] = ('%s (%s)'):format(module, entry.uses[module])
        end
        add('  %s %s: %s', resource, GetResourceMetadata(resource, 'version', 0) or '', #uses > 0 and table.concat(uses, ', ') or 'nothing yet')
        if entry.requires then
            local enough = internal.satisfies(Bridge.version, entry.requires)
            add('      requires nexus_bridge %s: %s', entry.requires, enough and 'satisfied' or ('NOT satisfied by ' .. Bridge.version))
        end
        for _, module in ipairs(sortedKeys(entry.broken)) do
            add('      the %s adapter stopped while loading there: %s', module, entry.broken[module])
        end
        if #entry.misses > 0 then
            add('      asked for and did not get: %s', table.concat(entry.misses, ', '))
        end
    end
    return lines
end

exports('Doctor', report)

local function help()
    print('nexus_bridge: doctor (what was detected), selftest (try every adapter), version')
end

local name = SERVER and Config.command or internal.state.s.command
RegisterCommand(type(name) == 'string' and name or 'bridge', function(_, args)
    local action = args[1] or 'doctor'
    if action == 'doctor' then
        for _, line in ipairs(report()) do print(line) end
    elseif action == 'selftest' then
        internal.selftest()
    elseif action == 'version' then
        print(('nexus_bridge %s'):format(Bridge.version))
    else
        help()
    end
end, SERVER)
