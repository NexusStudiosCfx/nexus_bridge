--[[
    ESX (es_extended) adapter, server. Written against ESX Legacy 1.15.2, with the older
    releases in mind where they differ; docs/adapters.md lists every call.

    What to know about ESX:
      - cash is the account 'money' there. The bridge calls it 'cash' like everybody else;
      - removeAccountMoney does not look at the balance, and the money functions raise on a
        bad amount or an unknown account instead of answering false. So the balance is read
        before and after, and the calls are protected;
      - there is no way to reach a character that is offline: no offlineMoney;
      - a job has no boss flag. By the convention every ESX society script follows, the boss
        is the grade named 'boss' (Config.settings.framework.bossGrades);
      - duty exists from 1.11.0. Before that everybody counts as on duty;
      - a character has one job, and ESX has no gangs.
]]

local h = ...

local ESX = exports['es_extended']:getSharedObject()
if type(ESX) ~= 'table' then
    -- Very old cores are safer to ask through their event.
    TriggerEvent('esx:getSharedObject', function(object) ESX = object end)
end
if type(ESX) ~= 'table' then error('es_extended did not hand out its shared object') end

local version = {}
for part in tostring(GetResourceMetadata(h.adapterResource or 'es_extended', 'version', 0) or ''):gmatch('%d+') do
    version[#version + 1] = tonumber(part)
end

local function atLeast(major, minor, patch)
    local wanted = { major, minor, patch }
    for i = 1, 3 do
        local have = version[i] or 0
        if have ~= wanted[i] then return have > wanted[i] end
    end
    return true
end

local settings = h.settings()
local bossGrades = {}
for _, name in ipairs(type(settings.bossGrades) == 'table' and settings.bossGrades or { 'boss' }) do
    bossGrades[name] = true
end

local function playerOf(src)
    src = tonumber(src)
    return src and ESX.GetPlayerFromId(src) or nil
end

local function accountName(account)
    return account == 'cash' and 'money' or account
end

local function balance(xPlayer, account)
    local held = xPlayer.getAccount(accountName(account))
    local amount = held and tonumber(held.money)
    return amount and math.floor(amount) or nil
end

local function toJob(job)
    if type(job) ~= 'table' or not job.name then return nil end
    return {
        name = job.name,
        label = job.label or job.name,
        grade = math.floor(tonumber(job.grade) or 0),
        gradeLabel = job.grade_label or job.grade_name or '',
        boss = bossGrades[job.grade_name] == true,
        -- No duty before 1.11.0: nil there means "working".
        onDuty = job.onDuty ~= false,
    }
end

local function jobs()
    if not ESX.GetJobs then return {} end
    return ESX.GetJobs() or {}
end

local framework = {
    caps = {
        duty = atLeast(1, 11, 0),
        metadata = atLeast(1, 9, 4),
        moneyEvents = atLeast(1, 9, 4),
        usableItems = true,
        jobs = true,
        grades = ESX.RefreshJobs ~= nil,
        gradeBoss = false,
        gradesPersist = true,
    },
}

framework.getPlayer = playerOf

function framework.core()
    return ESX
end

function framework.getIdentity(src)
    local xPlayer = playerOf(src)
    if not xPlayer then return nil end
    local name = xPlayer.getName and xPlayer.getName() or nil
    if type(name) ~= 'string' or name == '' then name = GetPlayerName(src) end
    return {
        id = xPlayer.identifier,
        name = name,
        firstName = xPlayer.get and xPlayer.get('firstName') or nil,
        lastName = xPlayer.get and xPlayer.get('lastName') or nil,
    }
end

function framework.getSource(id)
    local xPlayer = ESX.GetPlayerFromIdentifier(id)
    return xPlayer and xPlayer.source or nil
end

function framework.getPlayers()
    local out = {}
    if ESX.GetExtendedPlayers then
        -- The third argument asks for player ids instead of whole player objects.
        for _, src in ipairs(ESX.GetExtendedPlayers(nil, nil, true) or {}) do out[#out + 1] = tonumber(src) end
    else
        for _, src in ipairs(GetPlayers()) do
            if ESX.GetPlayerFromId(tonumber(src)) then out[#out + 1] = tonumber(src) end
        end
    end
    table.sort(out)
    return out
end

--- esx_identity adds the name columns to `users`. Without them a name is only known while
--- the character is online.
function framework.getCharacterName(id)
    if type(id) ~= 'string' then return nil end
    local xPlayer = ESX.GetPlayerFromIdentifier(id)
    if xPlayer then
        local name = xPlayer.getName and xPlayer.getName() or nil
        return type(name) == 'string' and name ~= '' and name or nil
    end
    local db = h.bridge.db
    if not db.ready() then return nil end
    local ok, row = pcall(db.single, 'SELECT `firstname`, `lastname` FROM `users` WHERE `identifier` = ?', { id })
    if not ok or type(row) ~= 'table' or not row.firstname then return nil end
    return (('%s %s'):format(row.firstname, row.lastname or '')):gsub('%s+$', '')
end

function framework.getMoney(src, account)
    local xPlayer = playerOf(src)
    return xPlayer and balance(xPlayer, account) or 0
end

function framework.addMoney(src, account, amount, reason)
    local xPlayer = playerOf(src)
    local before = xPlayer and balance(xPlayer, account)
    if not before then return false end
    pcall(xPlayer.addAccountMoney, accountName(account), amount, reason)
    return (balance(xPlayer, account) or before) - before >= amount
end

function framework.removeMoney(src, account, amount, reason)
    local xPlayer = playerOf(src)
    local before = xPlayer and balance(xPlayer, account)
    if not before or before < amount then return false end
    pcall(xPlayer.removeAccountMoney, accountName(account), amount, reason)
    return before - (balance(xPlayer, account) or before) >= amount
end

function framework.getJob(src)
    local xPlayer = playerOf(src)
    if not xPlayer then return nil end
    return toJob(xPlayer.getJob and xPlayer.getJob() or xPlayer.job)
end

function framework.jobExists(jobName, grade)
    local job = jobs()[jobName]
    if not job then return false end
    if grade == nil then return true end
    return job.grades ~= nil and (job.grades[tostring(grade)] or job.grades[tonumber(grade)]) ~= nil
end

function framework.getJobLabel(jobName)
    local job = jobs()[jobName]
    return job and (job.label or jobName) or nil
end

function framework.listJobs()
    local out = {}
    for name, job in pairs(jobs()) do
        out[#out + 1] = { name = name, label = job.label or name }
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

function framework.getGrades(jobName)
    local out = {}
    local job = jobs()[jobName]
    for key, grade in pairs(job and job.grades or {}) do
        local level = tonumber(grade.grade or key)
        if level then
            out[#out + 1] = {
                grade = math.floor(level),
                name = grade.label or grade.name or tostring(key),
                pay = math.floor(tonumber(grade.salary) or 0),
                boss = bossGrades[grade.name] == true,
            }
        end
    end
    table.sort(out, function(a, b) return a.grade < b.grade end)
    return out
end

local function gradeRow(jobName, grade)
    local job = jobs()[jobName]
    local grades = job and job.grades
    return grades and (grades[tostring(grade)] or grades[grade]) or nil
end

local function exists(id)
    local db = h.bridge.db
    return db.ready() and db.single('SELECT `identifier` FROM `users` WHERE `identifier` = ?', { id }) ~= nil
end

--- xPlayer.setJob answers nothing, so the job is read back to see whether it was taken.
local function assign(xPlayer, jobName, grade, onDuty)
    xPlayer.setJob(jobName, grade, onDuty)
    local now = xPlayer.getJob()
    return type(now) == 'table' and now.name == jobName and tonumber(now.grade) == grade
end

function framework.setJob(id, jobName, grade)
    local xPlayer = ESX.GetPlayerFromIdentifier(id)
    if xPlayer then
        -- Without a duty ESX puts them on the default one: in the job they already have,
        -- the duty they had is handed back.
        local before = xPlayer.getJob()
        local onDuty = nil
        if type(before) == 'table' and before.name == jobName then onDuty = before.onDuty end
        return assign(xPlayer, jobName, grade, onDuty)
    end
    if not exists(id) then return false, 'no_character' end
    h.bridge.db.update('UPDATE `users` SET `job` = ?, `job_grade` = ? WHERE `identifier` = ?', { jobName, grade, id })
    return true
end

function framework.removeJob(id, jobName)
    local xPlayer = ESX.GetPlayerFromIdentifier(id)
    if xPlayer then
        local job = xPlayer.getJob()
        if type(job) ~= 'table' or job.name ~= jobName then return true end
        return assign(xPlayer, 'unemployed', 0)
    end
    if not exists(id) then return false, 'no_character' end
    -- Only when the saved row still holds this job.
    h.bridge.db.update('UPDATE `users` SET `job` = ?, `job_grade` = ? WHERE `identifier` = ? AND `job` = ?', { 'unemployed', 0, id, jobName })
    return true
end

function framework.setDuty(src, onDuty, jobName)
    if not framework.caps.duty then return false end
    local xPlayer = playerOf(src)
    local job = xPlayer and xPlayer.getJob() or nil
    if type(job) ~= 'table' or (jobName and job.name ~= jobName) then return false end
    xPlayer.setJob(job.name, job.grade, onDuty)
    local now = xPlayer.getJob()
    return type(now) == 'table' and (now.onDuty ~= false) == onDuty
end

function framework.listEmployees(jobName)
    local out, seen = {}, {}
    for _, src in ipairs(framework.getPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(src)
        local job = xPlayer and xPlayer.getJob() or nil
        if xPlayer then seen[xPlayer.identifier] = true end
        if type(job) == 'table' and job.name == jobName then
            local name = xPlayer.getName and xPlayer.getName() or nil
            out[#out + 1] = { id = xPlayer.identifier, name = type(name) == 'string' and name ~= '' and name or nil, grade = math.floor(tonumber(job.grade) or 0), online = true }
        end
    end
    local db = h.bridge.db
    if not db.ready() then return out end
    -- The name columns are there when esx_identity is installed.
    local named = (db.columns('users') or {}).firstname
    local rows = db.query(named and 'SELECT `identifier`, `job_grade`, `firstname`, `lastname` FROM `users` WHERE `job` = ?'
        or 'SELECT `identifier`, `job_grade` FROM `users` WHERE `job` = ?', { jobName })
    for _, row in ipairs(rows or {}) do
        if not seen[row.identifier] then
            local name = row.firstname and (('%s %s'):format(row.firstname, row.lastname or '')):gsub('%s+$', '') or nil
            out[#out + 1] = { id = row.identifier, name = name, grade = math.floor(tonumber(row.job_grade) or 0), online = false }
        end
    end
    return out
end

--- Grades live in the table `job_grades`, and ESX reads them again with RefreshJobs.
--- Whoever holds a changed grade is given the job again so that they see it.
local function reload(jobName, grade)
    ESX.RefreshJobs()
    for _, src in ipairs(framework.getPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(src)
        local job = xPlayer and xPlayer.getJob() or nil
        if type(job) == 'table' and job.name == jobName and tonumber(job.grade) == grade then
            xPlayer.setJob(jobName, grade, job.onDuty)
        end
    end
end

function framework.setGrade(jobName, grade, data)
    local db = h.bridge.db
    if not ESX.RefreshJobs or not db.ready() then return false, 'not_supported' end
    local current = gradeRow(jobName, grade)
    -- ESX has no boss flag: the boss is the grade with a certain name, which a script has
    -- no business renaming.
    local isBoss = current ~= nil and bossGrades[current.name] == true
    if data.boss ~= nil and data.boss ~= isBoss then return false, 'not_supported' end

    if current then
        db.update('UPDATE `job_grades` SET `label` = ?, `salary` = ? WHERE `job_name` = ? AND `grade` = ?',
            { data.name or current.label or current.name, data.pay or tonumber(current.salary) or 0, jobName, grade })
    else
        local label = data.name or ('Grade %d'):format(grade)
        local name = label:lower():gsub('[^%w]', '')
        if name == '' or bossGrades[name] then name = ('grade%d'):format(grade) end
        db.insert('INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES (?, ?, ?, ?, ?, ?, ?)',
            { jobName, grade, name, label, data.pay or 0, '{}', '{}' })
    end
    reload(jobName, grade)
    return gradeRow(jobName, grade) ~= nil
end

function framework.removeGrade(jobName, grade)
    local db = h.bridge.db
    if not ESX.RefreshJobs or not db.ready() then return false, 'not_supported' end
    local current = gradeRow(jobName, grade)
    if current and bossGrades[current.name] then return false, 'not_supported' end
    db.update('DELETE FROM `job_grades` WHERE `job_name` = ? AND `grade` = ?', { jobName, grade })
    reload(jobName, grade)
    return gradeRow(jobName, grade) == nil
end

function framework.getMetadata(src, key)
    local xPlayer = playerOf(src)
    if not xPlayer or not xPlayer.getMeta then return nil end
    return xPlayer.getMeta(key)
end

function framework.setMetadata(src, key, value)
    local xPlayer = playerOf(src)
    if not xPlayer or not xPlayer.setMeta then return false end
    -- setMeta raises for a value it does not take (a boolean, for one).
    return (pcall(xPlayer.setMeta, key, value))
end

function framework.registerUsable(item, callback)
    ESX.RegisterUsableItem(item, callback)
    return true
end

function framework.notify(src, message, kind, duration)
    -- ESX calls its plain kind 'info'.
    if kind == nil or kind == 'inform' then kind = 'info' end
    TriggerClientEvent('esx:showNotification', src, message, kind, duration)
end

function framework.listen(emit)
    -- The first argument is the player id in every ESX release; what follows changed.
    h.on('esx:playerLoaded', function(src) emit.loaded(src) end)
    h.on('esx:playerDropped', function(src) emit.unloaded(src) end)
    h.on('esx:playerLogout', function(src) emit.unloaded(src) end)
    h.on('esx:setJob', function(src) emit.job(src) end)

    local function money(action)
        return function(src, account, amount, reason)
            emit.money(src, account == 'money' and 'cash' or account, amount, action, reason)
        end
    end
    h.on('esx:addAccountMoney', money('add'))
    h.on('esx:removeAccountMoney', money('remove'))
    h.on('esx:setAccountMoney', money('set'))
end

return framework
