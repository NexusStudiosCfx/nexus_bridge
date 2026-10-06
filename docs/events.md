# Events

The frameworks announce the same things under different names, with different arguments, and some of them more often than they happen. The bridge listens to the framework in one place and raises its own events, the same on every server.

```lua
local ref = Bridge.on('playerLoaded', function(src, characterId)
    -- a character is in the world
end)

Bridge.off(ref)
```

`Bridge.on` takes the short name. The events are ordinary local events named `nexus_bridge:<name>`, so `AddEventHandler('nexus_bridge:playerLoaded', ...)` is the same thing, for a resource that does not include the loader.

A client cannot trigger any of them on the server: they are raised with `TriggerEvent`, inside the server.

## Server

| event | arguments | when |
|---|---|---|
| `playerLoaded` | `src, characterId` | a character finished loading. Once per character: a framework that repeats its own event does not repeat this one |
| `playerUnloaded` | `src, characterId` | the character logged out, or the player left. Once |
| `jobChanged` | `src, job` | the job, the grade, the duty or the boss flag changed. `job` is `{ name, label, grade, gradeLabel, boss, onDuty }`. Not raised when a framework announces a job that did not change |
| `moneyChanged` | `src, account, amount, action, reason` | the framework moved money. `action` is `'add'`, `'remove'` or `'set'`. Only with `Bridge.framework.supports('moneyEvents')` |
| `itemUsed` | `src, itemName, slot, metadata` | a player used an item that a resource registered with `Bridge.inventory.registerUsable` |
| `playerDied` | `src` | the player went down: dead or in last stand, whichever comes first. Once until they are up again |
| `playerRevived` | `src` | the player is up again, whoever revived them |

`playerDied` and `playerRevived` come from the medical resource and need one the bridge knows (`Bridge.medical.available`).

### Characters that were already there

A resource that starts while players are online misses their `playerLoaded`. Ask for a replay and the handler runs once for each character that is loaded right now, and then for everybody who loads later:

```lua
Bridge.on('playerLoaded', function(src, characterId)
    loadTheirData(src, characterId)
end, { replay = true })
```

That is the whole "on resource start, loop over the players" block most scripts carry.

## Client

For the local player.

| event | arguments | when |
|---|---|---|
| `playerLoaded` | none | the character is in the world. `{ replay = true }` runs the handler at once when it already is |
| `playerUnloaded` | none | the character logged out |
| `jobChanged` | `job` | as on the server |
| `playerDied`, `playerRevived` | none | as on the server |

Between `playerUnloaded` and the next `playerLoaded`, `Bridge.framework.isLoaded()` is `false` and the other reads answer `nil`.

## What is not an event

- **Money by another resource.** `moneyChanged` is what the framework reports. A bank resource that keeps its own balances does not show up in it.
- **Inventory changes.** There is no "item added" event: inventories differ too much in when they fire one, and a script that needs to know asks `Bridge.inventory.count`.
- **Last stand versus death.** `playerDied` is the moment a player goes down. A resource that has to tell the two apart is an ambulance script and talks to the medical resource directly.

## In an adapter

A framework adapter gets an `emit` table in its `listen` function and calls it from the framework's own events. The bridge does the rest: once per change, the same arguments everywhere.

```lua
function framework.listen(emit)
    h.on('myframework:characterLoaded', function(src) emit.loaded(src) end)
    h.on('myframework:characterUnloaded', function(src) emit.unloaded(src) end)
    h.on('myframework:jobChanged', function(src) emit.job(src) end)
    h.on('myframework:moneyChanged', function(src, account, amount, action, reason)
        emit.money(src, account, amount, action, reason)
    end)
end
```

A medical adapter gets one function in `watch`: `emit(src, isDown)`.
