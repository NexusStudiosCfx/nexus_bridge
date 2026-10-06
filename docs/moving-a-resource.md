# Moving a resource onto the bridge

This is what it takes to move an existing resource from its own framework and inventory code onto Nexus Bridge. It was written while doing it to a real one: `nexus_shop`, a small shop with a clerk, a target option, a basket and a checkout. The result is in [examples/nexus_shop](../examples/nexus_shop), and it was started on Qbox, QBCore, ESX and ESX with ox_inventory before this page was written.

Before the move the shop needed ox_inventory and ox_target, and knew three frameworks by hand. After it, it runs on whatever the server has.

| | before | after |
|---|---|---|
| frameworks | qbx_core, qb-core, es_extended, each written out | any the bridge knows |
| inventory | ox_inventory only | ox_inventory, qb-inventory, the ESX inventory |
| target | ox_target only | ox_target, qb-target, sleepless_interact, or a key prompt |
| lines of code that name another resource | 84 (72 of them a file of framework detection) | 0 |

## The steps

### 1. The manifest

```lua
-- before
dependencies {
    'ox_inventory',
    'ox_target',
}

-- after
shared_scripts {
    '@nexus_bridge/init.lua',
    ...
}
```

Take out the dependencies on the resources the bridge now finds for you, and add the loader as the first shared script. Do **not** list `nexus_bridge` as a dependency: FXServer stops the dependents of a resource that restarts and never starts them again, so a server owner who updates the bridge would have to start every script by hand. The loader says clearly what to do when the bridge is missing, and a running resource picks a restarted bridge up again by itself.

Say what you need at the top of a server file:

```lua
Bridge.require('>=1.0')
```

### 2. Money

The shop had a file whose whole job was to know three frameworks:

```lua
-- before: server/money.lua, one of three branches
elseif started('es_extended') then
    local ESX = exports.es_extended:getSharedObject()
    -- ESX calls cash the account 'money'.
    local account = { cash = 'money', bank = 'bank' }

    -- removeAccountMoney does not say whether it worked, so the balance is checked first.
    function Money.remove(source, method, amount, reason)
        local player = ESX.GetPlayerFromId(source)
        if not player or balance(player, method) < amount then return false end
        player.removeAccountMoney(account[method], amount, reason)
        return true
    end
```

```lua
-- after: the file is gone
local available = framework.getMoney(source, data.method)
if not framework.removeMoney(source, data.method, total, 'nexus_shop') then
    return Nexus.reject('not_enough_money')
end
```

The knowledge in that file (cash is called `money` on ESX, its remove does not report failure, QBCore's bank can go negative) did not disappear. It moved into the bridge, where it is written once and tested against every framework.

What to look for when you replace money code:

- `removeMoney` is `true` only when the whole amount left. You do not need a balance check in front of it for safety, only if you want to tell the player how much is missing.
- Amounts are whole dollars. The shop used to `math.floor` and `math.ceil` balances; the bridge hands out whole numbers.
- The account names are `'cash'` and `'bank'` everywhere.

### 3. Items

```lua
-- before
local item = exports.ox_inventory:Items(sold.name)
if item then
    shop.list[#shop.list + 1] = { name = sold.name, label = item.label or sold.name, price = sold.price }
    shop.weights[sold.name] = item.weight or 0
end
...
if not inventory:CanCarryWeight(source, weight) then

-- after
if inventory.exists(sold.name) then
    shop.list[#shop.list + 1] = { name = sold.name, label = inventory.label(sold.name), price = sold.price }
end
...
for name, amount in pairs(basket) do
    if not inventory.canCarry(source, name, amount) then
```

The shop added up weights itself and asked ox_inventory whether the total fits. That question only exists on an inventory that works in grams, so it became the question every inventory can answer: does this item, this many times, fit. The price for that is in the next step.

`inventory.add` is `true` only when everything arrived. On ox_inventory an item that does not stack can arrive in part and still report success; the bridge counts what arrived and takes a partial delivery back.

### 4. Keep the refund

Each line of the basket fits by itself, but together they may not. The shop already paid back whatever did not arrive after the money was taken, and that code stays exactly as it was:

```lua
for name, amount in pairs(basket) do
    if not inventory.add(source, name, amount) then
        local refund = shop.prices[name] * amount
        framework.addMoney(source, data.method, refund, 'nexus_shop refund')
        total = total - refund
    end
end
```

The bridge makes each call honest. It does not make two calls into one transaction: where your resource takes money and then gives something, the "then" is still yours to guard.

### 5. The target

```lua
-- before
exports.ox_target:addLocalEntity(ped, {
    {
        name = 'nexus_shop:' .. shop.id,
        icon = 'fa-solid fa-basket-shopping',
        label = strings['target.browse'],
        distance = 2.5,
        onSelect = function() ... end,
    },
})
...
exports.ox_target:removeLocalEntity(ped, 'nexus_shop:' .. id)

-- after
targets[shop.id] = Bridge.target.addEntity(ped, {
    label = strings['target.browse'],
    icon = 'fa-basket-shopping',
    distance = 2.5,
    onSelect = function() ... end,
})
...
Bridge.target.remove(targets[id])
```

Options have no names: the bridge hands back an id and you remove by it. Keep the id. On a server without a target resource the same call shows a key prompt next to the clerk, with nothing extra to write.

You can also delete the code that puts options back after the target resource restarts, and the code that removes them when your resource stops. The bridge does both.

### 6. Pictures

```lua
-- before
local imagePath = GetConvar('inventory:imagepath', 'nui://ox_inventory/web/images')
images[sold.name] = item.client and item.client.image or ('%s/%s.png'):format(imagePath, sold.name)

-- after
images[sold.name] = Bridge.inventory.image(sold.name)
```

`image` answers `nil` on an inventory that has no pictures (the plain ESX one). The shop's page already showed the item's name when a picture failed to load, so nothing else changed; a page that assumes a picture needs a fallback now.

### 7. Say where you are running

```lua
print(('[nexus_shop] ready: %d shops on %s with %s'):format(#Config.shops, framework.name, inventory.name))
```

One line that names the adapters saves a round of questions in every support ticket.

## What was learned on the four servers

These are the things that only showed up when the moved shop was started on real servers. Each one changed the bridge, so a resource moved today does not meet them, but they are worth knowing.

- **ESX loads its items after it has started.** The shop builds its price list when it starts, and on plain ESX the item list was still empty in that moment: every item was "not an item in your inventory". The ESX inventory adapter now waits for the list when it is asked from a place that can wait. If your resource asks about items while its script is still loading, ask from a thread instead.
- **Restarting the bridge must not take resources down.** With `dependency 'nexus_bridge'` in the shop's manifest, `restart nexus_bridge` stopped the shop for good. That is why no resource lists the bridge as a dependency, and why the loader builds its modules again when the bridge comes back.
- **Carry limits differ by an order of magnitude.** The second purchase in the shop's test fitted on ox_inventory and not on plain ESX. If your resource hands out many items at once, `canCarry` is not a formality on every server.
- **Not every inventory has what yours had.** The shop needed nothing special. A resource that keeps data on items needs `Bridge.inventory.supports('metadata')` and a plan for the servers where it is `false`: plain ESX refuses an item with metadata outright rather than dropping the data quietly.

## A checklist

1. `shared_script '@nexus_bridge/init.lua'` first; remove the dependencies it replaces; no `dependency 'nexus_bridge'`.
2. `Bridge.require('>=1.0')` at the top of a server file.
3. Delete the `bridge/` folder of the resource and every `GetResourceState` branch, one call site at a time. The table in [api.md](api.md) is in the order most resources need it.
4. Replace "on start, loop over the players" with `Bridge.on('playerLoaded', fn, { replay = true })`.
5. Where the resource relied on something only one inventory or framework has, ask `supports()` and decide what the others get.
6. Remove the config options that chose a framework, an inventory or a target. The server owner chooses once, in the bridge.
7. Keep your own guards: refunds, locks, ownership checks. The bridge makes single calls honest, not sequences.
8. Start it on more than the server you develop on. `examples/bridge_test` shows what such a check looks like.

## Testing a resource that uses the bridge

Your own tests can hand the resource a fake:

```lua
Bridge = {
    framework = { getMoney = function() return 500 end, removeMoney = function() return true end },
    inventory = { canCarry = function() return true end, add = function() return true end },
}
```

The loader leaves a `Bridge` that already exists alone and puts the real one in `NexusBridge`, so a test that sets the global first never touches a server.
