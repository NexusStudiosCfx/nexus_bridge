--[[
    Bridge.db: oxmysql without including its library, and a migration helper for the tables a
    resource creates when it starts.

      Bridge.db.ready()                     true when oxmysql runs
      Bridge.db.query(sql, params)          rows
      Bridge.db.single(sql, params)         the first row, or nil
      Bridge.db.scalar(sql, params)         the first column of the first row, or nil
      Bridge.db.insert(sql, params)         the new row's id
      Bridge.db.update(sql, params)         how many rows changed
      Bridge.db.transaction(queries)        true when every query went through
      Bridge.db.columns(table)              the table's columns as a set, or nil when the
                                            database has no such table

      Bridge.db.migrate(name, steps)        runs the steps that have not run yet, in order

    The query functions wait for the database, so they belong in a thread or an event handler,
    and they raise what oxmysql raises. They use oxmysql's promise exports (query_async and so
    on, oxmysql 2.x).

    A migration:

        Bridge.db.migrate('nexus_shop', {
            [1] = [=[CREATE TABLE IF NOT EXISTS `nexus_shop_orders` (...)]=],
            [2] = { 'ALTER TABLE `nexus_shop_orders` ADD COLUMN `note` VARCHAR(64) NULL' },
            [3] = function(db) db.update('UPDATE `nexus_shop_orders` SET `note` = ? WHERE `note` IS NULL', { '' }) end,
        })

    Each numbered step runs once per database: the table `nexus_bridge_migrations` remembers the
    last one that finished. A step is one statement, a list of statements or a function. MySQL
    commits every CREATE and ALTER by itself, so a step that stops half way is not undone:
    write statements that can run twice (IF NOT EXISTS) or give each its own step.
]]

local h = ...

local MIGRATIONS = [[
    CREATE TABLE IF NOT EXISTS `nexus_bridge_migrations` (
        `name` VARCHAR(64) NOT NULL,
        `version` INT UNSIGNED NOT NULL DEFAULT 0,
        `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`name`)
    )
]]

local function ready()
    return GetResourceState('oxmysql') == 'started'
end

local function call(method, sql, params)
    if not ready() then
        error('Bridge.db needs oxmysql, and it is not running', 3)
    end
    local oxmysql = exports.oxmysql
    return oxmysql[method .. '_async'](oxmysql, sql, params)
end

return {
    build = function()
        local db = { ready = ready }

        function db.query(sql, params) return call('query', sql, params) end
        function db.single(sql, params) return call('single', sql, params) end
        function db.scalar(sql, params) return call('scalar', sql, params) end
        function db.insert(sql, params) return call('insert', sql, params) end
        function db.update(sql, params) return call('update', sql, params) end
        function db.transaction(queries) return call('transaction', queries) == true end

        --- Asking the catalogue first is how a resource finds out that a table of somebody
        --- else is missing without making the database raise.
        function db.columns(name)
            if type(name) ~= 'string' or name == '' then return nil end
            local rows = db.query('SELECT `COLUMN_NAME` AS `name` FROM `information_schema`.`COLUMNS` WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = ?', { name })
            if type(rows) ~= 'table' or #rows == 0 then return nil end
            local set = {}
            for _, row in ipairs(rows) do set[row.name] = true end
            return set
        end

        local function apply(step)
            if type(step) == 'function' then
                step(db)
            elseif type(step) == 'table' then
                for _, statement in ipairs(step) do db.query(statement) end
            else
                db.query(step)
            end
        end

        local tableReady = false

        --- Runs the steps above the remembered version. Returns true and the version reached,
        --- or false, the version reached and what stopped the next step.
        function db.migrate(name, steps)
            if type(name) == 'table' then name, steps = h.resource, name end
            if type(name) ~= 'string' or type(steps) ~= 'table' then
                error('Bridge.db.migrate(name, steps): name is a string and steps a table of numbered steps', 2)
            end
            if not tableReady then
                db.query(MIGRATIONS)
                tableReady = true
            end

            local last = 0
            for version in pairs(steps) do
                if type(version) == 'number' and version > last then last = version end
            end

            -- Kept in a local first: with no row oxmysql returns nothing at all, not nil.
            local remembered = db.scalar('SELECT `version` FROM `nexus_bridge_migrations` WHERE `name` = ?', { name })
            local current = tonumber(remembered) or 0
            for version = current + 1, last do
                local step = steps[version]
                if step == nil then
                    return false, version - 1, ('step %d is missing'):format(version)
                end
                local ok, problem = pcall(apply, step)
                if not ok then
                    h.say(('migration "%s" stopped at step %d: %s'):format(name, version, tostring(problem)))
                    return false, version - 1, tostring(problem)
                end
                db.query('INSERT INTO `nexus_bridge_migrations` (`name`, `version`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `version` = VALUES(`version`)', { name, version })
                current = version
            end
            return true, current
        end

        return db
    end,

    selftest = function(db, t)
        if not db.ready() then
            t.skip('a query', 'oxmysql is not running')
            return
        end
        t.check('a query answers', db.scalar('SELECT 1') == 1)
        t.check('a table that is not there has no columns', db.columns('nexus_bridge_no_such_table') == nil)
        local name = 'nexus_bridge_selftest'
        -- A run that was cut short may have left these behind.
        db.query('DROP TABLE IF EXISTS `nexus_bridge_selftest`')
        db.query(MIGRATIONS)
        db.query('DELETE FROM `nexus_bridge_migrations` WHERE `name` = ?', { name })
        local ok, version = db.migrate(name, {
            [1] = 'CREATE TABLE IF NOT EXISTS `nexus_bridge_selftest` (`id` INT NOT NULL, PRIMARY KEY (`id`))',
            [2] = function(d) d.insert('INSERT INTO `nexus_bridge_selftest` (`id`) VALUES (?)', { 1 }) end,
        })
        t.check('a migration runs its steps', ok and version == 2, version)
        local again, same = db.migrate(name, { [1] = 'SELECT 1', [2] = 'SELECT 1' })
        t.check('a second run does nothing', again and same == 2)
        t.check('the step left its row', db.scalar('SELECT COUNT(*) FROM `nexus_bridge_selftest`') == 1)
        db.query('DROP TABLE IF EXISTS `nexus_bridge_selftest`')
        db.query('DELETE FROM `nexus_bridge_migrations` WHERE `name` = ?', { name })
    end,
}
