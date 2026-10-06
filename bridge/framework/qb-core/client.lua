--[[
    QBCore (qb-core) adapter, client. Written against two builds of qb-core that both call
    themselves 1.3.0; see docs/adapters.md.

    The two builds tell a client about changes differently. The older one sends the whole
    player data on every change (QBCore:Player:SetPlayerData). The newer one sends only the
    part that changed (QBCore:Client:OnPlayerUpdated) and the whole only at login. Both are
    listened to, so the data kept here is current on either.
]]

local h = ...

local data, inWorld = nil, false

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

local framework = {
    caps = { duty = true, gangs = true, metadata = true },
}

function framework.start(changed)
    local QBCore = exports['qb-core']:GetCoreObject()

    local function fetch()
        local fetched = QBCore.Functions.GetPlayerData()
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

    h.onNet('QBCore:Client:OnPlayerUnload', function()
        inWorld, data = false, nil
        changed()
    end)

    h.onNet('QBCore:Player:SetPlayerData', function(value)
        if type(value) ~= 'table' then return end
        data = value
        if inWorld then changed() end
    end)

    h.onNet('QBCore:Client:OnPlayerUpdated', function(key, value)
        if key == 'all' and type(value) == 'table' then
            data = value
        elseif data and type(key) == 'string' then
            data[key] = value
        end
        if inWorld then changed() end
    end)

    -- Sent on their own by the older build; harmless repeats on the newer one.
    h.onNet('QBCore:Client:OnJobUpdate', function(job)
        if data and type(job) == 'table' then data.job = job end
        if inWorld then changed() end
    end)
    h.onNet('QBCore:Client:OnGangUpdate', function(gang)
        if data and type(gang) == 'table' then data.gang = gang end
        if inWorld then changed() end
    end)
    h.onNet('QBCore:Client:SetDuty', function(onDuty)
        if data and data.job then data.job.onduty = onDuty == true end
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

function framework.money(account)
    return data and data.money and data.money[account] or 0
end

function framework.metadata(key)
    return data and data.metadata and data.metadata[key] or nil
end

function framework.data()
    return data
end

--- Through the event qb-core itself listens to, so no copy of its core object is needed in
--- every resource that only wants to show a message.
function framework.notify(message, kind, duration)
    if kind == nil or kind == 'info' or kind == 'inform' then kind = 'primary' end
    TriggerEvent('QBCore:Notify', message, kind, duration)
end

return framework
