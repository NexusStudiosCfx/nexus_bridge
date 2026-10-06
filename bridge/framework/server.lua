--[[
    Bridge.framework (server): characters, their money and their jobs, the same on every
    framework.

    Who is this
      getIdentifier(src)                 the character's id (citizenid, identifier), or nil
      getIdentity(src)                   { id, name, firstName, lastName }, or nil
      getName(src)                       the character's name, or the player's name without one
      getSource(id)                      the player id of a character that is online, or nil
      getPlayers()                       the player ids of every loaded character
      isLoaded(src)
      getCharacterName(id)               name of any character, online or not, or nil

    Money, in whole dollars. `account` is 'cash', 'bank' or another account the framework has.
      getMoney(src, account)             0 when there is no such player or account
      addMoney(src, account, amount, reason)       true if the money arrived
      removeMoney(src, account, amount, reason)    true only if `amount` really left the account;
                                                   never takes a part and never goes below zero
      getMoneyById(id, account)          like getMoney, for a character id; nil when unknown
      addMoneyById(id, account, amount, reason)
      removeMoneyById(id, account, amount, reason)
          The ById functions reach a character that is online, and one that is offline where
          the framework can: supports('offlineMoney').

    Jobs
      getJob(src)                        { name, label, grade, gradeLabel, boss, onDuty }, or nil
      getGang(src)                       { name, label, grade, gradeLabel, boss }, or nil
      getGroups(src)                     { [name] = grade } of every job and gang held
      hasGroup(src, group, minGrade)     group: a name, a list of names, or { name = minGrade }
      getEmployment(src, job)            { grade, boss, onDuty, primary }, or nil without that job
      getOnDuty(job)                     the player ids on duty in a job
      jobExists(job, grade), getJobLabel(job), listJobs(), getGrades(job)
          listJobs: { { name, label } } by name. getGrades: { { grade, name, pay, boss } }, lowest first.

    Managing jobs: supports('jobs') and supports('grades'). Each answers true, or false and
    the reason in one word: 'job_missing', 'grade_missing', 'no_character', 'in_use',
    'last_grade', 'not_supported', 'refused', 'unavailable'.
      setJob(id, job, grade, options)    hires a character or changes their grade. `id` is a
                                         character id, online or not. On a framework with
                                         several jobs for one character, options.add = true
                                         adds the job next to the ones they have
      removeJob(id, job)                 true when the character no longer has the job
      setDuty(src, onDuty, job)          true if the framework now says so. With `job`, only
                                         for that job (and it becomes the active one where a
                                         character has several)
      listEmployees(job)                 { { id, name, grade, online } }, highest grade first
      setGrade(job, grade, data)         changes a grade, or makes it: data = { name, pay, boss }
      removeGrade(job, grade)            never one that somebody holds, never the last one
          supports('gradeBoss'): the boss flag of a grade can be changed.
          supports('gradesPersist'): a changed grade is still there after a restart. Where it
          is not, the resource that changed it applies it again when it starts.

    The rest
      getMetadata(src, key), setMetadata(src, key, value)     supports('metadata')
      registerUsable(item, function(src, item) end)           the framework's usable items
      notify(src, message, kind, duration)                    the framework's own notification
      getPlayer(src), core()             the framework's own objects, for what is not covered

    A framework without duty counts everybody as on duty: supports('duty') tells them apart.
    docs/api.md has every function with its edge cases; docs/capabilities.md the capabilities.
]]

local h = ...

local function none() return nil end
local function no() return false end
local function empty() return {} end

-- What the module answers when no framework runs, or the adapter lacks a function.
local fallbacks = {
    getPlayer = none,
    core = none,
    getIdentity = none,
    getSource = none,
    getPlayers = empty,
    getCharacterName = none,

    getMoney = function() return 0 end,
    addMoney = no,
    removeMoney = no,
    getMoneyById = none,
    addMoneyById = no,
    removeMoneyById = no,

    getJob = none,
    getGang = none,
    getOnDuty = empty,
    jobExists = no,
    getJobLabel = none,
    listJobs = empty,
    getGrades = empty,

    getMetadata = none,
    setMetadata = no,
    registerUsable = no,

    -- Without a framework a message still reaches the player, in the chat.
    notify = function(src, message)
        TriggerClientEvent('chat:addMessage', src, { args = { tostring(message) } })
    end,
}

--- A positive whole amount, or nil. Frameworks disagree on what a bad amount does (one
--- raises, one returns nothing), so it never reaches them.
local function whole(amount)
    amount = tonumber(amount)
    if not amount or amount ~= amount or amount == math.huge then return nil end
    amount = math.floor(amount)
    return amount > 0 and amount or nil
end

local function signature(job)
    if not job then return '' end
    return ('%s|%s|%s|%s'):format(tostring(job.name), tostring(job.grade), tostring(job.onDuty), tostring(job.boss))
end

--- Raises the bridge's events from what the adapter hears. Runs in nexus_bridge only: every
--- other resource listens to the bridge, not to the framework.
local function listen(adapter, fw)
    local loaded, jobs = {}, {}

    -- The characters that were loaded before the bridge (re)started.
    for _, src in ipairs(fw.getPlayers()) do
        loaded[src] = fw.getIdentifier(src)
        jobs[src] = signature(fw.getJob(src))
    end

    local emit = {}

    function emit.loaded(src)
        src = tonumber(src)
        if not src or loaded[src] then return end
        local id = fw.getIdentifier(src)
        if not id then return end
        loaded[src] = id
        jobs[src] = signature(fw.getJob(src))
        TriggerEvent('nexus_bridge:playerLoaded', src, id)
    end

    function emit.unloaded(src)
        src = tonumber(src)
        local id = src and loaded[src]
        if not id then return end
        loaded[src], jobs[src] = nil, nil
        TriggerEvent('nexus_bridge:playerUnloaded', src, id)
    end

    --- Frameworks announce a job more often than it changes (at login, on a refresh of the
    --- job list), so the event only goes out when name, grade, duty or boss differ.
    function emit.job(src)
        src = tonumber(src)
        if not src or not loaded[src] then return end
        local job = fw.getJob(src)
        local now = signature(job)
        if jobs[src] == now then return end
        jobs[src] = now
        TriggerEvent('nexus_bridge:jobChanged', src, job)
    end

    function emit.money(src, account, amount, action, reason)
        src = tonumber(src)
        if not src or type(account) ~= 'string' then return end
        TriggerEvent('nexus_bridge:moneyChanged', src, account, math.floor(tonumber(amount) or 0), action, reason)
    end

    adapter.listen(emit)

    -- Not every framework says when a player who simply leaves is gone.
    h.on('playerDropped', function()
        emit.unloaded(source)
    end)
end

return {
    adapters = true,
    caps = {
        'offlineMoney', 'multiJob', 'duty', 'gangs', 'metadata', 'usableItems', 'moneyEvents',
        'jobs', 'grades', 'gradeBoss', 'gradesPersist',
    },

    build = function(adapter)
        local a = h.complete(adapter, fallbacks)
        local fw = {
            getPlayer = a.getPlayer,
            core = a.core,
            getIdentity = a.getIdentity,
            getSource = a.getSource,
            getPlayers = a.getPlayers,
            getCharacterName = a.getCharacterName,
            getMoney = a.getMoney,
            getJob = a.getJob,
            getGang = a.getGang,
            jobExists = a.jobExists,
            getJobLabel = a.getJobLabel,
            listJobs = a.listJobs,
            getGrades = a.getGrades,
            getMetadata = a.getMetadata,
            setMetadata = a.setMetadata,
            registerUsable = a.registerUsable,
            notify = a.notify,
        }

        function fw.getIdentifier(src)
            local identity = a.getIdentity(src)
            return identity and identity.id or nil
        end

        function fw.getName(src)
            local identity = a.getIdentity(src)
            return identity and identity.name or GetPlayerName(src)
        end

        function fw.isLoaded(src)
            return a.getIdentity(src) ~= nil
        end

        function fw.addMoney(src, account, amount, reason)
            amount = whole(amount)
            if not amount or type(account) ~= 'string' then return false end
            return a.addMoney(src, account, amount, reason) == true
        end

        function fw.removeMoney(src, account, amount, reason)
            amount = whole(amount)
            if not amount or type(account) ~= 'string' then return false end
            return a.removeMoney(src, account, amount, reason) == true
        end

        function fw.getMoneyById(id, account)
            if type(id) ~= 'string' or type(account) ~= 'string' then return nil end
            local src = a.getSource(id)
            if src then return a.getMoney(src, account) end
            return a.getMoneyById(id, account)
        end

        --[[
            Money for a character that is offline.

            Frameworks do this as "load the row, change it, save it", and the save is not waited
            for: the call answers true while the write is still on its way. Two changes to the
            same character in the same moment would both start from the old balance, and one
            would be lost. So every such change is made here, in nexus_bridge, one at a time
            per character, and answers once the database shows the new balance.
        ]]
        local busy = {}

        local function offline(change, id, account, amount, reason)
            while busy[id] do Wait(0) end
            busy[id] = true
            local ok, done = pcall(function()
                local before = a.getMoneyById(id, account)
                if not before then return false end
                if change == 'remove' and before < amount then return false end
                local write = change == 'add' and a.addMoneyById or a.removeMoneyById
                if write(id, account, amount, reason) ~= true then return false end

                local expected = change == 'add' and before + amount or before - amount
                local deadline = GetGameTimer() + 5000
                while a.getMoneyById(id, account) ~= expected do
                    if GetGameTimer() > deadline then
                        -- The framework took it. Saying false now would make the caller pay twice.
                        h.say(('the %s of %d to %s of character %s was accepted by the framework and is not in the database after 5 seconds'):format(change, amount, account, id))
                        break
                    end
                    Wait(50)
                end
                return true
            end)
            busy[id] = nil
            if not ok then h.say(('money for the offline character %s stopped: %s'):format(id, tostring(done))) end
            return ok and done == true
        end

        local function byId(change)
            local online = change == 'add' and a.addMoney or a.removeMoney
            local export = change == 'add' and 'FrameworkAddMoneyById' or 'FrameworkRemoveMoneyById'
            return function(id, account, amount, reason)
                amount = whole(amount)
                if not amount or type(account) ~= 'string' or type(id) ~= 'string' then return false end
                local src = a.getSource(id)
                if src then return online(src, account, amount, reason) == true end
                if not adapter or not adapter.addMoneyById then
                    -- The stand-in says once that this framework cannot do it.
                    return a.addMoneyById(id, account, amount, reason) == true
                end
                if h.hub then return offline(change, id, account, amount, reason) end
                -- False while the bridge is restarting: nothing was changed, the caller may try again.
                local bridge = exports.nexus_bridge
                local ok, done = pcall(bridge[export], bridge, id, account, amount, reason)
                return ok and done == true
            end
        end

        fw.addMoneyById = byId('add')
        fw.removeMoneyById = byId('remove')

        fw.getGroups = adapter and adapter.getGroups or function(src)
            local groups = {}
            local job, gang = a.getJob(src), a.getGang(src)
            if job then groups[job.name] = job.grade end
            if gang then groups[gang.name] = gang.grade end
            return groups
        end

        function fw.hasGroup(src, group, minGrade)
            local groups = fw.getGroups(src)
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

        fw.getEmployment = adapter and adapter.getEmployment or function(src, jobName)
            local job = a.getJob(src)
            if not job or job.name ~= jobName then return nil end
            return { grade = job.grade, boss = job.boss, onDuty = job.onDuty, primary = true }
        end

        fw.getOnDuty = adapter and adapter.getOnDuty or function(jobName)
            local out = {}
            for _, src in ipairs(a.getPlayers()) do
                local job = a.getJob(src)
                if job and job.name == jobName and job.onDuty then out[#out + 1] = src end
            end
            return out
        end

        --- Calls one of the adapter's job functions: true, or false and a reason.
        local function managed(fn, ...)
            if not adapter then return false, 'unavailable' end
            if not fn then return false, 'not_supported' end
            local ok, done, reason = pcall(fn, ...)
            if not ok then
                h.once('jobs', ('the %s adapter could not change a job: %s'):format(tostring(h.adapter), tostring(done)))
                return false, 'refused'
            end
            if done == true then return true end
            return false, type(reason) == 'string' and reason or 'refused'
        end

        local function checked(jobName, grade)
            if type(jobName) ~= 'string' or jobName == '' or not fw.jobExists(jobName) then return 'job_missing' end
            if grade ~= nil and not fw.jobExists(jobName, grade) then return 'grade_missing' end
            return nil
        end

        function fw.setJob(id, jobName, grade, options)
            if type(id) ~= 'string' or id == '' then return false, 'no_character' end
            grade = math.floor(tonumber(grade) or 0)
            local problem = checked(jobName, grade)
            if problem then return false, problem end
            return managed(adapter and adapter.setJob, id, jobName, grade, type(options) == 'table' and options.add == true)
        end

        function fw.removeJob(id, jobName)
            if type(id) ~= 'string' or id == '' then return false, 'no_character' end
            local problem = checked(jobName)
            if problem then return false, problem end
            return managed(adapter and adapter.removeJob, id, jobName)
        end

        function fw.setDuty(src, onDuty, jobName)
            src = tonumber(src)
            if not src or not adapter or not adapter.setDuty then return false end
            local ok, done = pcall(adapter.setDuty, src, onDuty == true, type(jobName) == 'string' and jobName or nil)
            return ok and done == true
        end

        function fw.listEmployees(jobName)
            if type(jobName) ~= 'string' or not adapter or not adapter.listEmployees then return {} end
            local ok, list = pcall(adapter.listEmployees, jobName)
            if not ok or type(list) ~= 'table' then return {} end
            table.sort(list, function(a, b)
                if a.grade ~= b.grade then return a.grade > b.grade end
                return tostring(a.name or a.id) < tostring(b.name or b.id)
            end)
            return list
        end

        function fw.setGrade(jobName, grade, data)
            grade = tonumber(grade)
            if not grade or grade < 0 or type(data) ~= 'table' then return false, 'grade_missing' end
            local problem = checked(jobName)
            if problem then return false, problem end
            local name = type(data.name) == 'string' and data.name ~= '' and data.name:sub(1, 50) or nil
            local pay = data.pay ~= nil and math.max(0, math.floor(tonumber(data.pay) or 0)) or nil
            local boss = nil
            if data.boss ~= nil then boss = data.boss == true end
            return managed(adapter and adapter.setGrade, jobName, math.floor(grade), { name = name, pay = pay, boss = boss })
        end

        function fw.removeGrade(jobName, grade)
            grade = tonumber(grade)
            local problem = checked(jobName, grade)
            if problem then return false, problem end
            if not adapter or not adapter.removeGrade then return false, adapter and 'not_supported' or 'unavailable' end
            if #fw.getGrades(jobName) <= 1 then return false, 'last_grade' end
            for _, employee in ipairs(fw.listEmployees(jobName)) do
                if employee.grade == grade then return false, 'in_use' end
            end
            return managed(adapter.removeGrade, jobName, math.floor(grade))
        end

        if h.hub and adapter and adapter.listen then listen(adapter, fw) end

        return fw
    end,

    selftest = function(fw, t)
        if not fw.available then
            t.skip('everything', 'no framework is running')
            return
        end
        local nobody, nowhere = 65534, 'nexus_bridge_nobody'
        t.check('a player that is not there has no identity', fw.getIdentity(nobody) == nil)
        t.check('and no money', fw.getMoney(nobody, 'bank') == 0)
        t.check('money cannot be taken from them', fw.removeMoney(nobody, 'bank', 1, 'selftest') == false)
        t.check('or given to them', fw.addMoney(nobody, 'bank', 1, 'selftest') == false)
        t.check('an unknown character has no balance', fw.getMoneyById(nowhere, 'bank') == nil)
        t.check('and cannot be paid', fw.addMoneyById(nowhere, 'bank', 1, 'selftest') == false)
        t.check('and has no name', fw.getCharacterName(nowhere) == nil)
        t.check('a bad amount is refused', fw.addMoney(nobody, 'bank', -5) == false and fw.removeMoney(nobody, 'bank', 'x') == false)

        local jobs = fw.listJobs()
        t.check('the job list is read', type(jobs) == 'table' and #jobs > 0, #jobs .. ' jobs')
        local first = jobs[1]
        if first then
            local grades = fw.getGrades(first.name)
            t.check('a job has grades', type(grades) == 'table' and #grades > 0, ('%s: %d grades'):format(first.name, #grades))
            t.check('a job that exists is known', fw.jobExists(first.name) == true and fw.getJobLabel(first.name) ~= nil)
        end
        t.check('a job that does not exist is not', fw.jobExists('nexus_bridge_no_such_job') == false)

        local players = fw.getPlayers()
        t.check('the loaded characters are listed', type(players) == 'table', #players .. ' online')
        local src = players[1]
        if not src then
            t.skip('identity, money and job of a character', 'nobody is online')
            return
        end
        local identity = fw.getIdentity(src)
        t.check('a character has an id and a name', identity ~= nil and type(identity.id) == 'string' and type(identity.name) == 'string')
        t.check('the id leads back to the player', identity ~= nil and fw.getSource(identity.id) == src)
        t.check('a balance is a whole number', math.type(fw.getMoney(src, 'bank')) == 'integer', fw.getMoney(src, 'bank'))
        local job = fw.getJob(src)
        t.check('the job has a name and a grade', job == nil or (type(job.name) == 'string' and type(job.grade) == 'number'))
    end,
}
