Bridge.require('>=1.0')

local framework, inventory = Bridge.framework, Bridge.inventory

-- The shops as the server sells them: config.lua joined with what the inventory knows about
-- each item. Built once, when the resource starts.
local shops = {}

for _, entry in ipairs(Config.shops) do
    local shop = { label = entry.label, coords = vec3(entry.coords.x, entry.coords.y, entry.coords.z), list = {}, prices = {} }
    for _, sold in ipairs(entry.items) do
        if inventory.exists(sold.name) then
            shop.list[#shop.list + 1] = { name = sold.name, label = inventory.label(sold.name), price = sold.price }
            shop.prices[sold.name] = sold.price
        else
            print(("[nexus_shop] '%s' is not an item in your inventory (%s), so the shop '%s' does not sell it."):format(sold.name, inventory.name, entry.id))
        end
    end
    shops[entry.id] = shop
end

local function balancesOf(source)
    return { cash = framework.getMoney(source, 'cash'), bank = framework.getMoney(source, 'bank') }
end

local function inRange(source, shop)
    local ped = GetPlayerPed(source)
    return ped ~= 0 and #(GetEntityCoords(ped) - shop.coords) <= Config.range
end

Nexus.handle('shop:catalogue', function(source, data)
    local shop = shops[data.shop]
    if not shop then
        return Nexus.reject('unknown_shop')
    end
    return { label = shop.label, balances = balancesOf(source), items = shop.list }
end)

-- The contract guarantees the shape of `data`: a shop id, 'cash' or 'bank', and 1 to 24 lines
-- with an item name and an amount of 1 to 50. Everything that matters is decided here, from
-- what the server knows: what the shop sells, what it costs, where the player stands, what
-- they can carry and what they can pay.
Nexus.handle('shop:checkout', function(source, data)
    local shop = shops[data.shop]
    if not shop then
        return Nexus.reject('unknown_shop')
    end
    if not inRange(source, shop) then
        return Nexus.reject('too_far')
    end

    -- The same item on two lines counts as one.
    local basket, total = {}, 0
    for _, line in ipairs(data.lines) do
        local price = shop.prices[line.name]
        if not price then
            return Nexus.reject('unknown_item')
        end
        basket[line.name] = (basket[line.name] or 0) + line.amount
        total = total + price * line.amount
    end

    for name, amount in pairs(basket) do
        if not inventory.canCarry(source, name, amount) then
            return Nexus.reject('cannot_carry')
        end
    end

    local available = framework.getMoney(source, data.method)
    if available < total then
        return Nexus.reject('not_enough_money', { missing = total - available })
    end
    -- True only if the whole amount left the account, on every framework.
    if not framework.removeMoney(source, data.method, total, 'nexus_shop') then
        return Nexus.reject('payment_failed')
    end

    -- The money is gone, so every item has to arrive. One that does not is paid back: each
    -- line fitted by itself, and together they may still be too much.
    for name, amount in pairs(basket) do
        if not inventory.add(source, name, amount) then
            local refund = shop.prices[name] * amount
            framework.addMoney(source, data.method, refund, 'nexus_shop refund')
            total = total - refund
        end
    end
    if total == 0 then
        return Nexus.reject('cannot_carry')
    end

    return { total = total, balances = balancesOf(source) }
end)

print(('[nexus_shop] ready: %d shops on %s with %s'):format(#Config.shops, framework.name, inventory.name))
