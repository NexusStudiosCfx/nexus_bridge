--[[
    esx_addonaccount adapter: where ESX keeps society money, and what esx_society works on.
    Written against esx_addonaccount 1.1 (ESX-Legacy-Addons v1.15.0); docs/adapters.md lists
    every call.

    What to know about esx_addonaccount:
      - a society account is the shared account 'society_<job>'. The bridge takes the job's
        name and adds the prefix, unless the name already has it;
      - the account object a resource receives is a copy: its money does not follow later
        changes, so the account is fetched again for every read;
      - its functions are called with a dot: account.addMoney(100);
      - removeMoney does not look at the balance: an account goes negative. The balance is
        checked here first;
      - addMoney and removeMoney answer nothing, so the balance before and after decides.
]]

local function nameOf(account)
    if account:sub(1, 8) == 'society_' then return account end
    return 'society_' .. account
end

local function fetch(account)
    local found = nil
    local ok = pcall(function() found = exports['esx_addonaccount']:GetSharedAccount(nameOf(account)) end)
    if not ok then
        -- Releases without the export answer the event at once, in the same call.
        TriggerEvent('esx_addonaccount:getSharedAccount', nameOf(account), function(shared) found = shared end)
    end
    return type(found) == 'table' and found or nil
end

local function balance(account)
    local found = fetch(account)
    return found and tonumber(found.money) or nil
end

local banking = {
    caps = { create = true },
    balance = balance,
}

function banking.add(account, amount)
    local found = fetch(account)
    if not found then return false end
    local before = tonumber(found.money) or 0
    found.addMoney(amount)
    return (balance(account) or before) - before >= amount
end

function banking.remove(account, amount)
    local found = fetch(account)
    if not found then return false end
    local before = tonumber(found.money) or 0
    if before < amount then return false end
    found.removeMoney(amount)
    return before - (balance(account) or before) >= amount
end

function banking.ensure(account, label)
    pcall(function() exports['esx_addonaccount']:AddSharedAccount({ name = nameOf(account), label = label }, 0) end)
    return balance(account) ~= nil
end

return banking
