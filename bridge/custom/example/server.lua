--[[
    A template for the server half of your own adapter: see client.lua next to it. A server
    file is read from disk by the server and is never sent to players.

    This one would be a banking adapter. Every function may be left out: what is missing
    answers with the category's harmless default.
]]

local h = ...

return {
    caps = { create = false },

    balance = function(account)
        -- return exports.my_bank:GetBalance(account)
        return nil
    end,

    add = function(account, amount, reason)
        -- return exports.my_bank:Deposit(account, amount, reason) == true
        return false
    end,

    remove = function(account, amount, reason)
        -- The bridge promises that an account never goes below zero. If your bank does not
        -- check that itself, read the balance first.
        return false
    end,
}
