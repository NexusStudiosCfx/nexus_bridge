# API

Everything is reached through the global `Bridge`, which a resource gets from one line in its manifest:

```lua
shared_script '@nexus_bridge/init.lua'
```

A resource that already has a global called `Bridge` keeps it and finds the same table under `NexusBridge`.

Rules that hold for every function:

- **`src`** is a player id. **`id`** is a character id: the citizenid on Qbox and QBCore, the identifier on ESX.
- **Money is whole dollars.** A fraction is dropped, and an amount that is not a positive number is refused.
- **`true` means it happened.** A function that changes something answers `true` only when the change is really there, and `false` otherwise. Nothing raises because a player left or a resource is missing.
- **A missing category answers harmlessly**: 0, `nil`, `false` or an empty table, and one line in the console names the first call that came back empty.
- Functions marked *waits* may wait for a database or another resource: call them from an event handler, a command or a thread, not while a script is still loading.

## Core

| | |
|---|---|
| `Bridge.version` | the version of the bridge that is running, as `'1.0.0'` |
| `Bridge.side` | `'server'` or `'client'` |
| `Bridge.require(range)` | stops the resource with a message naming both versions when the bridge is older than it needs. `'>=1.1'`, `'^1.2.0'`, `'~1.2'`, or `'1.2'` for "1.2 or newer, below 2.0" |
| `Bridge.adapter(module)` | the name of the adapter serving a category, or `nil` |
| `Bridge.has(module)` | `true` when the category exists on this side and something serves it |
| `Bridge.supports(module, feature)` | a capability, also as `Bridge.supports('inventory.metadata')`. See [capabilities.md](capabilities.md) |
| `Bridge.on(event, handler, options)` | listens to one of the bridge's events, see [events.md](events.md). Answers a reference for `Bridge.off` |
| `Bridge.off(ref)` | stops listening |

Every category also has `name` (its adapter), `resource` (what the adapter talks to), `available`, `supports(feature)` and `capabilities()`:

```lua
if not Bridge.banking.available then
    -- this server has no bank the bridge knows: keep the money in our own table
end
```

Every function is an export of `nexus_bridge` as well, for a resource that cannot include the loader (JavaScript, C#): `exports.nexus_bridge:FrameworkGetMoney(src, 'bank')` is `Bridge.framework.getMoney(src, 'bank')`. The name is the category and the function, each with a capital. `exports.nexus_bridge:Call('framework.getMoney', src, 'bank')` does the same by name.

## framework

Server.

| function | answers |
|---|---|
| `getIdentifier(src)` | the character id, or `nil` |
| `getIdentity(src)` | `{ id, name, firstName, lastName }`, or `nil` |
| `getName(src)` | the character's name, or the player's name without a character |
| `getSource(id)` | the player id of a character that is online, or `nil` |
| `getPlayers()` | the player ids of every loaded character |
| `isLoaded(src)` | `true` once the player has a character |
| `getCharacterName(id)` | the name of any character, online or not, or `nil` |
| `getMoney(src, account)` | the balance of `'cash'`, `'bank'` or another account the framework has; 0 when there is none |
| `addMoney(src, account, amount, reason)` | `true` if the money arrived |
| `removeMoney(src, account, amount, reason)` | `true` only if the whole amount left. Never takes a part, never goes below zero |
| `getMoneyById(id, account)` | like `getMoney`, by character id; `nil` for an unknown character. *waits* |
| `addMoneyById(id, account, amount, reason)`, `removeMoneyById(...)` | the same for a character that may be offline: `supports('offlineMoney')`. *waits* |
| `getJob(src)` | `{ name, label, grade, gradeLabel, boss, onDuty }`, or `nil` |
| `getGang(src)` | `{ name, label, grade, gradeLabel, boss }`, or `nil` |
| `getGroups(src)` | `{ [name] = grade }` of every job and gang held |
| `hasGroup(src, group, minGrade)` | `group` is a name, a list of names, or `{ police = 2, sheriff = 0 }` |
| `getEmployment(src, job)` | `{ grade, boss, onDuty, primary }`, or `nil` without that job |
| `getOnDuty(job)` | the player ids on duty in a job. A framework without duty counts everybody |
| `jobExists(job, grade)`, `getJobLabel(job)` | |
| `listJobs()` | `{ { name, label } }`, by name |
| `getGrades(job)` | `{ { grade, name, pay, boss } }`, lowest first |
| `getMetadata(src, key)`, `setMetadata(src, key, value)` | `supports('metadata')` |
| `registerUsable(item, function(src, item) end)` | the framework's own usable items. Prefer `Bridge.inventory.registerUsable` |
| `notify(src, message, kind, duration)` | the framework's own notification. Prefer `Bridge.notify.send` |
| `getPlayer(src)`, `core()` | the framework's own objects, for what is not covered. Using them ties the script to one framework |

Managing jobs, for a boss menu or an admin tool. Each answers `true`, or `false` and a reason: `'job_missing'`, `'grade_missing'`, `'no_character'`, `'in_use'`, `'last_grade'`, `'not_supported'`, `'refused'`, `'unavailable'`. *All wait.*

| function | does |
|---|---|
| `setJob(id, job, grade, options)` | hires a character or changes their grade, online or not. `{ add = true }` adds the job next to the ones they have, where a character can hold several (`supports('multiJob')`). A new grade in the same job leaves their duty as it was |
| `removeJob(id, job)` | `true` when the character no longer has the job, also when they never had it |
| `setDuty(src, onDuty, job)` | `true` if the framework now says so. With `job`: only for that job |
| `listEmployees(job)` | `{ { id, name, grade, online } }`, highest grade first, offline characters included |
| `setGrade(job, grade, { name, pay, boss })` | changes a grade or makes it; what is left out stays. `supports('gradeBoss')` says whether the boss flag can change |
| `removeGrade(job, grade)` | never a grade somebody holds, never the last one |

`supports('gradesPersist')` is `true` where a changed grade is still there after a restart (ESX keeps them in its database). Where it is `false`, the resource that changed a grade applies it again when it starts.

Client. The local player's character; reads are plain table reads, cheap enough for a `canInteract` that runs every frame.

| function | answers |
|---|---|
| `isLoaded()` | `true` once a character is in the world |
| `getIdentifier()`, `getName()` | |
| `getJob()`, `getGang()`, `getGroups()`, `hasGroup(group, minGrade)` | as on the server |
| `getMoney(account)` | what the client knows of a balance. For display only |
| `getMetadata(key)`, `getPlayerData()` | |
| `notify(message, kind, duration)` | |

## inventory

An item is `{ slot, name, label, count, metadata, weight, image }`. `inv` is a player id, or the id of a stash where the inventory has them (`supports('stashes')`).

Server.

| function | answers |
|---|---|
| `items(inv)` | every stack held |
| `slot(inv, slot)` | the item in that slot, or `nil` |
| `count(inv, name)` | how many of `name`, over all stacks |
| `has(inv, name, count)` | `true` with at least `count` (1 when left out) |
| `find(inv, name, metadata)` | the stacks of `name` whose metadata holds these values |
| `canCarry(inv, name, count, metadata)` | `true` if it fits |
| `add(inv, name, count, metadata)` | `true` if all of it arrived, with exactly this metadata. Ask `canCarry` first: not every inventory checks the weight on an add |
| `remove(inv, name, count)` | from as many stacks as it takes; all or nothing |
| `removeSlot(inv, slot, name, count)` | out of exactly that slot, and only if it holds `name`. Does not wait, so nothing slips in between the check and the removal |
| `setMetadata(inv, slot, metadata)` | replaces the metadata of a slot |
| `clear(inv, keep)` | empties it, except the item names in `keep` |
| `label(name)`, `exists(name)`, `image(name, metadata)`, `weight(name)` | about an item: its display name, whether the inventory knows it, where its picture is (`nui://...`), what one weighs |
| `missing(names)` | the names the inventory does not know |
| `check(names, hint)` | prints which are missing, once: call it when the resource starts, so an owner who forgot to add the items reads it in the console and not in a bug report |
| `registerUsable(name, function(src, item) end)` | `item` is `{ name, slot, count, metadata }`. `false` when the inventory does not know the item |
| `registerStash(id, { label, slots, weight })`, `openStash(src, id, options)` | a stash, and opening it for a player |
| `stashItems(id)`, `clearStash(id)` | |

An inventory without metadata refuses an `add` that carries any, and says so once. `supports('metadata')` tells beforehand.

Client: `label(name)`, `exists(name)`, `image(name, metadata)`, `items()`, `count(name)`, `has(name, count)`. For showing things: the server decides.

## target

Client only. Served by the server's target resource, or by a key prompt when it has none.

```lua
local id = Bridge.target.addPoint({ coords = vector3(...), radius = 1.5, options = {...} })
local id = Bridge.target.addBox({ coords = vector3(...), size = vector3(1.0, 2.0, 2.0), heading = 90.0, options = {...} })
local id = Bridge.target.addEntity(entity, options)
local id = Bridge.target.addModel({ 'prop_atm_01', 'prop_atm_02' }, options)
local id = Bridge.target.addGlobal('player', options)     -- 'player', 'vehicle', 'ped', 'object'

Bridge.target.remove(id)
Bridge.target.clear()              -- everything this resource added
Bridge.target.disable(true)        -- no targeting while a menu or a scene has the player
```

An option, or a list of them:

```lua
{
    label = 'Open the till',
    icon = 'fa-solid fa-cash-register',
    distance = 2.0,
    onSelect = function(entity) end,          -- entity is nil for a point or a box
    canInteract = function(entity, distance) return true end,
    groups = 'police',                        -- a job or gang, a list, or { police = 2 }
}
```

The bridge remembers what was added. When the target resource restarts, or another one takes over, everything is put back without the script noticing, and when the script stops everything it added is removed.

## notify

| side | function | |
|---|---|---|
| server | `send(src, message, kind, options)` | `src` -1 is everybody |
| client | `show(message, kind, options)` | |

`kind` is `'info'` (when left out), `'success'`, `'error'` or `'warning'`. `options` is `{ title, duration }` with the duration in milliseconds. A resource that has no separate title shows it in front of the message. Text is plain text: for a resource that renders HTML it is escaped.

## banking

Server. The accounts of jobs and gangs. `account` is the job's or gang's name. *All wait.*

| function | answers |
|---|---|
| `exists(account)` | |
| `balance(account)` | whole dollars, or `nil` when the bank has no such account |
| `add(account, amount, reason)` | `true` if the money arrived |
| `remove(account, amount, reason)` | `true` only if the account had it and it left. Never below zero, also on banks that would allow it |
| `ensure(account, label)` | makes the account when it is missing: `supports('create')` |

## vehicles

Server. Who owns which vehicle. *All wait.*

| function | answers |
|---|---|
| `get(plate)` | `{ plate, owner, model, hash, stored, garage, props }`, or `nil` when nobody owns that plate |
| `owner(plate)`, `isOwned(plate)`, `owns(id, plate)` | |
| `list(id)` | every vehicle of a character |
| `give(id, { model, plate, props, garage })` | adds a vehicle: the plate it got, or `false`. Without a plate it gets a free one; with a garage it is stored there, without one it is "out" for a resource that spawns it straight away |
| `setOwner(plate, id)` | `true` when it changed hands. Never to a character that does not exist |
| `remove(plate)` | deletes the stored vehicle |
| `plate()` | eight characters nobody owns yet |

`model` is the model's name where the framework stores one (ESX stores only the hash). `props` is the framework's own table of vehicle properties.

## keys

Server. `give(src, vehicle, plate)`, `remove(src, vehicle, plate)`, `has(src, vehicle, plate)`. Hand over the vehicle's entity, its plate, or both: some key resources go by one and some by the other, and the bridge finds what is missing. `has` needs `supports('has')`.

## fuel

| side | function | |
|---|---|---|
| both | `set(vehicle, level)` | 0 to 100; a level outside is brought inside |
| both | `get(vehicle)` | on the server only with `supports('read')` |

Set from the server when there is a choice: it reaches the fuel resource on its own side and the client that drives the vehicle. Without a fuel resource the game's own fuel level is used.

## dispatch

Server. `Bridge.dispatch.send(alert)` is `true` when the alert was handed over.

```lua
Bridge.dispatch.send({
    title = 'Store robbery',                     -- required
    coords = vector3(25.7, -1347.3, 29.5),       -- required
    message = 'The silent alarm of a store went off',
    code = '10-90',
    location = 'Innocence Blvd',                 -- a name for the place, where one is shown
    jobs = { 'police' },                         -- without it the jobs in config.lua
    priority = 'high',                           -- 'low', 'medium' (when left out), 'high'
    blip = { sprite = 161, colour = 1, scale = 1.0, seconds = 120 },
    source = src,                                -- the player it is about, when there is one
})
```

With no dispatch resource the bridge shows the alert itself: whoever is on duty in one of the jobs gets a notification and a blip.

## phone

Server. `who` is a player id, or a character id.

| function | answers |
|---|---|
| `getNumber(who)` | the phone number as text, or `nil` without a phone. *waits* |
| `notify(src, { title, message, app })` | a notification on the phone |
| `mail(who, { sender, subject, message })` | an e-mail in the inbox: `supports('mail')`. A character that is not online only with `supports('offline')`. *waits* |

Client: `isOpen()`, with `supports('open')`.

With no phone resource nothing is sent. A script that has to reach the player either way falls back to `Bridge.notify`.

## medical

| side | function | |
|---|---|---|
| server | `isDown(src)` | `true` while the player is dead or in last stand |
| server | `revive(src)` | `true` when the medical resource was asked |
| server | `heal(src)` | a full heal for somebody who is up: `supports('heal')` |
| client | `isDown()` | the local player |

It raises `playerDied` and `playerRevived`, see [events.md](events.md).

## voice

Server: `setRadio(src, channel)`, `setCall(src, channel)` (0 or nothing takes the player off), `getRadio(src)`, `getCall(src)` with `supports('read')`, `mute(src, muted)` with `supports('mute')`. A channel is a whole number above zero. Client: `isTalking()` with `supports('talking')`.

## weather

| side | function | |
|---|---|---|
| server | `get()` | the weather type in capitals (`'RAIN'`), or `nil`: `supports('read')` |
| server | `getTime()` | hour, minute: `supports('time')` |
| server | `set(weather)`, `setTime(hour, minute)` | `supports('set')` |
| both | `isRaining()` | |
| client | `get()`, `getTime()` | read from the game itself, so they work with any weather resource |
| client | `pause(state)` | `true`: the weather resource stops setting weather and time for this player, so an interior or a scene can set its own. Counted per resource, and let go when the resource stops |

## appearance

Client.

| function | does |
|---|---|
| `open(options, onDone)` | opens the clothing resource's editor. `{ full = true }` for face and body as well, clothes only without it. `onDone(saved)` where the resource tells: `supports('result')` |
| `reload()` | puts the look the player saved back on: `supports('reload')` |
| `get()`, `set(look)` | takes the current look and puts one back: `supports('snapshot')`. A look is the clothing resource's own table: keep it, do not read it |

Server: `reload(src)`.

## log

Server. `Bridge.log.send(channel, entry)`. `channel` is one word for what it is about (`'shop'`, `'admin'`); the owner decides in config.lua where each goes. `entry` is a text, or `{ title, message, fields, level, player }` with `level` `'info'`, `'warn'` or `'error'` and `player` a player id whose name and character id are added.

## Utilities

These wrap nothing. They are the small things every resource would otherwise write again.

**`Bridge.permission`** (server). `check(src, rule)`. A rule is `nil` or `true` (everybody), `false` (nobody), `'ace:nexus.admin'`, `'job:police'`, `'job:police:2'`, `'gang:ballas:1'`, `'group:police'`, `'boss:police'`, `'duty:police'`, a list of rules (any one is enough) or a table of conditions that all have to hold: `{ job = 'police', grade = 2, onDuty = true }`. The console passes every rule; a rule that cannot be read lets nobody in and is named in the console.

**`Bridge.cooldown`** (server). `start(key, seconds, id)`, `remaining(key, id)`, `active(key, id)`, `try(key, seconds, id)`, `clear(key, id)`. Leave `id` out for one everybody shares, pass a character id for one each character has. Kept in the resource's own key-value store: they survive a restart and nothing ticks.

**`Bridge.ratelimit`** (server). `check(src, name, limit, window)` is `true` while the player is within `limit` calls per `window` milliseconds. `guard(event, handler, limit, window)` registers a net event whose handler only runs within the limit and receives the player id first. `lock(id, name)`, `unlock(id, name)`, `locked(id, name)` for "one purchase at a time".

**`Bridge.db`** (server, needs oxmysql). `query`, `single`, `scalar`, `insert`, `update`, `transaction`, `columns(table)`, `ready()`, and `migrate(name, steps)`, which runs the numbered steps that have not run yet and remembers the last one in the table `nexus_bridge_migrations`.

**`Bridge.format`** (both). `number(1234567.891)` is `'1,234,568'`, `money(1500)` is `'$1,500'`, `compact(1300000)` is `'1.3M'`, with the sign and separators of config.lua.

**`Bridge.locale`** (both). `local L = Bridge.locale.load()` reads `locales/<language>.json` of the resource, with English filling in what is missing; `L('shop.paid', { amount = '$50' })`.

**`Bridge.point`** (client). `add({ coords, distance, onEnter, onExit, nearby })`, `remove(id)`, `inside(id)`. One loop for all points of a resource, once a second while everything is far, every frame only inside a point that has `nearby`, and no loop at all without points.

**`Bridge.ped`** (client). `add({ model, coords, distance, scenario, options, onSpawn })`, `remove(id)`, `entity(id)`. The ped exists only while the player is near, with its target options on it.

**`Bridge.placer`** (client). `start({ model, reach, flatness, canPlace }, function(result) end)` lets the player set an object down where they look and answers `{ coords, heading }`, or `nil` when they cancel. `settle(entity, onDone)` puts a new object on the ground and makes it solid once the ground is there.
