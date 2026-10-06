--[[
    Bridge.permission (server): one way to write "who may do this" in a config, and one
    function that checks it.

      Bridge.permission.check(src, rule)       true when the player passes

    A rule is one of:
      nil or true                everybody
      false                      nobody
      'ace:nexus.admin'          the player has that ace (server.cfg: add_ace group.admin nexus.admin allow)
      'job:police'               has the job. 'job:police:2' from grade 2 up
      'gang:ballas:1'            the same for a gang
      'group:police'             a job or a gang of that name
      'boss:police'              is a boss in that job
      'duty:police'              has the job and is on duty
      { 'job:police', 'ace:nexus.admin' }      a list: any one of them is enough
      { job = 'police', grade = 2, onDuty = true }     a table of conditions: all of them
          keys: ace, job, grade, gang, boss, onDuty. `job` may be a name, a list of names or
          a table { police = 2, sheriff = 0 } of lowest grades.

    The server console (player id 0) passes every rule. A rule that cannot be read fails and
    is named in the console once, so a typing mistake in a config locks people out loudly
    instead of letting everybody in.

      Bridge.permission.describe(rule)         the rule as a short text, for a log or a tooltip
]]

local h = ...

return {
    build = function()
        local permission = {}
        local framework = h.bridge.framework

        local function ace(src, name)
            if type(name) ~= 'string' or name == '' then return false end
            -- FXServer answers 1 for an allowed ace, not true: comparing with true alone
            -- turned every player away.
            local allowed = IsPlayerAceAllowed(tostring(src), name)
            return allowed == true or allowed == 1
        end

        local function inJob(src, name, grade)
            local employment = framework.getEmployment(src, name)
            return employment ~= nil and employment.grade >= (tonumber(grade) or 0), employment
        end

        local words = {}

        function words.ace(src, name) return ace(src, name) end
        function words.job(src, name, grade) return (inJob(src, name, grade)) end
        function words.group(src, name, grade) return framework.hasGroup(src, name, tonumber(grade) or 0) end

        function words.gang(src, name, grade)
            local gang = framework.getGang(src)
            return gang ~= nil and gang.name == name and gang.grade >= (tonumber(grade) or 0)
        end

        function words.boss(src, name)
            local held, employment = inJob(src, name, 0)
            return held and employment.boss == true
        end

        function words.duty(src, name)
            local held, employment = inJob(src, name, 0)
            return held and employment.onDuty == true
        end

        local function unreadable(rule)
            h.once('rule:' .. tostring(rule), ('%s uses a permission rule the bridge cannot read: %s. Nobody passes it.')
                :format(h.resource, type(rule) == 'string' and ('"%s"'):format(rule) or type(rule)))
            return false
        end

        local check

        local function conditions(src, rule)
            if rule.ace ~= nil and not ace(src, rule.ace) then return false end
            if rule.gang ~= nil and not words.gang(src, rule.gang, rule.gangGrade) then return false end
            if rule.job ~= nil then
                local jobs = rule.job
                if type(jobs) == 'string' then jobs = { [jobs] = tonumber(rule.grade) or 0 } end
                if type(jobs) ~= 'table' then return unreadable('job') end
                local passed = false
                for key, value in pairs(jobs) do
                    local name, grade = key, value
                    if type(key) == 'number' then name, grade = value, rule.grade end
                    local held, employment = inJob(src, name, grade)
                    if held and (rule.boss ~= true or employment.boss) and (rule.onDuty ~= true or employment.onDuty) then
                        passed = true
                        break
                    end
                end
                if not passed then return false end
            elseif rule.boss == true or rule.onDuty == true then
                local job = framework.getJob(src)
                if not job or (rule.boss == true and not job.boss) or (rule.onDuty == true and not job.onDuty) then return false end
            end
            return true
        end

        function check(src, rule)
            if rule == nil or rule == true then return true end
            if rule == false then return false end
            if type(rule) == 'string' then
                local word, name, grade = rule:match('^(%a+):([^:]+):?(%d*)$')
                if not word or not words[word] then return unreadable(rule) end
                return words[word](src, name, grade) == true
            end
            if type(rule) ~= 'table' then return unreadable(rule) end
            -- An empty table names nobody: a list somebody emptied should not open the door.
            if next(rule) == nil then return false end
            if rule[1] ~= nil then
                for _, one in ipairs(rule) do
                    if check(src, one) then return true end
                end
                return false
            end
            return conditions(src, rule)
        end

        function permission.check(src, rule)
            src = tonumber(src)
            if not src then return false end
            if src == 0 then return true end
            return check(src, rule) == true
        end

        function permission.describe(rule)
            if rule == nil or rule == true then return 'everybody' end
            if rule == false then return 'nobody' end
            if type(rule) == 'string' then return rule end
            if type(rule) ~= 'table' then return '?' end
            local parts = {}
            if rule[1] ~= nil then
                for _, one in ipairs(rule) do parts[#parts + 1] = permission.describe(one) end
                return table.concat(parts, ' or ')
            end
            for _, key in ipairs({ 'ace', 'job', 'grade', 'gang', 'boss', 'onDuty' }) do
                local value = rule[key]
                if value ~= nil then
                    parts[#parts + 1] = ('%s %s'):format(key, type(value) == 'table' and json.encode(value) or tostring(value))
                end
            end
            return table.concat(parts, ', ')
        end

        return permission
    end,

    selftest = function(permission, t)
        t.check('the console passes, nobody else passes "false"', permission.check(0, false) == true and permission.check(65000, false) == false)
        t.check('a rule for everybody lets a player in', permission.check(65000, nil) == true)
        t.check('a player who is not there has no job', permission.check(65000, 'job:police') == false)
    end,
}
