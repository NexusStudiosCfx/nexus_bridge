--[[
    The nexus_bridge loader.

    A resource adds this line to its fxmanifest.lua:

        shared_script '@nexus_bridge/init.lua'

    and gets one global, `Bridge`. Every key of it is a module (Bridge.framework,
    Bridge.inventory, Bridge.target, ...) that is read from the bridge and compiled into the
    calling resource's own Lua state the first time it is used. After that a call is a plain
    Lua function call: nothing crosses a resource boundary except the calls an adapter makes
    into the resource it wraps.

    Which adapter serves a module is decided once, by the nexus_bridge resource itself, and
    published in the replicated convar `nexus_bridge_state`. The loader only reads it.
]]

local BRIDGE = 'nexus_bridge'
local RESOURCE = GetCurrentResourceName()
local SERVER = IsDuplicityVersion()
local SIDE = SERVER and 'server' or 'client'
local HUB = RESOURCE == BRIDGE

-- Checked on the server only. A client starts what the server started, in its own time, and
-- a module that needs the bridge's client half before it is up is built again when it is.
if not HUB and SERVER then
    local running = GetResourceState(BRIDGE)
    if running ~= 'started' and running ~= 'starting' then
        error(('%s needs nexus_bridge, which is %s. Put "ensure nexus_bridge" above "ensure %s" in server.cfg.')
            :format(RESOURCE, running, RESOURCE), 0)
    end
end

local VERSION = GetResourceMetadata(BRIDGE, 'version', 0) or '0.0.0'
local EVENT = BRIDGE .. ':'

local function parseVersion(text)
    local major, minor, patch = tostring(text):match('^%s*v?(%d+)%.?(%d*)%.?(%d*)')
    if not major then return nil end
    return { tonumber(major), tonumber(minor) or 0, tonumber(patch) or 0 }
end

local function compareVersions(a, b)
    for i = 1, 3 do
        if a[i] ~= b[i] then return a[i] < b[i] and -1 or 1 end
    end
    return 0
end

--- True when `version` is inside `range`. A range is one or more conditions separated by
--- spaces that must all hold: '>=1.2', '>1.2 <2', '~1.2.3' (same minor), '^1.2' (same major).
--- A bare version means the same as a caret.
local function satisfies(version, range)
    local have = parseVersion(version)
    if not have then return false end
    local conditions = 0
    for condition in tostring(range):gmatch('%S+') do
        conditions = conditions + 1
        local operator, rest = condition:match('^([%^~<>=]*)(.+)$')
        local want = parseVersion(rest)
        if not want then return false end
        local order = compareVersions(have, want)
        local ok
        if operator == '>=' then ok = order >= 0
        elseif operator == '>' then ok = order > 0
        elseif operator == '<=' then ok = order <= 0
        elseif operator == '<' then ok = order < 0
        elseif operator == '=' or operator == '==' then ok = order == 0
        elseif operator == '~' then ok = order >= 0 and have[1] == want[1] and have[2] == want[2]
        elseif operator == '^' or operator == '' then
            -- Before 1.0 a minor release may break, so the caret pins the minor there.
            ok = order >= 0 and have[1] == want[1] and (want[1] > 0 or have[2] == want[2])
        else
            return false
        end
        if not ok then return false end
    end
    return conditions > 0
end

-- a[module] = { adapter, resource } | 'off' | nil      which adapter serves a module
-- x[module] = { resource, server, client, shared }      an adapter registered by another resource
-- s                                                    settings the modules read (never secrets)
local state = { a = {}, x = {}, s = {} }

local function readState()
    local raw = GetConvar('nexus_bridge_state', '')
    if raw == '' then return false end
    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then return false end
    state.a = type(decoded.a) == 'table' and decoded.a or {}
    state.x = type(decoded.x) == 'table' and decoded.x or {}
    state.s = type(decoded.s) == 'table' and decoded.s or {}
    return true
end

local stateRead = readState()

local function say(message)
    print(('[nexus_bridge] %s'):format(message))
end

local function debug(message)
    if state.s.debug then print(('[nexus_bridge] (%s, %s) %s'):format(RESOURCE, SIDE, message)) end
end

--- Tells the bridge resource what this resource uses and what it asked for in vain, so the
--- doctor can print it. A local event: it never leaves this machine.
local function report(kind, module, detail)
    TriggerEvent(EVENT .. 'internal:usage', RESOURCE, kind, module, detail)
end

local function readChunk(resource, path)
    local source = LoadResourceFile(resource, path)
    if not source or source == '' then return nil end
    -- The environment is passed on so the file sees the globals of the resource that loads it.
    local chunk, problem = load(source, ('@@%s/%s'):format(resource, path), 't', _ENV)
    if not chunk then
        error(('could not compile %s/%s: %s'):format(resource, path, tostring(problem)), 0)
    end
    return chunk
end

--- Runs `<folder>/shared.lua` (when there is one) and `<folder>/<side>.lua`. The side file
--- receives the helper and what the shared file returned.
local function runFolder(resource, folder, helper)
    local sharedChunk = readChunk(resource, folder .. '/shared.lua')
    local sideChunk = readChunk(resource, ('%s/%s.lua'):format(folder, SIDE))
    if not sharedChunk and not sideChunk then return nil end
    local shared = sharedChunk and sharedChunk(helper) or nil
    if not sideChunk then return shared end
    return sideChunk(helper, shared)
end

local Bridge = {
    name = BRIDGE,
    version = VERSION,
    resource = RESOURCE,
    side = SIDE,
}

-- records[name] = { name, api, def, helper, store, cleanups, told, adapter, adapterResource,
-- reason } for a module that exists, false for a name that is not a module.
local records = {}

local function runCleanups(record)
    local cleanups = record.cleanups
    record.cleanups = {}
    for i = #cleanups, 1, -1 do
        local ok, problem = pcall(cleanups[i])
        if not ok then debug(('%s: cleanup stopped: %s'):format(record.name, tostring(problem))) end
    end
end

--- What a module and its adapter receive as their first argument.
local function newHelper(record)
    -- `bridge` is handed over because a resource may keep its own global called Bridge.
    local h = { bridge = Bridge, module = record.name, store = record.store, resource = RESOURCE, side = SIDE, hub = HUB }

    function h.say(message) say(('%s: %s'):format(record.name, message)) end
    function h.debug(message) debug(('%s: %s'):format(record.name, message)) end

    --- Prints `message` only the first time `key` is seen since the module was built.
    function h.once(key, message)
        if record.told[key] then return end
        record.told[key] = true
        h.say(message)
    end

    --- The settings the bridge's config holds for this module, or for the one named.
    function h.settings(module)
        local settings = state.s[module or record.name]
        return type(settings) == 'table' and settings or {}
    end

    --- The language server owners chose for the bridge's own texts.
    function h.language()
        return type(state.s.locale) == 'string' and state.s.locale or 'en'
    end

    --- `fn` runs when the module is rebuilt (its adapter changed or restarted) and when this
    --- resource stops.
    function h.cleanup(fn)
        record.cleanups[#record.cleanups + 1] = fn
    end

    --- AddEventHandler that does not outlive the adapter that asked for it.
    function h.on(event, handler)
        local ref = AddEventHandler(event, handler)
        h.cleanup(function() RemoveEventHandler(ref) end)
        return ref
    end

    --- h.on for an event that the other side of the network sends.
    function h.onNet(event, handler)
        RegisterNetEvent(event)
        return h.on(event, handler)
    end

    --- The resource a registration belongs to: the caller of an export, or this resource.
    function h.owner()
        return GetInvokingResource() or RESOURCE
    end

    --- Tells the doctor that this resource wanted something the bridge could not give.
    function h.miss(what)
        report('miss', record.name, what)
    end

    --- A stand-in for a function nobody provides: it says so once, then answers with what
    --- `fallback` returns, so the caller gets a harmless value instead of a nil error.
    function h.unavailable(fn, fallback)
        return function(...)
            if not record.told[fn] then
                record.told[fn] = true
                local why
                if record.adapter then
                    why = ('the %s adapter has no %s on the %s'):format(record.adapter, fn, SIDE)
                elseif record.reason == 'off' then
                    why = ('%s is switched off in the config of nexus_bridge'):format(record.name)
                elseif record.reason == 'broken' then
                    why = 'its adapter did not load (see above)'
                elseif record.reason == 'starting' then
                    why = ('%s has not started on this client yet'):format(tostring(record.waiting))
                else
                    why = ('no %s resource that nexus_bridge knows is running'):format(record.name)
                end
                say(('Bridge.%s.%s was called by %s and does nothing: %s.'):format(record.name, fn, RESOURCE, why))
                report('miss', record.name, fn)
            end
            return fallback(...)
        end
    end

    --- The adapter with every function of `fallbacks` it lacks filled in by a stand-in.
    function h.complete(adapter, fallbacks)
        local out = {}
        for key, value in pairs(fallbacks) do
            local own = adapter and adapter[key]
            if own ~= nil then
                out[key] = own
            elseif type(value) == 'function' then
                out[key] = h.unavailable(key, value)
            else
                out[key] = value
            end
        end
        if adapter then
            for key, value in pairs(adapter) do
                if out[key] == nil then out[key] = value end
            end
        end
        return out
    end

    return h
end

local function loadAdapter(record, name)
    local h = record.helper
    local external = state.x[record.name]
    if type(external) == 'table' and external.name == name then
        -- An adapter another resource registered: the files are in that resource.
        local sharedChunk = external.shared and readChunk(external.resource, external.shared) or nil
        local sideChunk = external[SIDE] and readChunk(external.resource, external[SIDE]) or nil
        local shared = sharedChunk and sharedChunk(h) or nil
        if not sideChunk then return shared end
        return sideChunk(h, shared)
    end
    if name == 'custom' then
        return runFolder(BRIDGE, 'bridge/custom/' .. record.name, h)
    end
    return runFolder(BRIDGE, ('bridge/%s/%s'):format(record.name, name), h)
end

--- Builds the module (again) and puts the result into the table the resource already holds,
--- so `local Inventory = Bridge.inventory` stays valid when the adapter behind it changes.
local function instantiate(record)
    if not stateRead then stateRead = readState() end
    runCleanups(record)
    record.told = {}
    record.adapter, record.adapterResource, record.reason, record.waiting = nil, nil, nil, nil

    local def, h = record.def, record.helper
    local adapter = nil
    if def.adapters then
        local entry = state.a[record.name]
        local behind = type(entry) == 'table' and entry[2] or nil
        local running = behind and not SERVER and GetResourceState(behind) or 'started'
        if behind and running ~= 'started' and running ~= 'missing' then
            -- The server chose it, and its client half has not started here yet. Building now
            -- would call exports that do not exist: the module is built when it starts.
            record.waiting, record.reason = behind, 'starting'
        elseif type(entry) == 'table' and type(entry[1]) == 'string' then
            record.adapter, record.adapterResource = entry[1], entry[2] or nil
            h.adapter, h.adapterResource = record.adapter, record.adapterResource
            local ok, result = pcall(loadAdapter, record, entry[1])
            if ok then
                -- An adapter may have nothing to do on one side: it still counts as chosen.
                adapter = type(result) == 'table' and result or {}
            else
                say(('%s: the %s adapter stopped while loading in %s (%s): %s')
                    :format(record.name, entry[1], RESOURCE, SIDE, tostring(result)))
                report('broken', record.name, tostring(result))
                record.adapter, record.adapterResource, record.reason = nil, nil, 'broken'
            end
        else
            record.reason = entry == 'off' and 'off' or 'none'
        end
        if not adapter then h.adapter, h.adapterResource = nil, nil end
    end

    local api, caps = def.build(adapter, h)
    caps = caps or (adapter and adapter.caps) or {}

    local stable = record.api
    for key in pairs(stable) do stable[key] = nil end
    for key, value in pairs(api) do stable[key] = value end

    stable.name = record.adapter or (def.adapters and 'none' or record.name)
    stable.resource = record.adapterResource or false
    stable.available = adapter ~= nil or not def.adapters

    function stable.supports(feature)
        local value = caps[feature]
        return value ~= nil and value ~= false
    end

    function stable.capabilities()
        local out = {}
        for key, value in pairs(caps) do out[key] = value end
        return out
    end

    report('use', record.name, stable.name)
end

local function open(name)
    if type(name) ~= 'string' or not name:match('^%a[%w_]*$') or name == 'custom' then return false end
    local record = { name = name, api = {}, store = {}, cleanups = {}, told = {} }
    record.helper = newHelper(record)
    local def = runFolder(BRIDGE, 'bridge/' .. name, record.helper)
    if type(def) ~= 'table' or type(def.build) ~= 'function' then return false end
    record.def = def
    -- Registered before it is built, so two modules that use each other do not recurse.
    records[name] = record
    instantiate(record)
    return record
end

local function find(name)
    if name == nil then return false end
    local record = records[name]
    if record == nil then
        record = open(name)
        if not record then records[name] = false end
    end
    return record
end

setmetatable(Bridge, {
    __index = function(self, key)
        local record = find(key)
        if not record then
            error(('nexus_bridge %s has no module "%s" on the %s'):format(VERSION, tostring(key), SIDE), 2)
        end
        rawset(self, key, record.api)
        return record.api
    end,
})

--- Rebuilds every loaded module for which `changed(record)` is true. The list is taken first:
--- building a module may load another one, and a table must not grow while it is walked.
local function rebuild(changed)
    local due = {}
    for _, record in pairs(records) do
        if record and changed(record) then due[#due + 1] = record end
    end
    for i = 1, #due do instantiate(due[i]) end
end

--- What the bridge wants for a module and what a loaded module was built with, as text that
--- can be compared. The resource is part of it: one adapter may serve several resources.
local function chosen(module)
    local entry = state.a[module]
    if type(entry) == 'table' then return ('%s@%s'):format(tostring(entry[1]), tostring(entry[2] or '')) end
    return entry == 'off' and 'off' or nil
end

local function following(record)
    if record.adapter then return ('%s@%s'):format(record.adapter, tostring(record.adapterResource or '')) end
    return record.reason == 'off' and 'off' or nil
end

if SERVER then
    -- Not a net event: only code on the server can raise it.
    AddEventHandler(EVENT .. 'refresh', function()
        readState()
        rebuild(function(record)
            return record.def.adapters and following(record) ~= chosen(record.name)
        end)
    end)
else
    -- The server sends the new choice along, because the convar that carries it for players
    -- who join later may reach this client after the event does.
    RegisterNetEvent(EVENT .. 'refresh', function(module, entry, external)
        if type(module) ~= 'string' then return end
        state.a[module] = entry
        state.x[module] = external
        rebuild(function(record)
            return record.name == module and record.def.adapters and following(record) ~= chosen(module)
        end)
    end)
end

if not SERVER then
    -- A module that was waiting for the client half of its resource is built now. One that
    -- was already built is built again: the server's word can arrive while the old instance
    -- still runs here, and what was registered with that instance is gone with it. On the
    -- server the bridge sees the stop and the start itself, and says so through `refresh`.
    AddEventHandler('onClientResourceStart', function(started)
        rebuild(function(record) return record.waiting == started or record.adapterResource == started end)
    end)
end

AddEventHandler(SERVER and 'onResourceStop' or 'onClientResourceStop', function(stopped)
    if stopped ~= RESOURCE then return end
    for _, record in pairs(records) do
        if record then
            -- A cleanup can tell the end of the resource from a module being built again.
            if record.helper then record.helper.stopping = true end
            runCleanups(record)
        end
    end
end)

local required = nil

if not HUB then
    --[[
        The bridge itself restarted (an update, or a server owner's `restart nexus_bridge`).

        A resource that uses the bridge does not declare it as a dependency: FXServer stops
        the dependents of a resource that restarts and does not start them again. Instead the
        resource keeps running on the modules it has in its own Lua state, and when the bridge
        is back it reads the bridge's decisions again and builds its modules again. That puts
        back what it had registered inside the bridge (key prompts) and tells the bridge's
        doctor what it uses.
    ]]
    AddEventHandler(SERVER and 'onResourceStart' or 'onClientResourceStart', function(started)
        if started ~= BRIDGE then return end
        readState()
        if required then report('require', 'bridge', required) end
        rebuild(function() return true end)
    end)
end

--- Stops the calling resource with a clear message when the installed bridge is older than it
--- needs: Bridge.require('>=1.2').
function Bridge.require(range)
    required = tostring(range)
    report('require', 'bridge', required)
    if satisfies(VERSION, range) then return true end
    error(('%s needs nexus_bridge %s and %s is installed. Update it: https://github.com/NexusStudiosCfx/nexus_bridge/releases')
        :format(RESOURCE, tostring(range), VERSION), 2)
end

--- The name of the adapter chosen for a module, or nil. Does not load the module.
function Bridge.adapter(module)
    if not stateRead then stateRead = readState() end
    local entry = state.a[module]
    return type(entry) == 'table' and entry[1] or nil
end

--- True when the module exists on this side and something serves it.
function Bridge.has(module)
    local record = find(module)
    return record ~= false and record.api.available == true
end

--- Bridge.supports('inventory', 'metadata') or Bridge.supports('inventory.metadata').
function Bridge.supports(module, feature)
    if feature == nil then
        module, feature = tostring(module):match('^([^.]+)%.(.+)$')
    end
    if not module or not Bridge.has(module) then return false end
    return records[module].api.supports(feature)
end

local EVENTS = {
    playerLoaded = true,
    playerUnloaded = true,
    jobChanged = true,
    moneyChanged = true,
    itemUsed = true,
    playerDied = true,
    playerRevived = true,
}

--- Listens to one of the bridge's events. They are the same on every framework; docs/events.md
--- lists what each one carries. With { replay = true }, a playerLoaded handler also runs for
--- the characters that were loaded before this resource started.
function Bridge.on(event, handler, options)
    if not EVENTS[event] then
        error(('nexus_bridge has no event "%s"'):format(tostring(event)), 2)
    end
    local ref = AddEventHandler(EVENT .. event, handler)
    if event == 'playerLoaded' and type(options) == 'table' and options.replay then
        CreateThread(function()
            local framework = Bridge.framework
            if SERVER then
                for _, src in ipairs(framework.getPlayers()) do
                    handler(src, framework.getIdentifier(src))
                end
            elseif framework.isLoaded() then
                handler()
            end
        end)
    end
    return ref
end

function Bridge.off(ref)
    if ref then RemoveEventHandler(ref) end
end

if HUB then
    -- What the bridge's own scripts need of the loader. Other resources never see this.
    rawset(Bridge, 'internal', {
        state = state,
        records = records,
        events = EVENTS,
        find = find,
        readState = readState,
        satisfies = satisfies,
        parseVersion = parseVersion,
        compareVersions = compareVersions,
    })
end

-- A resource that already has a global called Bridge keeps it and uses NexusBridge.
if rawget(_ENV, 'Bridge') == nil then _ENV.Bridge = Bridge end
_ENV.NexusBridge = Bridge
