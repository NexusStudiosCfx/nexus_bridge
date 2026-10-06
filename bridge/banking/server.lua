--[[
    Bridge.banking (server): the accounts of businesses, jobs and gangs ("society money").

      exists(account)                    true when the bank has that account
      balance(account)                   whole dollars, or nil when there is no such account
      add(account, amount, reason)       true if the money arrived
      remove(account, amount, reason)    true only if the account had it and it left; an
                                         account never goes below zero through the bridge
      ensure(account, label)             makes the account when it is missing: true when it
                                         exists afterwards. supports('create')

    `account` is the name the bank knows the account by: a job name, or a gang name.

    These functions may wait for a database, so they belong in a thread or an event handler.
    With no banking resource running the module is not available: balance is nil and nothing
    moves. A resource that wants to work without a bank keeps the money itself in that case,
    and says so in its own configuration.
]]

local h = ...

local function none() return nil end
local function no() return false end

local fallbacks = {
    balance = none,
    add = no,
    remove = no,
    ensure = no,
}

--- A positive whole amount, or nil. The banks do not check what they are handed: one of them
--- lowers a balance when asked to add a negative amount.
local function whole(amount)
    amount = tonumber(amount)
    if not amount or amount ~= amount or amount == math.huge then return nil end
    amount = math.floor(amount)
    return amount > 0 and amount or nil
end

local function named(account)
    return type(account) == 'string' and account ~= ''
end

return {
    adapters = true,
    caps = { 'create', 'statements' },

    build = function(adapter)
        local a = h.complete(adapter, fallbacks)
        local banking = {}

        function banking.balance(account)
            if not named(account) then return nil end
            local amount = tonumber(a.balance(account))
            return amount and math.floor(amount) or nil
        end

        function banking.exists(account)
            return banking.balance(account) ~= nil
        end

        function banking.add(account, amount, reason)
            amount = whole(amount)
            if not amount or not named(account) then return false end
            return a.add(account, amount, type(reason) == 'string' and reason or nil) == true
        end

        function banking.remove(account, amount, reason)
            amount = whole(amount)
            if not amount or not named(account) then return false end
            return a.remove(account, amount, type(reason) == 'string' and reason or nil) == true
        end

        function banking.ensure(account, label)
            if not named(account) then return false end
            if banking.exists(account) then return true end
            return a.ensure(account, type(label) == 'string' and label or account) == true
        end

        return banking
    end,

    selftest = function(banking, t)
        if not banking.available then
            t.skip('everything', 'no banking resource is running')
            return
        end
        local name = 'nexus_bridge_selftest'
        t.check('an account nobody has is unknown', banking.balance('nexus_bridge_no_such_account') == nil)
        t.check('and takes no money', banking.add('nexus_bridge_no_such_account', 10, 'selftest') == false and banking.remove('nexus_bridge_no_such_account', 10, 'selftest') == false)
        if not banking.supports('create') then
            t.skip('money in and out of an account', banking.name .. ' cannot make an account to try it on')
            return
        end
        if not banking.ensure(name, 'nexus_bridge self-test') then
            t.check('a test account is made', false)
            return
        end
        local start = banking.balance(name)
        t.check('the test account exists', type(start) == 'number', start)
        t.check('money arrives', banking.add(name, 25, 'selftest') == true and banking.balance(name) == start + 25, banking.balance(name))
        t.check('more than there is cannot be taken', banking.remove(name, start + 26, 'selftest') == false and banking.balance(name) == start + 25)
        t.check('the money is taken back out', banking.remove(name, 25, 'selftest') == true and banking.balance(name) == start, banking.balance(name))
        t.check('a bad amount is refused', banking.add(name, -5) == false and banking.add(name, 'x') == false and banking.balance(name) == start)
        t.note(('the account "%s" stays in the bank with the balance it had: a bank has no way to delete one'):format(name))
    end,
}
