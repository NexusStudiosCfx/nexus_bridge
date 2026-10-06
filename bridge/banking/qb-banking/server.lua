--[[
    qb-banking adapter. Written against qb-banking 2.0.0, the version that took over the
    society accounts from qb-management; docs/adapters.md lists every call.

    What to know about qb-banking:
      - RemoveMoney does not look at the balance: an account goes negative. The balance is
        checked here first;
      - AddMoney and RemoveMoney answer with the number of database rows they changed, not
        with true, and false for an account that does not exist. The balance before and
        after decides;
      - GetAccountBalance answers 0 for an account that does not exist, so GetAccount is the
        one that tells them apart;
      - AddMoney and RemoveMoney write their own line into the account's statement;
      - CreateJobAccount does not check whether the account is already there.
]]

local bank = exports['qb-banking']

local function balance(account)
    local found = bank:GetAccount(account)
    if type(found) ~= 'table' then return nil end
    return tonumber(found.account_balance) or 0
end

local banking = {
    caps = { create = true, statements = true },
    balance = balance,
}

function banking.add(account, amount, reason)
    local before = balance(account)
    if not before then return false end
    bank:AddMoney(account, amount, reason)
    return (balance(account) or before) - before >= amount
end

function banking.remove(account, amount, reason)
    local before = balance(account)
    if not before or before < amount then return false end
    bank:RemoveMoney(account, amount, reason)
    return before - (balance(account) or before) >= amount
end

function banking.ensure(account)
    if balance(account) then return true end
    bank:CreateJobAccount(account, 0)
    return balance(account) ~= nil
end

return banking
