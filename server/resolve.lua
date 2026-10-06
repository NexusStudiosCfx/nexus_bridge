--[[
    Decides which adapter serves each module, and publishes the decision.

    The decision is made here and nowhere else, so every resource on the server and every
    client agrees on it. It is made again whenever a resource the bridge knows starts or stops:
    the order of the `ensure` lines only matters for the framework, which has to be up before
    the resources that need a character.

    exports.nexus_bridge:RegisterAdapter(module, { name, server, client, shared })
    exports.nexus_bridge:UnregisterAdapter(module)
    exports.nexus_bridge:Adapters()
]]

local BRIDGE = GetCurrentResourceName()
local internal = Bridge.internal
local registry = BridgeRegistry

local chosen = {}    -- module -> { adapter, resource or false } | 'off' | nil
local external = {}  -- module -> { name, resource, server, client, shared }
local notes = {}     -- module -> why nothing serves it, for the doctor
local watched = {}   -- resource -> { [module] = true }: whose start or stop changes a decision

local function isRunning(resource)
    local state = GetResourceState(resource)
    return state == 'started' or state == 'starting'
end

local function watch(resource, module)
    watched[resource] = watched[resource] or {}
    watched[resource][module] = true
end

for module, adapters in pairs(registry.adapters) do
    for _, entry in ipairs(adapters) do
        local resources = type(entry.resource) == 'table' and entry.resource or { entry.resource }
        for _, resource in ipairs(resources) do watch(resource, module) end
    end
end

--- The running resource behind a registry entry: its name, `false` for an adapter that needs
--- no resource (the key prompt, the game's own fuel level), or nil when none of them runs.
local function resourceBehind(entry)
    if not entry.resource then return false end
    local resources = type(entry.resource) == 'table' and entry.resource or { entry.resource }
    for _, resource in ipairs(resources) do
        if isRunning(resource) then return resource end
    end
    return nil
end

--- Whether config.lua means this entry. An adapter that serves several resources with one
--- file is also meant by the name of one of them, and then only that resource counts.
local function meant(entry, wanted)
    if wanted == entry.name then return true end
    if type(entry.resource) == 'table' then
        for _, resource in ipairs(entry.resource) do
            if resource == wanted then return true, resource end
        end
    end
    return false
end

--- An entry may say that it only counts in 'auto' once config.lua holds something for it:
--- `configured = 'log.webhooks'` is true when that table has a value that is not empty.
local function isConfigured(entry)
    if not entry.configured then return true end
    local value = Config
    for key in entry.configured:gmatch('[^.]+') do
        value = type(value) == 'table' and value[key] or nil
    end
    if type(value) ~= 'table' then return value ~= nil and value ~= '' and value ~= false end
    for _, item in pairs(value) do
        if item ~= nil and item ~= '' and item ~= false then return true end
    end
    return false
end

local function hasCustomFiles(module)
    local folder = ('bridge/custom/%s/'):format(module)
    return LoadResourceFile(BRIDGE, folder .. 'server.lua') ~= nil
        or LoadResourceFile(BRIDGE, folder .. 'client.lua') ~= nil
        or LoadResourceFile(BRIDGE, folder .. 'shared.lua') ~= nil
end

local function names(module)
    local out = {}
    for _, entry in ipairs(registry.adapters[module]) do out[#out + 1] = entry.name end
    return table.concat(out, ', ')
end

local function resolve(module)
    notes[module] = nil
    local wanted = Config.adapters and Config.adapters[module]
    if wanted == nil then wanted = 'auto' end
    if wanted == false or wanted == 'off' or wanted == 'none' then return 'off' end

    -- An adapter another resource registered wins over detection: somebody asked for it.
    local registered = external[module]
    if registered and (wanted == 'auto' or wanted == registered.name) then
        if isRunning(registered.resource) then return { registered.name, registered.resource } end
    end

    if wanted == 'custom' then
        if hasCustomFiles(module) then return { 'custom', false } end
        notes[module] = ('config.lua asks for "custom", and bridge/custom/%s/ has no server.lua or client.lua'):format(module)
        return nil
    end

    for _, entry in ipairs(registry.adapters[module]) do
        local named, only = false, nil
        if wanted ~= 'auto' then named, only = meant(entry, wanted) end
        local eligible = named or (wanted == 'auto' and entry.auto ~= false and isConfigured(entry))
        if eligible then
            local resource
            if only then resource = isRunning(only) and only or nil else resource = resourceBehind(entry) end
            if resource ~= nil then return { entry.name, resource } end
            if wanted ~= 'auto' then
                notes[module] = ('config.lua asks for %s, which is not running'):format(wanted)
                return nil
            end
        end
    end

    if wanted ~= 'auto' then
        notes[module] = ('config.lua asks for "%s", which is not an adapter of %s (%s, custom)'):format(tostring(wanted), module, names(module))
        return nil
    end

    -- Nothing was found: an entry marked as the fallback serves the module anyway.
    for _, entry in ipairs(registry.adapters[module]) do
        if entry.fallback then
            local resource = resourceBehind(entry)
            if resource ~= nil then return { entry.name, resource } end
        end
    end
    return nil
end

local function same(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= 'table' then return a == b end
    return a[1] == b[1] and a[2] == b[2]
end

local function publish()
    local settings = {}
    for key, value in pairs(Config.settings or {}) do settings[key] = value end
    settings.debug = Config.debug == true
    settings.command = Config.command
    SetConvarReplicated('nexus_bridge_state', json.encode({
        v = Bridge.version,
        a = chosen,
        x = external,
        s = settings,
    }))
end

--- Decides again for `modules` and tells every loader what changed.
local function reconsider(modules)
    local changed = {}
    for module in pairs(modules) do
        if registry.adapters[module] then
            local now = resolve(module)
            if not same(now, chosen[module]) then
                chosen[module] = now
                changed[#changed + 1] = module
            end
        end
    end
    if #changed == 0 then return end
    publish()
    TriggerEvent('nexus_bridge:refresh')
    for _, module in ipairs(changed) do
        TriggerClientEvent('nexus_bridge:refresh', -1, module, chosen[module], external[module])
    end
end

for _, module in ipairs(registry.modules) do
    chosen[module] = resolve(module)
end
publish()
internal.readState()

for module in pairs(Config.adapters or {}) do
    if not registry.adapters[module] then
        print(('[nexus_bridge] config.lua names "%s" under Config.adapters, which is not a module.'):format(tostring(module)))
    end
end

AddEventHandler('onResourceStart', function(resource)
    if resource == BRIDGE or not watched[resource] then return end
    reconsider(watched[resource])
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == BRIDGE then return end
    local affected = watched[resource]
    for module, registered in pairs(external) do
        if registered.resource == resource then
            external[module] = nil
            affected = affected or {}
            affected[module] = true
        end
    end
    if affected then reconsider(affected) end
end)

local function isPath(value)
    return value == nil or (type(value) == 'string' and value:match('%.lua$') ~= nil and not value:find('..', 1, true))
end

--- Lets another resource serve a module with adapter files of its own. The files have the
--- same form as the ones in bridge/ and are read from the calling resource, so the client
--- file must be in that resource's `files`. Call it again every time the resource starts.
exports('RegisterAdapter', function(module, definition)
    local resource = GetInvokingResource()
    if not resource then return false, 'call this from another resource' end
    if not registry.adapters[module] then return false, ('"%s" is not a module with adapters'):format(tostring(module)) end
    if type(definition) ~= 'table' then return false, 'the second argument is a table' end
    if not isPath(definition.server) or not isPath(definition.client) or not isPath(definition.shared) then
        return false, 'server, client and shared are paths of .lua files inside your resource'
    end
    if not definition.server and not definition.client and not definition.shared then
        return false, 'give at least one of server, client, shared'
    end
    local name = type(definition.name) == 'string' and definition.name or resource
    if not name:match('^[%w_%-]+$') then return false, 'the name may hold letters, digits, _ and -' end

    external[module] = {
        name = name,
        resource = resource,
        server = definition.server,
        client = definition.client,
        shared = definition.shared,
    }
    watch(resource, module)
    reconsider({ [module] = true })
    return true
end)

exports('UnregisterAdapter', function(module)
    local resource = GetInvokingResource()
    local registered = external[module]
    if not registered or registered.resource ~= resource then return false end
    external[module] = nil
    reconsider({ [module] = true })
    return true
end)

--- { framework = 'qbx_core', dispatch = false, ... }: the adapter of each module, false when
--- nothing serves it.
exports('Adapters', function()
    local out = {}
    for _, module in ipairs(registry.modules) do
        local entry = chosen[module]
        out[module] = type(entry) == 'table' and entry[1] or false
    end
    return out
end)

internal.resolved = { chosen = chosen, external = external, notes = notes }
