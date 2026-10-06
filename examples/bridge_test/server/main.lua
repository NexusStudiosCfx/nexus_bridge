--[[
    bridge_test: runs every module of nexus_bridge once when it starts, and again on
    `bridgetest` in the server console. It only reads, and what it creates it removes, so it
    is safe on a live server. One line per check:

        [bridge_test] OK    framework.listJobs: 23 jobs
        [bridge_test] NO    framework.getIdentity(0): expected nil, got ...

    `bridgetest player <id>` runs the checks that need a connected character on that player.
]]

Bridge.require('>=1.0')

local failures = 0

local function check(what, ok, detail)
    if not ok then failures = failures + 1 end
    print(('[bridge_test] %s  %s%s'):format(ok and 'OK  ' or 'NO  ', what, detail ~= nil and (': ' .. tostring(detail)) or ''))
end

local function core()
    check('Bridge.version', type(Bridge.version) == 'string', Bridge.version)
    check('Bridge.side', Bridge.side == 'server')
    check('format.money', Bridge.format.money(1234567) ~= nil, Bridge.format.money(1234567))

    Bridge.cooldown.clear('bridge_test')
    check('cooldown.try', Bridge.cooldown.try('bridge_test', 5) == true)
    check('cooldown.try again', Bridge.cooldown.try('bridge_test', 5) == false, Bridge.cooldown.remaining('bridge_test'))
    Bridge.cooldown.clear('bridge_test')

    check('ratelimit.check', Bridge.ratelimit.check(-1, 'bridge_test', 1, 60000) and not Bridge.ratelimit.check(-1, 'bridge_test', 1, 60000))
    Bridge.ratelimit.reset(-1)

    check('exports.nexus_bridge:Version()', exports.nexus_bridge:Version() == Bridge.version)
    check('exports.nexus_bridge:FormatMoney()', exports.nexus_bridge:FormatMoney(5) == Bridge.format.money(5))

    if Bridge.db.ready() then
        check('db.scalar', Bridge.db.scalar('SELECT 1') == 1)
        local ok, version = Bridge.db.migrate('bridge_test', {
            [1] = 'CREATE TABLE IF NOT EXISTS `bridge_test_rows` (`id` INT NOT NULL, PRIMARY KEY (`id`))',
            [2] = 'DROP TABLE IF EXISTS `bridge_test_rows`',
        })
        check('db.migrate', ok and version == 2, version)
    else
        check('db.ready', true, 'oxmysql is not running, skipped')
    end
end

local function framework()
    local fw = Bridge.framework
    check('framework adapter', fw.available, fw.name)
    if not fw.available then return end

    local nobody, nowhere = 65534, 'bridge_test_nobody'
    check('framework.getIdentity of nobody', fw.getIdentity(nobody) == nil)
    check('framework.getMoney of nobody', fw.getMoney(nobody, 'bank') == 0)
    check('framework.removeMoney from nobody', fw.removeMoney(nobody, 'bank', 1, 'bridge_test') == false)
    check('framework.addMoney to nobody', fw.addMoney(nobody, 'bank', 1, 'bridge_test') == false)
    check('framework.getMoneyById of an unknown character', fw.getMoneyById(nowhere, 'bank') == nil)
    check('framework.addMoneyById to an unknown character', fw.addMoneyById(nowhere, 'bank', 1, 'bridge_test') == false)
    check('framework.getCharacterName of an unknown character', fw.getCharacterName(nowhere) == nil)
    check('framework.getJob of nobody', fw.getJob(nobody) == nil)
    check('framework.hasGroup of nobody', fw.hasGroup(nobody, 'police') == false)
    check('framework.getSource of an unknown character', fw.getSource(nowhere) == nil)

    local players = fw.getPlayers()
    check('framework.getPlayers', type(players) == 'table', #players .. ' loaded')

    local jobs = fw.listJobs()
    check('framework.listJobs', #jobs > 0, #jobs .. ' jobs')
    local police = fw.jobExists('police') and 'police' or (jobs[1] and jobs[1].name)
    if police then
        local grades = fw.getGrades(police)
        local top = grades[#grades]
        check('framework.getGrades', #grades > 0 and type(top.name) == 'string' and math.type(top.pay) == 'integer',
            ('%s: %d grades, top "%s" pays %s, boss %s'):format(police, #grades, top.name, top.pay, tostring(top.boss)))
        check('framework.jobExists with a grade', fw.jobExists(police, grades[1].grade) and not fw.jobExists(police, 9999))
        check('framework.getJobLabel', type(fw.getJobLabel(police)) == 'string', fw.getJobLabel(police))
        check('framework.getOnDuty', type(fw.getOnDuty(police)) == 'table')
    end
    check('framework.jobExists of a job that is not there', fw.jobExists('bridge_test_no_such_job') == false)

    local caps = {}
    for name, value in pairs(fw.capabilities()) do caps[#caps + 1] = ('%s=%s'):format(name, tostring(value)) end
    table.sort(caps)
    check('framework.capabilities', #caps > 0, table.concat(caps, ' '))
end

--- A character that exists only in the database, for the checks that need one. Answers false
--- on a framework whose table this test does not know.
local function throwaway(id, bank)
    local fw, db = Bridge.framework, Bridge.db
    if fw.name == 'qbx_core' or fw.name == 'qb-core' then
        db.query('DELETE FROM `players` WHERE `citizenid` = ?', { id })
        db.insert('INSERT INTO `players` (`citizenid`, `license`, `name`, `money`, `charinfo`, `job`, `gang`, `position`, `metadata`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            id, 'license:bridge_test', 'bridge_test',
            json.encode({ cash = 0, bank = bank or 0, crypto = 0 }),
            json.encode({ firstname = 'Bridge', lastname = 'Test', birthdate = '2000-01-01', gender = 0, nationality = 'USA', phone = '0000000000', account = 'US00BRIDGE0000000000', cid = 1 }),
            json.encode({ name = 'unemployed', label = 'Civilian', payment = 10, onduty = true, isboss = false, grade = { name = 'Freelancer', level = 0 } }),
            json.encode({ name = 'none', label = 'No Gang Affiliation', isboss = false, grade = { name = 'none', level = 0 } }),
            json.encode({ x = 0.0, y = 0.0, z = 0.0, w = 0.0 }),
            json.encode({}),
        })
        return true
    elseif fw.name == 'es_extended' then
        db.query('DELETE FROM `users` WHERE `identifier` = ?', { id })
        -- ESX 1.15 added a social security number that has to be there.
        if (db.columns('users') or {}).ssn then
            db.insert('INSERT INTO `users` (`identifier`, `ssn`) VALUES (?, ?)', { id, id })
        else
            db.insert('INSERT INTO `users` (`identifier`) VALUES (?)', { id })
        end
        return true
    end
    return false
end

local function discard(id)
    local fw, db = Bridge.framework, Bridge.db
    if fw.name == 'es_extended' then
        db.query('DELETE FROM `users` WHERE `identifier` = ?', { id })
    else
        db.query('DELETE FROM `players` WHERE `citizenid` = ?', { id })
    end
end

--- With `set bridge_test_character 1`: creates a throwaway character that is not online, moves
--- its money through the bridge, compares with what the database holds, and deletes it. Only
--- on QBCore and Qbox, the frameworks that can reach an offline character.
local function character()
    if GetConvarInt('bridge_test_character', 0) ~= 1 then return end
    local fw, db = Bridge.framework, Bridge.db
    if not fw.supports('offlineMoney') then
        check('offline character', true, ('skipped: %s cannot reach a character that is offline'):format(fw.name))
        return
    end
    if fw.name ~= 'qbx_core' and fw.name ~= 'qb-core' then
        check('offline character', true, 'skipped: this test only knows the players table of QBCore and Qbox')
        return
    end

    local id = 'BRTEST01'
    local function bankInDatabase()
        local money = db.scalar('SELECT `money` FROM `players` WHERE `citizenid` = ?', { id })
        return money and json.decode(money).bank or nil
    end

    throwaway(id, 300)

    check('offline: getCharacterName', fw.getCharacterName(id) == 'Bridge Test', fw.getCharacterName(id))
    check('offline: getSource', fw.getSource(id) == nil)
    check('offline: getMoneyById', fw.getMoneyById(id, 'bank') == 300, fw.getMoneyById(id, 'bank'))
    check('offline: addMoneyById', fw.addMoneyById(id, 'bank', 200, 'bridge_test') == true)
    check('offline: the database holds it', bankInDatabase() == 500, bankInDatabase())
    check('offline: removeMoneyById refuses more than there is', fw.removeMoneyById(id, 'bank', 501, 'bridge_test') == false)
    check('offline: and nothing left the account', bankInDatabase() == 500, bankInDatabase())
    check('offline: removeMoneyById', fw.removeMoneyById(id, 'bank', 500, 'bridge_test') == true)
    check('offline: the database holds zero', bankInDatabase() == 0, bankInDatabase())
    check('offline: an unknown account is refused', fw.addMoneyById(id, 'no_such_account', 5, 'bridge_test') == false)

    discard(id)
    check('offline: the test character is gone', fw.getMoneyById(id, 'bank') == nil)
end

--- With `set bridge_test_vehicles 1`: gives a throwaway character a vehicle, hands it to a
--- second one and removes it again, comparing each step with what the bridge answers.
local function vehicles()
    local owned = Bridge.vehicles
    if not owned.available then
        check('vehicles adapter', true, 'none running, skipped')
        return
    end
    check('vehicles adapter', true, owned.name)
    check('vehicles.owner of a plate nobody has', owned.owner('BRT0NONE') == nil and owned.isOwned('BRT0NONE') == false)
    check('vehicles.list of nobody', #owned.list('bridge_test_nobody') == 0)
    check('vehicles.give to nobody', owned.give('bridge_test_nobody', { model = 'sultan', plate = 'BRT0NONE' }) == false)
    if GetConvarInt('bridge_test_vehicles', 0) ~= 1 then return end

    local tables = { ['qb-core'] = 'player_vehicles', es_extended = 'owned_vehicles' }
    if tables[owned.name] and not Bridge.db.columns(tables[owned.name]) then
        check('vehicles: a table to try', true, ('skipped: this database has no %s'):format(tables[owned.name]))
        return
    end

    local first, second, plate = 'BRTEST02', 'BRTEST03', 'BRT0TEST'
    if not (throwaway(first) and throwaway(second)) then
        check('vehicles: two characters to try', true, 'skipped: this test does not know the table of this framework')
        return
    end
    owned.remove(plate)

    local given = owned.give(first, { model = 'sultan', plate = plate, garage = 'bridge_test', props = { color1 = 3 } })
    check('vehicles.give', given == plate, given)
    local found = owned.get(plate) or {}
    check('vehicles.get', found.owner == first and found.stored == true and found.hash == joaat('sultan') and found.props.color1 == 3,
        json.encode({ owner = found.owner, stored = found.stored, model = found.model, hash = found.hash, garage = found.garage }))
    check('vehicles.owns', owned.owns(first, plate) and not owned.owns(second, plate))
    check('vehicles.list', #owned.list(first) == 1 and owned.list(first)[1].plate == plate, #owned.list(first))
    check('vehicles.give refuses a taken plate', owned.give(second, { model = 'adder', plate = plate }) == false and owned.owner(plate) == first)
    check('vehicles.setOwner', owned.setOwner(plate, second) == true and owned.owner(plate) == second, owned.owner(plate))
    check('vehicles.list follows', #owned.list(first) == 0 and #owned.list(second) == 1)
    check('vehicles.setOwner to nobody', owned.setOwner(plate, 'bridge_test_nobody') == false and owned.owner(plate) == second)

    local out = owned.give(first, { model = 'sultan' })
    check('vehicles.give without a plate or a garage', type(out) == 'string' and owned.get(out) ~= nil and owned.get(out).stored == false, out)
    if out then owned.remove(out) end

    check('vehicles.remove', owned.remove(plate) == true and owned.isOwned(plate) == false)
    discard(first)
    discard(second)
end

--- With `set bridge_test_banking 1` the money of a job's account goes up by 25 and down again.
--- Leave it off on a live server: the two movements show in that account's history.
local function banking()
    local bank = Bridge.banking
    if not bank.available then
        check('banking adapter', true, 'none running, skipped')
        return
    end
    check('banking adapter', true, bank.name)
    check('banking.balance of an unknown account', bank.balance('bridge_test_no_such_account') == nil)
    check('banking.add to an unknown account', bank.add('bridge_test_no_such_account', 10, 'bridge_test') == false)
    check('banking.remove from an unknown account', bank.remove('bridge_test_no_such_account', 10, 'bridge_test') == false)
    if GetConvarInt('bridge_test_banking', 0) ~= 1 then return end

    local account = nil
    for _, job in ipairs(Bridge.framework.listJobs()) do
        if bank.balance(job.name) then
            account = job.name
            break
        end
    end
    if not account then
        check('banking: an account to try', true, 'skipped: no job has an account in this bank')
        return
    end
    local start = bank.balance(account)
    check('banking.add', bank.add(account, 25, 'bridge_test') == true and bank.balance(account) == start + 25, ('%s: %s'):format(account, bank.balance(account)))
    check('banking.remove refuses more than there is', bank.remove(account, start + 26, 'bridge_test') == false and bank.balance(account) == start + 25)
    check('banking.remove', bank.remove(account, 25, 'bridge_test') == true and bank.balance(account) == start, ('%s: %s'):format(account, bank.balance(account)))
    check('banking refuses a bad amount', bank.add(account, -5, 'bridge_test') == false and bank.balance(account) == start)
end

--- With `set bridge_test_jobs 1`: hires a throwaway character that is not online, lists the
--- job, fires them again, and makes, changes and removes a grade nobody holds.
local function jobs()
    local fw = Bridge.framework
    if GetConvarInt('bridge_test_jobs', 0) ~= 1 then return end
    if not fw.supports('jobs') then
        check('job management', true, ('skipped: %s has none'):format(tostring(fw.name)))
        return
    end
    local job = fw.jobExists('police') and 'police' or nil
    if not job then
        for _, entry in ipairs(fw.listJobs()) do
            if entry.name ~= 'unemployed' then job = entry.name break end
        end
    end
    local id = 'BRTEST04'
    if not job or not throwaway(id) then
        check('job management', true, 'skipped: no job or no table to try it on')
        return
    end
    local lowest = fw.getGrades(job)[1].grade

    local hired, why = fw.setJob(id, job, lowest)
    check('framework.setJob for somebody offline', hired == true, ('%s %s %s'):format(job, lowest, tostring(why)))
    local listed = false
    for _, employee in ipairs(fw.listEmployees(job)) do
        if employee.id == id and employee.grade == lowest and employee.online == false then listed = true end
    end
    check('framework.listEmployees has them', listed, #fw.listEmployees(job))
    local missing, reason = fw.setJob(id, job, 9999)
    check('framework.setJob refuses a grade that is not there', missing == false and reason == 'grade_missing', tostring(reason))
    check('framework.removeJob', fw.removeJob(id, job) == true)
    local still = false
    for _, employee in ipairs(fw.listEmployees(job)) do
        if employee.id == id then still = true end
    end
    check('framework.listEmployees no longer has them', not still)
    check('framework.setJob for nobody', select(2, fw.setJob('bridge_test_nobody', job, lowest)) == 'no_character')
    discard(id)

    if not fw.supports('grades') then
        check('grade management', true, 'skipped: not on this framework')
        return
    end
    local before = #fw.getGrades(job)
    local made, problem = fw.setGrade(job, 90, { name = 'Bridge Test', pay = 1 })
    check('framework.setGrade makes a grade', made == true and #fw.getGrades(job) == before + 1, tostring(problem))
    check('framework.setGrade changes it', fw.setGrade(job, 90, { pay = 2 }) == true)
    local found = nil
    for _, grade in ipairs(fw.getGrades(job)) do
        if grade.grade == 90 then found = grade end
    end
    check('framework.getGrades shows it', found ~= nil and found.name == 'Bridge Test' and found.pay == 2, found and json.encode(found))
    check('framework.removeGrade', fw.removeGrade(job, 90) == true and #fw.getGrades(job) == before)
end

--- Only what can be asked without a player: nothing is sent to anybody.
local function others()
    local phone = Bridge.phone
    if phone.available then
        check('phone adapter', true, phone.name)
        check('phone.getNumber of nobody', phone.getNumber(65000) == nil and phone.getNumber('bridge_test_nobody') == nil)
        check('phone.notify to nobody', phone.notify(65000, { title = 'bridge_test' }) == false)
        check('phone.mail to an unknown character', phone.mail('bridge_test_nobody', { message = 'bridge_test' }) == false)
    else
        check('phone adapter', true, 'none running, skipped')
    end

    local dispatch = Bridge.dispatch
    check('dispatch adapter', dispatch.available, dispatch.name)
    check('dispatch.send refuses an alert without a place', dispatch.send({ title = 'bridge_test' }) == false)
    -- With `set bridge_test_dispatch 1` a real alert goes out to whoever is on duty.
    if GetConvarInt('bridge_test_dispatch', 0) == 1 then
        local sent = dispatch.send({
            title = 'Bridge test', message = 'An alert from bridge_test, nothing happened.', code = '10-00',
            coords = vector3(441.8, -982.0, 30.7), location = 'Mission Row', jobs = { 'police' }, priority = 'low',
            blip = { seconds = 30 },
        })
        check('dispatch.send', sent == true, tostring(sent))
    end

    local fuel = Bridge.fuel
    check('fuel adapter', fuel.available, fuel.name)
    check('fuel.set refuses what is not a vehicle', fuel.set(0, 50) == false and fuel.get(0) == nil)
end

local function run()
    failures = 0
    core()
    framework()
    character()
    banking()
    vehicles()
    jobs()
    others()
    local adapters = {}
    for module, adapter in pairs(exports.nexus_bridge:Adapters()) do
        adapters[#adapters + 1] = ('%s=%s'):format(module, tostring(adapter))
    end
    table.sort(adapters)
    print(('[bridge_test] adapters: %s'):format(table.concat(adapters, ' ')))
    if failures == 0 then
        print('[bridge_test] ready: every check passed')
    else
        print(('[bridge_test] %d checks did not pass'):format(failures))
    end
end

CreateThread(function()
    Wait(2000)
    run()
end)

RegisterCommand('bridgetest', function(source)
    if source ~= 0 then return end
    CreateThread(run)
end, true)
