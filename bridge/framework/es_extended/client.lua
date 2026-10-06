--[[
    ESX (es_extended) adapter, client. Written against ESX Legacy 1.15.2; see docs/adapters.md.

    The shared object a resource receives is a copy, so its PlayerData does not follow the
    game. The data is taken from esx:playerLoaded and kept current from the events ESX sends
    for the job, the accounts and the metadata.
]]

local h = ...

local data = nil

local settings = h.settings()
local bossGrades = {}
for _, name in ipairs(type(settings.bossGrades) == 'table' and settings.bossGrades or { 'boss' }) do
    bossGrades[name] = true
end

local function toJob(job)
    if type(job) ~= 'table' or not job.name then return nil end
    return {
        name = job.name,
        label = job.label or job.name,
        grade = math.floor(tonumber(job.grade) or 0),
        gradeLabel = job.grade_label or job.grade_name or '',
        boss = bossGrades[job.grade_name] == true,
        onDuty = job.onDuty ~= false,
    }
end

local framework = {
    caps = { duty = true, metadata = true },
}

function framework.start(changed)
    local ESX = exports['es_extended']:getSharedObject()

    -- The resource was restarted while the player is in the world.
    if ESX.IsPlayerLoaded and ESX.IsPlayerLoaded() then
        local fetched = ESX.GetPlayerData()
        data = type(fetched) == 'table' and fetched.identifier and fetched or nil
    end

    h.onNet('esx:playerLoaded', function(playerData)
        if type(playerData) ~= 'table' then return end
        data = playerData
        changed()
    end)

    h.onNet('esx:onPlayerLogout', function()
        data = nil
        changed()
    end)

    h.onNet('esx:setJob', function(job)
        if not data or type(job) ~= 'table' then return end
        data.job = job
        changed()
    end)

    -- One account at a time, as { name, money, label }.
    h.onNet('esx:setAccountMoney', function(account)
        if not data or type(account) ~= 'table' or type(data.accounts) ~= 'table' then return end
        for index, held in ipairs(data.accounts) do
            if held.name == account.name then
                data.accounts[index] = account
                return
            end
        end
        data.accounts[#data.accounts + 1] = account
    end)

    h.onNet('esx:updatePlayerData', function(key, value)
        if data and type(key) == 'string' then data[key] = value end
    end)
end

function framework.isLoaded()
    return data ~= nil
end

function framework.identity()
    if not data then return nil end
    local name = nil
    if data.firstName then
        name = (('%s %s'):format(data.firstName, data.lastName or '')):gsub('%s+$', '')
    end
    return { id = data.identifier, name = name }
end

function framework.job()
    return data and toJob(data.job) or nil
end

function framework.money(account)
    if not data or type(data.accounts) ~= 'table' then return 0 end
    local name = account == 'cash' and 'money' or account
    for _, held in ipairs(data.accounts) do
        if held.name == name then return held.money end
    end
    return 0
end

function framework.metadata(key)
    return data and type(data.metadata) == 'table' and data.metadata[key] or nil
end

function framework.data()
    return data
end

--- Through the event ESX itself listens to.
function framework.notify(message, kind, duration)
    if kind == nil or kind == 'inform' then kind = 'info' end
    TriggerEvent('esx:showNotification', message, kind, duration)
end

return framework
