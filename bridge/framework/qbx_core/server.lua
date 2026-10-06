--[[
    Qbox (qbx_core) adapter, server. Written against qbx_core 1.23.0 and 1.24.0; every call is
    listed with its source in docs/adapters.md.

    What to know about Qbox:
      - its exports take a player id (a number) or a citizenid (a string), and tell them apart
        by type: a player id passed as text would be looked up as a citizenid. Ids are made
        numbers here;
      - the money exports also reach a character that is offline;
      - the bank may go below zero there, so a balance is checked before money is taken;
      - a character can hold several jobs. getJob is the active one, getGroups all of them.
]]

local h = ...
local qbx = exports.qbx_core

local function playerOf(src)
    src = tonumber(src)
    return src and qbx:GetPlayer(src) or nil
end

local function fullName(info)
    if type(info) ~= 'table' or not info.firstname then return nil end
    return (('%s %s'):format(info.firstname, info.lastname or '')):gsub('%s+$', '')
end

local function toJob(job)
    if type(job) ~= 'table' or not job.name then return nil end
    local grade = type(job.grade) == 'table' and job.grade or {}
    return {
        name = job.name,
        label = job.label or job.name,
        grade = math.floor(tonumber(grade.level) or 0),
        gradeLabel = grade.name or '',
        boss = job.isboss == true,
        onDuty = job.onduty == true,
    }
end

local function balance(target, account)
    local amount = qbx:GetMoney(target, account)
    if type(amount) ~= 'number' then return nil end
    return math.floor(amount)
end

local framework = {
    caps = {
        offlineMoney = true, multiJob = true, duty = true, gangs = true,
        metadata = true, usableItems = true, moneyEvents = true,
        jobs = true, grades = true, gradeBoss = true, gradesPersist = false,
    },
}

framework.getPlayer = playerOf

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
    local player = qbx:GetPlayerByCitizenId(id)
    return player and player.PlayerData.source or nil
end

function framework.getPlayers()
    local out = {}
    for src in pairs(qbx:GetQBPlayers() or {}) do out[#out + 1] = tonumber(src) end
    table.sort(out)
    return out
end

function framework.getCharacterName(id)
    if type(id) ~= 'string' then return nil end
    local player = qbx:GetPlayerByCitizenId(id) or qbx:GetOfflinePlayer(id)
    return player and fullName(player.PlayerData.charinfo) or nil
end

function framework.getMoney(src, account)
    src = tonumber(src)
    return src and balance(src, account) or 0
end

function framework.addMoney(src, account, amount, reason)
    src = tonumber(src)
    if not src then return false end
    return qbx:AddMoney(src, account, amount, reason) == true
end

function framework.removeMoney(src, account, amount, reason)
    src = tonumber(src)
    if not src then return false end
    local have = balance(src, account)
    if not have or have < amount then return false end
    return qbx:RemoveMoney(src, account, amount, reason) == true
end

function framework.getMoneyById(id, account)
    if type(id) ~= 'string' then return nil end
    return balance(id, account)
end

function framework.addMoneyById(id, account, amount, reason)
    return qbx:AddMoney(id, account, amount, reason) == true
end

--- The module has already checked the balance, and makes these one at a time per character.
function framework.removeMoneyById(id, account, amount, reason)
    return qbx:RemoveMoney(id, account, amount, reason) == true
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

--- Read from the player and not through the GetGroups export, which raises inside qbx_core
--- for a player who is not loaded.
function framework.getGroups(src)
    local groups = {}
    local player = playerOf(src)
    if not player then return groups end
    for name, grade in pairs(player.PlayerData.jobs or {}) do groups[name] = math.floor(tonumber(grade) or 0) end
    for name, grade in pairs(player.PlayerData.gangs or {}) do groups[name] = math.floor(tonumber(grade) or 0) end
    return groups
end

--- The grade of a job, by number: the grade tables are keyed by number there, and by text
--- once they have been through JSON.
local function gradeOf(job, level)
    local grades = job and job.grades
    return grades and (grades[level] or grades[tostring(level)]) or nil
end

function framework.getEmployment(src, jobName)
    local player = playerOf(src)
    if not player then return nil end
    local data = player.PlayerData
    local primary = data.job ~= nil and data.job.name == jobName
    local grade = data.jobs and tonumber(data.jobs[jobName])
    if grade == nil and primary then grade = tonumber(data.job.grade and data.job.grade.level) or 0 end
    if grade == nil then return nil end
    grade = math.floor(grade)
    -- Not IsGradeBoss: it raises for a grade the job no longer has.
    local definition = gradeOf(qbx:GetJob(jobName), grade)
    return {
        grade = grade,
        boss = definition ~= nil and definition.isboss == true,
        onDuty = primary and data.job.onduty == true,
        primary = primary,
    }
end

function framework.getOnDuty(jobName)
    local _, sources = qbx:GetDutyCountJob(jobName)
    return type(sources) == 'table' and sources or {}
end

function framework.jobExists(jobName, grade)
    local job = qbx:GetJob(jobName)
    if not job then return false end
    if grade == nil then return true end
    return gradeOf(job, tonumber(grade)) ~= nil
end

function framework.getJobLabel(jobName)
    local job = qbx:GetJob(jobName)
    return job and (job.label or jobName) or nil
end

function framework.listJobs()
    local out = {}
    for name, job in pairs(qbx:GetJobs() or {}) do
        out[#out + 1] = { name = name, label = job.label or name }
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

function framework.getGrades(jobName)
    local out = {}
    local job = qbx:GetJob(jobName)
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

--- qbx_core answers false and a table with a code; the bridge has its own few words.
local REASONS = {
    job_not_found = 'job_missing',
    job_missing_grade = 'grade_missing',
    player_not_found = 'no_character',
    player_not_in_job = 'refused',
    max_jobs = 'refused',
}

local function answer(ok, problem)
    if ok == true then return true end
    local code = type(problem) == 'table' and problem.code or nil
    return false, REASONS[code] or 'refused'
end

function framework.setJob(id, jobName, grade, add)
    if add then return answer(qbx:AddPlayerToJob(id, jobName, grade)) end
    -- SetJob prints for a character it cannot find, so that is looked at first.
    local online = qbx:GetPlayerByCitizenId(id)
    if not online and not qbx:GetOfflinePlayer(id) then return false, 'no_character' end

    local before = online and online.PlayerData.job or nil
    local ok, reason = answer(qbx:SetJob(id, jobName, grade))
    -- A job that is set starts on its default duty. A new grade in the same job should not
    -- clock anybody in or out.
    if ok and before and before.name == jobName then
        local now = qbx:GetPlayerByCitizenId(id)
        if now and now.PlayerData.job.onduty ~= before.onduty then
            qbx:SetJobDuty(now.PlayerData.source, before.onduty == true)
        end
    end
    return ok, reason
end

function framework.removeJob(id, jobName)
    if not qbx:GetPlayerByCitizenId(id) and not qbx:GetOfflinePlayer(id) then return false, 'no_character' end
    return answer(qbx:RemovePlayerFromJob(id, jobName))
end

function framework.setDuty(src, onDuty, jobName)
    local player = playerOf(src)
    if not player then return false end
    local data = player.PlayerData
    if jobName and data.job.name ~= jobName then
        -- Going off duty in a job that is not the active one: they are off duty in it already.
        if not onDuty then return true end
        if qbx:SetPlayerPrimaryJob(data.citizenid, jobName) ~= true then return false end
    end
    qbx:SetJobDuty(tonumber(src), onDuty)
    local now = playerOf(src)
    return now ~= nil and now.PlayerData.job.onduty == onDuty
end

function framework.listEmployees(jobName)
    local out = {}
    for _, row in ipairs(qbx:GetGroupMembers(jobName, 'job') or {}) do
        local online = qbx:GetPlayerByCitizenId(row.citizenid)
        out[#out + 1] = {
            id = row.citizenid,
            name = online and fullName(online.PlayerData.charinfo) or framework.getCharacterName(row.citizenid),
            grade = math.floor(tonumber(row.grade) or 0),
            online = online ~= nil,
        }
    end
    return out
end

--- A grade is replaced as a whole, so what is not being changed is carried over. Nothing is
--- written to the job files of the server: the change lasts until the next restart.
function framework.setGrade(jobName, grade, data)
    local current = gradeOf(qbx:GetJob(jobName), grade) or {}
    local boss = current.isboss == true
    if data.boss ~= nil then boss = data.boss end
    qbx:UpsertJobGrade(jobName, grade, {
        name = data.name or current.name or ('Grade %d'):format(grade),
        payment = data.pay or current.payment or 0,
        isboss = boss,
        bankAuth = current.bankAuth,
    }, false)
    return gradeOf(qbx:GetJob(jobName), grade) ~= nil
end

function framework.removeGrade(jobName, grade)
    qbx:RemoveJobGrade(jobName, grade, false)
    return gradeOf(qbx:GetJob(jobName), grade) == nil
end

function framework.getMetadata(src, key)
    src = tonumber(src)
    if not src then return nil end
    return qbx:GetMetadata(src, key)
end

function framework.setMetadata(src, key, value)
    src = tonumber(src)
    if not src or not qbx:GetPlayer(src) then return false end
    qbx:SetMetadata(src, key, value)
    return true
end

function framework.registerUsable(item, callback)
    qbx:CreateUseableItem(item, callback)
    return true
end

function framework.notify(src, message, kind, duration)
    -- Handed on to ox_lib, which calls its plain kind 'inform'.
    if kind == nil or kind == 'info' then kind = 'inform' end
    qbx:Notify(src, message, kind, duration)
end

function framework.listen(emit)
    h.on('QBCore:Server:PlayerLoaded', function(player)
        local src = type(player) == 'table' and player.PlayerData and player.PlayerData.source
        if src then emit.loaded(src) end
    end)
    h.on('QBCore:Server:OnPlayerUnload', function(src) emit.unloaded(src) end)
    h.on('qbx_core:server:playerLoggedOut', function(src) emit.unloaded(src) end)
    h.on('QBCore:Server:OnJobUpdate', function(src) emit.job(src) end)
    h.on('QBCore:Server:SetDuty', function(src) emit.job(src) end)
    h.on('qbx_core:server:onGroupUpdate', function(src) emit.job(src) end)
    h.on('QBCore:Server:OnMoneyChange', function(src, account, amount, action, reason)
        emit.money(src, account, amount, action, reason)
    end)
end

return framework
