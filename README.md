# Nexus Bridge

One bridge between a FiveM resource and everything it has to talk to: the framework, the
inventory, the target, the bank, the phone and the rest. A resource written against it runs on
Qbox, QBCore and ESX without knowing which one it is on, and a server owner sets things up
once instead of once per script.

```lua
-- fxmanifest.lua
shared_script '@nexus_bridge/init.lua'
```

```lua
-- server/main.lua
Bridge.require('>=1.0')

RegisterNetEvent('my_shop:buy', function(item)
    local src = source
    if not Bridge.inventory.canCarry(src, item, 1) then
        return Bridge.notify.send(src, 'Your pockets are full', 'error')
    end
    if not Bridge.framework.removeMoney(src, 'cash', 50, 'shop') then
        return Bridge.notify.send(src, 'You cannot afford that', 'error')
    end
    Bridge.inventory.add(src, item, 1)
    Bridge.log.send('shop', { title = 'Sale', message = item, player = src })
end)
```

That is the whole integration. No `if GetResourceState('qb-core')`, no bridge folder in the
resource, no config option for which inventory the server runs.

## What it is

- **One global.** `Bridge.framework`, `Bridge.inventory`, `Bridge.target` and so on. A module
  is read the first time a script touches it, in the script's own Lua state: a call is a plain
  function call, not an export.
- **Detection that can be overruled.** Each category finds the resource that is running.
  `config.lua` can name one instead, or switch a category off. Whatever a server lacks answers
  with a harmless default (no money, not carried, not owned) and says so once in the console.
- **The same answer everywhere.** `removeMoney` is true only when the whole amount left the
  account, on every framework. `add` is true only when everything arrived, on every inventory.
  Where the resources underneath disagree, the bridge does the checking.
- **Capabilities instead of surprises.** `Bridge.inventory.supports('metadata')` tells a script
  beforehand what the server's inventory can do.
- **Events that do not depend on the framework.** `Bridge.on('playerLoaded', ...)`,
  `jobChanged`, `moneyChanged`, `itemUsed`, `playerDied`, `playerRevived`.
- **A doctor.** `bridge doctor` in the server console prints what was detected, which version
  of it, what each adapter can do, which resources use the bridge and what they asked for in
  vain.
- **The small things every resource rewrites.** Permission rules, cooldowns that survive a
  restart, a rate limiter for events, database migrations, money formatting, a locale loader,
  points and peds that exist only near the player, and a prop placer.
- **No dependencies.** Not ox_lib, not a framework. oxmysql only when a script uses
  `Bridge.db`. Nothing runs while nothing happens.

## Supported

Every adapter carries one of three marks. **tested**: it ran against the real resource on a
real server. **source**: written against the resource's
published source. **docs**: the resource is escrowed, so only the vendor's documentation could
be read. [docs/adapters.md](docs/adapters.md) lists every call each adapter makes, where it was
read, what exactly ran on a real server, and the resources that are still wanted.

| category | tested | source | docs |
|---|---|---|---|
| framework | qbx_core, qb-core, es_extended | | |
| inventory | ox_inventory, qb-inventory (2.x), the ESX inventory | | |
| target | | ox_target, qb-target, sleepless_interact, and a key prompt of its own | |
| notify | | t-notify, mythic_notify, pNotify, ox_lib, the framework's own, the game's feed | okokNotify, wasabi_notify, lation_ui, brutal_notify |
| banking | Renewed-Banking | qb-banking, esx_addonaccount | |
| vehicles | qbx_vehicles, QBCore's and ESX's vehicle tables | | |
| keys | | qbx_vehiclekeys, qb-vehiclekeys | Renewed-Vehiclekeys, MrNewbVehicleKeys, wasabi_carlock, vehicles_keys, cd_garage |
| fuel | | ox_fuel, LegacyFuel, cdn-fuel, ps-fuel, qb-fuel, lc_fuel, the game's own level | Renewed-Fuel, qs-fuelstations, BigDaddy-Fuel, rcore_fuel, ti_fuel |
| dispatch | lb-tablet | ps-dispatch, and an alert of its own | cd_dispatch, qs-dispatch, core_dispatch, rcore_dispatch, tk_dispatch, codem-dispatchv2, origen_police |
| phone | | npwd, qb-phone | lb-phone, yseries, gksphone, 17mov_Phone, roadphone |
| medical | | nexus_ems, qbx_medical, qb-ambulancejob, esx_ambulancejob, ars_ambulancejob | wasabi_ambulance, wasabi_ambulance_v2 |
| voice | | pma-voice, saltychat | |
| weather | | Renewed-Weathersync, cd_easytime, qb-weathersync, qbx_weathersync | |
| appearance | | illenium-appearance, fivem-appearance, qb-clothing, esx_skin | |
| log | | Discord webhooks of its own, fmsdk, fm-logs, qb-smallresources, ESX | |

Something missing? A server owner adds an adapter in `bridge/custom/` without touching the
rest, and a developer registers one from a resource of their own:
[docs/adding-an-adapter.md](docs/adding-an-adapter.md).

## Install

1. Put the folder into your resources as `nexus_bridge` (the name matters: other resources
   load `@nexus_bridge/init.lua`).
2. Start it after your framework, inventory and the other resources it should find, and before
   the resources that use it:

   ```cfg
   ensure qbx_core
   ensure ox_inventory
   ensure ox_target

   ensure nexus_bridge

   ensure my_shop
   ```
3. Type `bridge doctor` in the server console. It shows what the bridge found:

   ```
   module      adapter              resource                  evidence  capabilities
   framework   qbx_core             qbx_core 1.23.0           tested    yes: offlineMoney, multiJob, duty, gangs, ...
   inventory   ox_inventory         ox_inventory 2.47.9       tested    yes: metadata, slots, stashes, weight, images
   target      ox_target            ox_target 1.18.1          source
   banking     none                 no resource the bridge knows for it is running
   ```

Nothing needs configuring when it found the right things. `config.lua` is where you name an
adapter yourself, switch a category off, set the currency format, the language and the
Discord webhooks for logs. [docs/getting-started.md](docs/getting-started.md) goes through it.

## Using it in a resource

```lua
-- fxmanifest.lua
shared_script '@nexus_bridge/init.lua'
```

```lua
-- anywhere, server or client
local job = Bridge.framework.getJob(source)             -- { name, label, grade, gradeLabel, boss, onDuty }
local ok = Bridge.framework.removeMoney(source, 'bank', 250, 'fine')

Bridge.on('playerLoaded', function(src, characterId) end, { replay = true })

Bridge.target.addPoint({ coords = vector3(25.7, -1347.3, 29.5), options = {
    { label = 'Open the shop', icon = 'fa-solid fa-store', onSelect = openShop },
} })
```

- [docs/api.md](docs/api.md): every function, by category.
- [docs/capabilities.md](docs/capabilities.md): what `supports()` knows, and which adapter has what.
- [docs/events.md](docs/events.md): the events and what they carry.
- [docs/moving-a-resource.md](docs/moving-a-resource.md): taking a resource that has its own
  bridge folder and putting it on this one, with a real resource as the example
  ([examples/nexus_shop](examples/nexus_shop)).
- `types/`: annotations for the Lua language server, so `Bridge.` completes in your editor.

A resource does not list `nexus_bridge` under `dependency`. The loader checks that the bridge
runs and says what to do when it does not, and the bridge can be restarted under running
resources: they pick it up again by themselves.

## Trying it on your server

`examples/bridge_test` is a small resource that runs the bridge on a real server and prints one
line for each check. `bridge doctor` in the server console shows what was detected.

## Licence

MIT. Made by Nexus Studios, used by every Nexus resource, and free for yours.
