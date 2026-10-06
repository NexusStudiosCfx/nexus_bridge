--[[
    QBCore (qb-core) adapter, server. Written against two builds of qb-core that both call
    themselves 1.3.0 (before and after its 2026 refactor); docs/adapters.md lists every call.

    What to know about QBCore:
      - the core object is a copy: it is fetched again when qb-core says its shared data changed;
      - the bank may go down to a minus limit, so a balance is checked before money is taken;
      - AddMoney and RemoveMoney answer true, false or nothing depending on build and fork,
        so the balance before and after decides when the answer is not a clear true;
      - an offline character is loaded, changed and saved: its money functions only change
        memory until Save() is called;
      - a character has one job.
]]

local h = ...

local QBCore = exports['qb-core']:GetCoreObject()
h.on('QBCore:Server:UpdateObject', function()
    QBCore = exports['qb-core']:GetCoreObject()
end)

local function playerOf(src)
    src = tonumber(src)
    return src and QBCore.Functions.GetPlayer(src) or nil
end

local function fullName(info)
    if type(info) ~= 'table' or not info.firstname then return nil end
    return (('%s %s'):format(info.firstname, info.lastname or '')):gsub('%s+$', '')
end

local function toJob(job)
    if type(job) ~= 'table' or not job.name then return nil end
    local grade = type(job.grade) == 'table' and job.grade or { level = job.grade }
    return {
        name = job.name,
        label = job.label or job.name,
        grade = math.floor(tonumber(grade.level) or 0),
        gradeLabel = grade.name or '',
        boss = job.isboss == true or grade.isboss == true,
        onDuty = job.onduty == true,
    }
end

local function balance(player, account)
    local money = player.PlayerData.money
    local amount = money and tonumber(money[account])
    return amount and math.floor(amount) or nil
end

local function add(player, account, amount, reason)
    local before = balance(player, account)
    if not before then return false end
    if player.Functions.AddMoney(account, amount, reason) == true then return true end
    return (balance(player, account) or before) - before >= amount
end

local function remove(player, account, amount, reason)
    local before = balance(player, account)
    if not before or before < amount then return false end
    if player.Functions.RemoveMoney(account, amount, reason) == true then return true end
    return before - (balance(player, account) or before) >= amount
end

--- A character that is not online, loaded from the database, or nil.
local function offline(id)
    if type(id) ~= 'string' or QBCore.Functions.GetPlayerByCitizenId(id) then return nil end
    return QBCore.Functions.GetOfflinePlayerByCitizenId(id)
end

local function jobOf(name)
    local jobs = QBCore.Shared and QBCore.Shared.Jobs
    return jobs and jobs[name] or nil
end

local framework = {
    caps = {
        offlineMoney = true, duty = true, gangs = true,
        metadata = true, usableItems = true, moneyEvents = true,
        jobs = true, grades = true, gradeBoss = true, gradesPersist = false,
    },
}

framework.getPlayer = playerOf

function framework.core()
    return QBCore
end

function framework.getIdentity(src)
    local player = playerOf(src)
    if not player then return nil end
    local data = player.PlayerData
    local info = data.charinfo or {}
    return {
        id = data.citizenid,
        name = fullName(info) or GetPlayerName(src),
        firstName = info.firstname,
        lastName = info.lastname,
    }
end

function framework.getSource(id)
    local player = QBCore.Functions.GetPlayerByCitizenId(id)
    return player and player.PlayerData.source or nil
end

function framework.getPlayers()
    local out = {}
    for _, src in ipairs(QBCore.Functions.GetPlayers() or {}) do out[#out + 1] = tonumber(src) end
    table.sort(out)
    return out
end

function framework.getCharacterName(id)
    if type(id) ~= 'string' then return nil end
    local player = QBCore.Functions.GetPlayerByCitizenId(id) or QBCore.Functions.GetOfflinePlayerByCitizenId(id)
    return player and fullName(player.PlayerData.charinfo) or nil
end

function framework.getMoney(src, account)
    local player = playerOf(src)
    return player and balance(player, account) or 0
end

function framework.addMoney(src, account, amount, reason)
    local player = playerOf(src)
    return player ~= nil and add(player, account, amount, reason)
end

function framework.removeMoney(src, account, amount, reason)
    local player = playerOf(src)
    return player ~= nil and remove(player, account, amount, reason)
end

function framework.getMoneyById(id, account)
    local player = offline(id)
    return player and balance(player, account) or nil
end

function framework.addMoneyById(id, account, amount, reason)
    local player = offline(id)
    if not player or not add(player, account, amount, reason) then return false end
    player.Functions.Save()
    return true
end

function framework.removeMoneyById(id, account, amount, reason)
    local player = offline(id)
    if not player or not remove(player, account, amount, reason) then return false end
    player.Functions.Save()
    return true
end

function framework.getJob(src)
    local player = playerOf(src)
    return player and toJob(player.PlayerData.job) or nil
end

function framework.getGang(src)
    local player = playerOf(src)
    local gang = player and toJob(player.PlayerData.gang)
    -- Everybody is in the gang 'none' there.
    if not gang or gang.name == 'none' then return nil end
    gang.onDuty = nil
    return gang
end

function framework.getOnDuty(jobName)
    local sources = QBCore.Functions.GetPlayersOnDuty(jobName)
    return type(sources) == 'table' and sources or {}
end

function framework.jobExists(jobName, grade)
    local job = jobOf(jobName)
    if not job then return false end
    if grade == nil then return true end
    -- The grades of a job are keyed by text there: '0', '1', ...
    return job.grades ~= nil and (job.grades[tostring(grade)] or job.grades[tonumber(grade)]) ~= nil
end

function framework.getJobLabel(jobName)
    local job = jobOf(jobName)
    return job and (job.label or jobName) or nil
end

function framework.listJobs()
    local out = {}
    for name, job in pairs(QBCore.Shared and QBCore.Shared.Jobs or {}) do
        out[#out + 1] = { name = name, label = job.label or name }
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

function framework.getGrades(jobName)
    local out = {}
    local job = jobOf(jobName)
    for key, grade in pairs(job and job.grades or {}) do
        local level = tonumber(key)
        if level then
            out[#out + 1] = {
                grade = math.floor(level),
                name = grade.name or tostring(key),
                pay = math.floor(tonumber(grade.payment) or 0),
                boss = grade.isboss == true,
            }
        end
    end
    table.sort(out, function(a, b) return a.grade < b.grade end)
    return out
end

--- A character by id, online or loaded from the database, or nil.
local function character(id)
    return QBCore.Functions.GetPlayerByCitizenId(id) or QBCore.Functions.GetOfflinePlayerByCitizenId(id)
end

--- A character that is offline is saved in the background: Save() answers before the row
--- is written, and whoever reads the table next (the employees of a job) would still find
--- the old job. So the row is watched until it holds the new one.
local function landed(id, jobName, grade)
    local db = h.bridge.db
    if not db.ready() or not coroutine.isyieldable() then return end
    local deadline = GetGameTimer() + 3000
    repeat
        local saved = db.scalar('SELECT job FROM players WHERE citizenid = ?', { id })
        local job = type(saved) == 'string' and json.decode(saved) or saved
        if type(job) == 'table' and job.name == jobName and (grade == nil or toJob(job).grade == grade) then return end
        Wait(50)
    until GetGameTimer() > deadline
end

--- SetJob puts a character on the job's default duty. A new grade in the job they already
--- have should not clock anybody in or out, so the duty they had is put back.
local function assign(player, jobName, grade)
    local before = player.PlayerData.job
    local sameJob = type(before) == 'table' and before.name == jobName
    local wasOn = sameJob and before.onduty == true
    if player.Functions.SetJob(jobName, grade) ~= true then return false end
    if sameJob and not player.Offline then player.Functions.SetJobDuty(wasOn) end
    player.Functions.Save()
    if player.Offline then landed(player.PlayerData.citizenid, jobName, grade) end
    return true
end

function framework.setJob(id, jobName, grade)
    local player = character(id)
    if not player then return false, 'no_character' end
    return assign(player, jobName, grade)
end

function framework.removeJob(id, jobName)
    local player = character(id)
    if not player then return false, 'no_character' end
    local job = player.PlayerData.job
    if type(job) ~= 'table' or job.name ~= jobName then return true end
    if player.Functions.SetJob('unemployed', 0) ~= true then return false, 'refused' end
    player.Functions.Save()
    if player.Offline then landed(id, 'unemployed') end
    return true
end

function framework.setDuty(src, onDuty, jobName)
    local player = playerOf(src)
    if not player then return false end
    local job = player.PlayerData.job
    if type(job) ~= 'table' or (jobName and job.name ~= jobName) then return false end
    if job.onduty == onDuty then return true end
    player.Functions.SetJobDuty(onDuty)
    -- What the core's own duty toggle sends after it, so other resources follow.
    TriggerEvent('QBCore:Server:SetDuty', tonumber(src), onDuty)
    TriggerClientEvent('QBCore:Client:SetDuty', tonumber(src), onDuty)
    return true
end

function framework.listEmployees(jobName)
    local out, seen = {}, {}
    -- Somebody who is online first: their job in memory is newer than the saved row.
    for _, player in pairs(QBCore.Functions.GetQBPlayers() or {}) do
        local data = player.PlayerData
        seen[data.citizenid] = true
        if type(data.job) == 'table' and data.job.name == jobName then
            out[#out + 1] = { id = data.citizenid, name = fullName(data.charinfo), grade = toJob(data.job).grade, online = true }
        end
    end
    -- The job is saved as JSON text in the players table, so the name is looked for in it
    -- and the row is read properly before it counts.
    local db = h.bridge.db
    if not db.ready() then return out end
    local rows = db.query('SELECT citizenid, charinfo, job FROM players WHERE job LIKE ?', { ('%%"name":"%s"%%'):format(jobName) })
    for _, row in ipairs(rows or {}) do
        local job = type(row.job) == 'string' and json.decode(row.job) or row.job
        if not seen[row.citizenid] and type(job) == 'table' and job.name == jobName then
            local info = type(row.charinfo) == 'string' and json.decode(row.charinfo) or row.charinfo
            out[#out + 1] = { id = row.citizenid, name = fullName(info), grade = toJob(job).grade, online = false }
        end
    end
    return out
end

--- Jobs are edited as a whole: a copy with the one grade changed is handed to UpdateJob,
--- and whoever holds that grade right now is given the job again so that they see it.
local function editJob(jobName, change)
    local job = jobOf(jobName)
    local copy = { grades = {} }
    for key, value in pairs(job) do
        if key ~= 'grades' then copy[key] = value end
    end
    for key, grade in pairs(job.grades or {}) do
        local same = {}
        for field, value in pairs(grade) do same[field] = value end
        copy.grades[tostring(key)] = same
    end
    change(copy.grades)
    if exports['qb-core']:UpdateJob(jobName, copy) ~= true then return false end
    QBCore = exports['qb-core']:GetCoreObject()
    return true
end

function framework.setGrade(jobName, grade, data)
    local key = tostring(grade)
    local done = editJob(jobName, function(grades)
        local current = grades[key] or {}
        local boss = current.isboss == true
        if data.boss ~= nil then boss = data.boss end
        grades[key] = { name = data.name or current.name or ('Grade %d'):format(grade), payment = data.pay or current.payment or 0, isboss = boss }
    end)
    if not done then return false end
    for _, player in pairs(QBCore.Functions.GetQBPlayers() or {}) do
        local job = player.PlayerData.job
        if type(job) == 'table' and job.name == jobName and toJob(job).grade == grade then assign(player, jobName, grade) end
    end
    return true
end

function framework.removeGrade(jobName, grade)
    return editJob(jobName, function(grades) grades[tostring(grade)] = nil end)
end

function framework.getMetadata(src, key)
    local player = playerOf(src)
    local metadata = player and player.PlayerData.metadata
    return metadata and metadata[key] or nil
end

function framework.setMetadata(src, key, value)
    local player = playerOf(src)
    if not player then return false end
    player.Functions.SetMetaData(key, value)
    return true
end

function framework.registerUsable(item, callback)
    QBCore.Functions.CreateUseableItem(item, callback)
    return true
end

function framework.notify(src, message, kind, duration)
    -- QBCore calls its plain kind 'primary'.
    if kind == nil or kind == 'info' or kind == 'inform' then kind = 'primary' end
    TriggerClientEvent('QBCore:Notify', src, message, kind, duration)
end

function framework.listen(emit)
    h.on('QBCore:Server:PlayerLoaded', function(player)
        local src = type(player) == 'table' and player.PlayerData and player.PlayerData.source
        if src then emit.loaded(src) end
    end)
    h.on('QBCore:Server:OnPlayerUnload', function(src) emit.unloaded(src) end)
    h.on('QBCore:Server:OnJobUpdate', function(src) emit.job(src) end)
    h.on('QBCore:Server:SetDuty', function(src) emit.job(src) end)
    h.on('QBCore:Server:OnMoneyChange', function(src, account, amount, action, reason)
        emit.money(src, account, amount, action, reason)
    end)
end

return framework
