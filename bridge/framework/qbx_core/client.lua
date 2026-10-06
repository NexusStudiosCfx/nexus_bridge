--[[
    Qbox (qbx_core) adapter, client. Written against qbx_core 1.23.0 and 1.24.0; see
    docs/adapters.md.

    The player data is fetched once and then kept current from the events Qbox sends, the way
    its own playerdata module does it. A character counts as loaded from the moment it is in
    the world (QBCore:Client:OnPlayerLoaded), not from the character selection, where Qbox
    already sends its data.
]]

local h = ...
local qbx = exports.qbx_core

local data, inWorld = nil, false

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

local framework = {
    caps = { duty = true, gangs = true, metadata = true, multiJob = true },
}

function framework.start(changed)
    local function fetch()
        local fetched = qbx:GetPlayerData()
        data = type(fetched) == 'table' and fetched.citizenid and fetched or nil
    end

    -- The resource was restarted while the player is in the world.
    if LocalPlayer.state.isLoggedIn then
        inWorld = true
        fetch()
    end

    h.onNet('QBCore:Client:OnPlayerLoaded', function()
        inWorld = true
        fetch()
        changed()
    end)

    local function unloaded()
        if not inWorld and not data then return end
        inWorld, data = false, nil
        changed()
    end
    h.onNet('QBCore:Client:OnPlayerUnload', unloaded)
    h.onNet('qbx_core:client:playerLoggedOut', unloaded)

    h.onNet('QBCore:Player:SetPlayerData', function(value)
        if type(value) ~= 'table' then return end
        data = value
        if inWorld then changed() end
    end)
end

function framework.isLoaded()
    return inWorld and data ~= nil
end

function framework.identity()
    if not data then return nil end
    return { id = data.citizenid, name = fullName(data.charinfo) }
end

function framework.job()
    return data and toJob(data.job) or nil
end

function framework.gang()
    local gang = data and toJob(data.gang)
    if not gang or gang.name == 'none' then return nil end
    gang.onDuty = nil
    return gang
end

function framework.groups()
    local groups = {}
    if not data then return groups end
    for name, grade in pairs(data.jobs or {}) do groups[name] = math.floor(tonumber(grade) or 0) end
    for name, grade in pairs(data.gangs or {}) do groups[name] = math.floor(tonumber(grade) or 0) end
    return groups
end

function framework.money(account)
    return data and data.money and data.money[account] or 0
end

function framework.metadata(key)
    return data and data.metadata and data.metadata[key] or nil
end

function framework.data()
    return data
end

function framework.notify(message, kind, duration)
    if kind == nil or kind == 'info' then kind = 'inform' end
    qbx:Notify(message, kind, duration)
end

return framework
