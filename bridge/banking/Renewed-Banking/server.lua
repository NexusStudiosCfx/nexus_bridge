--[[
    Renewed-Banking adapter. Written against Renewed-Banking 2.1.4; docs/adapters.md lists
    every call.

    What to know about Renewed-Banking:
      - job and gang accounts are in one list, under the job's or gang's name;
      - getAccountMoney answers false for an account it does not know;
      - removeAccountMoney refuses when the balance is short, which is what we want;
      - the money exports write no line into the account's history: handleTransaction does,
        and moves no money. Both are called here;
      - it makes an account for every job and gang of the framework when it starts. Making
        one later is not offered here: in the 2.1.4 release CreateJobAccount raises for a new
        account and forgets it again until the next restart, the fix carries the same version
        number, and the error lands in the console even when it is caught. So `ensure` only
        answers for accounts that exist, and supports('create') is false.
]]

local h = ...
local bank = exports['Renewed-Banking']

local function balance(account)
    local amount = bank:getAccountMoney(account)
    return type(amount) == 'number' and amount or nil
end

--- A line in the account's history. The money has already moved: a line that cannot be
--- written must not turn a payment into a refusal.
local function statement(account, amount, reason, kind)
    local title = h.resource
    pcall(function()
        bank:handleTransaction(account, title, amount, reason or title,
            kind == 'deposit' and title or account, kind == 'deposit' and account or title, kind)
    end)
end

local banking = {
    caps = { statements = true },
    balance = balance,
}

function banking.add(account, amount, reason)
    if not balance(account) then return false end
    if bank:addAccountMoney(account, amount) ~= true then return false end
    statement(account, amount, reason, 'deposit')
    return true
end

function banking.remove(account, amount, reason)
    local have = balance(account)
    if not have or have < amount then return false end
    if bank:removeAccountMoney(account, amount) ~= true then return false end
    statement(account, amount, reason, 'withdraw')
    return true
end

return banking
