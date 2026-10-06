--[[
    Bridge.framework (client): what the local player's character is, the same on every
    framework.

      isLoaded()                       true once a character is in the world
      getIdentifier(), getName()       the character's id and name, or nil
      getJob()                         { name, label, grade, gradeLabel, boss, onDuty }, or nil
      getGang()                        { name, label, grade, gradeLabel, boss }, or nil
      getGroups()                      { [name] = grade } of every job and gang held
      hasGroup(group, minGrade)        group: a name, a list of names, or { name = minGrade }
      getMoney(account)                what the client knows of a balance. For display only:
                                       the server is the one that decides
      getMetadata(key)
      getPlayerData()                  the framework's own player data, for what is not covered
      notify(message, kind, duration)  the framework's own notification

    Only nexus_bridge listens to the framework here. A framework sends the whole player data
    on many changes, and one resource decoding that is enough: every other resource keeps a
    small snapshot (identity, job, groups) and asks the bridge again after a change. Reads of
    the snapshot are plain table reads, cheap enough for a canInteract that runs every frame.
]]

local h = ...

local function signature(job)
    if not job then return '' end
    return ('%s|%s|%s|%s'):format(tostring(job.name), tostring(job.grade), tostring(job.onDuty), tostring(job.boss))
end

local function hasGroup(groups, group, minGrade)
    if type(group) == 'string' then
        local grade = groups[group]
        return grade ~= nil and grade >= (tonumber(minGrade) or 0)
    end
    if type(group) ~= 'table' then return false end
    for key, value in pairs(group) do
        local name, least = key, value
        if type(key) == 'number' then name, least = value, minGrade end
        local grade = groups[name]
        if grade ~= nil and grade >= (tonumber(least) or 0) then return true end
    end
    return false
end

local EMPTY = { loaded = false, groups = {} }

--- The module inside nexus_bridge: it holds the adapter and raises the events.
local function hub(adapter)
    local snapshot = EMPTY
    local last = ''

    local function take()
        if not adapter.isLoaded() then return EMPTY end
        local identity = adapter.identity() or {}
        local job, gang = adapter.job(), adapter.gang and adapter.gang() or nil
        local groups = adapter.groups and adapter.groups() or nil
        if not groups then
            groups = {}
            if job then groups[job.name] = job.grade end
            if gang then groups[gang.name] = gang.grade end
        end
        return { loaded = true, id = identity.id, name = identity.name, job = job, gang = gang, groups = groups }
    end

    --- Called by the adapter whenever the framework said something changed.
    local function changed()
        local before = snapshot
        snapshot = take()
        if snapshot.loaded and not before.loaded then
            last = signature(snapshot.job)
            TriggerEvent('nexus_bridge:playerLoaded')
        elseif before.loaded and not snapshot.loaded then
            last = ''
            TriggerEvent('nexus_bridge:playerUnloaded')
        elseif snapshot.loaded and signature(snapshot.job) ~= last then
            last = signature(snapshot.job)
            TriggerEvent('nexus_bridge:jobChanged', snapshot.job)
        end
        -- For the snapshots the other resources hold.
        TriggerEvent('nexus_bridge:internal:playerChanged')
    end

    adapter.start(changed)
    snapshot = take()
    last = signature(snapshot.job)

    local fw = {}
    function fw.snapshot() return snapshot end
    function fw.isLoaded() return snapshot.loaded end
    function fw.getIdentifier() return snapshot.id end
    function fw.getName() return snapshot.name end
    function fw.getJob() return snapshot.job end
    function fw.getGang() return snapshot.gang end
    function fw.getGroups() return snapshot.groups end
    function fw.hasGroup(group, minGrade) return hasGroup(snapshot.groups, group, minGrade) end

    function fw.getMoney(account)
        if not snapshot.loaded or type(account) ~= 'string' then return 0 end
        return math.floor(tonumber(adapter.money(account)) or 0)
    end

    function fw.getMetadata(key)
        if not snapshot.loaded or not adapter.metadata then return nil end
        return adapter.metadata(key)
    end

    function fw.getPlayerData()
        return snapshot.loaded and adapter.data() or nil
    end

    fw.notify = adapter.notify
    return fw
end

--- The module in every other resource: a snapshot, and the bridge for the rest.
local function consumer(adapter)
    local bridge = exports.nexus_bridge
    local snapshot = nil

    --- Asked of the bridge once and kept until it says something changed. While the bridge
    --- is restarting there is nobody to ask: nothing is kept then, and the next read asks again.
    local function current()
        if snapshot then return snapshot end
        local ok, taken = pcall(bridge.FrameworkSnapshot, bridge)
        if not ok or type(taken) ~= 'table' then return EMPTY end
        snapshot = taken
        return snapshot
    end

    local function ask(export, fallback, ...)
        local ok, answer = pcall(bridge[export], bridge, ...)
        if not ok then return fallback end
        return answer
    end

    h.on('nexus_bridge:internal:playerChanged', function() snapshot = nil end)

    local fw = {}
    function fw.snapshot() return current() end
    function fw.isLoaded() return current().loaded end
    function fw.getIdentifier() return current().id end
    function fw.getName() return current().name end
    function fw.getJob() return current().job end
    function fw.getGang() return current().gang end
    function fw.getGroups() return current().groups end
    function fw.hasGroup(group, minGrade) return hasGroup(current().groups, group, minGrade) end
    function fw.getMoney(account) return ask('FrameworkGetMoney', 0, account) end
    function fw.getMetadata(key) return ask('FrameworkGetMetadata', nil, key) end
    function fw.getPlayerData() return ask('FrameworkGetPlayerData', nil) end
    fw.notify = adapter.notify
    return fw
end

local function nothing() end

return {
    adapters = true,
    caps = { 'duty', 'gangs', 'metadata', 'multiJob' },

    build = function(adapter)
        if adapter and adapter.start then
            return (h.hub and hub or consumer)(adapter)
        end
        -- No framework, or one with nothing on the client: nobody is ever loaded.
        local a = h.complete(adapter, { notify = nothing })
        return {
            snapshot = function() return EMPTY end,
            isLoaded = function() return false end,
            getIdentifier = nothing,
            getName = nothing,
            getJob = nothing,
            getGang = nothing,
            getGroups = function() return {} end,
            hasGroup = function() return false end,
            getMoney = function() return 0 end,
            getMetadata = nothing,
            getPlayerData = nothing,
            notify = a.notify,
        }
    end,

    selftest = function(fw, t)
        if not fw.available then
            t.skip('everything', 'no framework is running')
            return
        end
        t.check('the loaded state is known', type(fw.isLoaded()) == 'boolean', fw.isLoaded())
        if not fw.isLoaded() then
            t.skip('identity, job and groups', 'no character is loaded')
            return
        end
        t.check('the character has an id and a name', type(fw.getIdentifier()) == 'string' and type(fw.getName()) == 'string', fw.getName())
        local job = fw.getJob()
        t.check('the job has a name and a grade', job == nil or (type(job.name) == 'string' and type(job.grade) == 'number'), job and job.name)
        t.check('the groups are a table', type(fw.getGroups()) == 'table')
        t.check('a balance is a whole number', math.type(fw.getMoney('bank')) == 'integer', fw.getMoney('bank'))
    end,
}
