# Adding an adapter

An adapter is the small file that knows one resource: how its exports are called, what they answer, where it is odd. The category file next to it (`bridge/inventory/server.lua`) knows nothing about any resource and does everything that is the same for all of them: checking arguments, the all-or-nothing rules, the defaults when something is missing.

There are three ways to add one, depending on who you are.

| you are | you want | do this |
|---|---|---|
| a server owner | the bridge to talk to a resource it does not know | [a file in `bridge/custom/`](#1-a-file-in-bridgecustom) |
| the author of a resource | your resource to serve a category on every server that runs it | [register it from your resource](#2-registering-an-adapter-from-your-own-resource) |
| a contributor | the adapter to ship with the bridge | [add it to the repository](#3-adding-it-to-the-bridge-itself) |

All three write the same kind of file.

## What an adapter looks like

A Lua file that returns a table of functions. This is a complete notification adapter:

```lua
-- bridge/custom/notify/client.lua
return {
    caps = { title = true, duration = true },

    show = function(message, kind, title, duration)
        exports.my_notify:Send({ text = message, type = kind, header = title, time = duration })
    end,
}
```

By the time `show` is called the category has done its part: `message` is a non-empty text, `kind` is one of `'info'`, `'success'`, `'error'`, `'warning'`, `duration` is a number between 500 and 60000. The adapter only translates.

What each category expects from its adapter is at the top of the category's file and in the adapters next to it. The short version:

| category | side | functions |
|---|---|---|
| framework | server | `getPlayer`, `getIdentity`, `getSource`, `getPlayers`, `getCharacterName`, `getMoney`, `addMoney`, `removeMoney`, `getJob`, `getGang`, `jobExists`, `getJobLabel`, `listJobs`, `getGrades`, `notify`, `listen(emit)`, and optionally the `...ById` money functions, metadata and job management |
| framework | client | `start(changed)`, `isLoaded`, `identity`, `job`, `gang`, `groups`, `money`, `metadata`, `data`, `notify` |
| inventory | server | `items`, `slot`, `canCarry`, `add`, `removeSlot`, `setMetadata`, `clear`, `label`, `exists`, `image`, `weight`, `registerUsable`, and the stash functions |
| target | client | `addSphere(entry)`, `addBox(entry)`, `addEntity(entry)`, `addModel(entry)`, `addGlobal(entry)`, `remove(entry, handle)`, `disable(state)` |
| notify | client | `show(message, kind, title, duration)` |
| banking | server | `balance`, `add`, `remove`, `ensure` |
| vehicles | server | `get`, `list`, `give`, `setOwner`, `remove` |
| keys | server | `give(src, vehicle, plate)`, `remove`, `has`, and `by = 'entity'` or `'plate'` |
| fuel | client, and server where the resource has a server side | `get(vehicle)`, `set(vehicle, level)` |
| dispatch | server, or client for a resource that only takes alerts there | `send(alert)` |
| phone | server | `number(who)`, `notify(who, note)`, `mail(who, mail)`; client: `isOpen`, `notify(note)` |
| medical | server | `isDown(src)`, `revive(src)`, `heal(src)`, `watch(emit)`; client: `isDown()` |
| voice | server | `setRadio(src, channel)`, `setCall`, `getRadio`, `getCall`, `mute`; client: `isTalking()` |
| weather | server | `get()`, `time()`, `set(weather)`, `setTime(hour, minute)`; client: `pause(state)` |
| appearance | client | `open(full, done)`, `reload()`, `get()`, `set(look)` |
| log | server | `send(channel, entry)` |

Leave out what the resource cannot do. A function that is missing answers with the category's harmless default, and `caps` tells scripts beforehand:

```lua
caps = { metadata = false, stashes = false },
```

### The helper

Every adapter file receives one argument, a helper. Take it at the top of the file:

```lua
local h = ...
```

| | |
|---|---|
| `h.bridge` | the bridge itself: `h.bridge.framework.getIdentifier(src)`, `h.bridge.db.query(...)` |
| `h.adapterResource` | the name of the resource this adapter was chosen for |
| `h.resource`, `h.side` | the resource the file is running in, and `'server'` or `'client'` |
| `h.hub` | `true` inside nexus_bridge itself. Every resource that uses the bridge loads the adapter in its own Lua state, so anything that must happen once (listening to an event of the resource) is done `if h.hub` |
| `h.settings()` | the category's part of `Config.settings` |
| `h.on(event, handler)`, `h.onNet(event, handler)` | listen to an event; removed again by itself when the adapter is replaced or the resource stops |
| `h.cleanup(fn)` | runs when the adapter is replaced or the resource stops |
| `h.once(key, message)` | one line in the console, once per key |
| `h.say(message)`, `h.debug(message)` | a line in the console; `debug` only with `Config.debug` |

## 1. A file in bridge/custom

For a server owner. Nothing in `bridge/custom/` is touched by an update.

1. Make the folder `bridge/custom/<category>/`, for example `bridge/custom/notify/`.
2. Write `client.lua` or `server.lua` (or both) in it, on the side the table above names.
3. In `config.lua`:

   ```lua
   Config.adapters = {
       notify = 'custom',
   }
   ```
4. `restart nexus_bridge`, then `bridge doctor`. The category shows `custom`.

If the folder has no file for the side, the doctor says so and the category serves nothing.

## 2. Registering an adapter from your own resource

For the author of a resource that serves a category: your own inventory, notification or dispatch script. The adapter lives in your resource and comes with it, so a server that installs your resource has the bridge talking to it with nothing to configure.

1. Put the adapter files anywhere in your resource:

   ```
   my_notify/
     fxmanifest.lua
     bridge/client.lua
     server.lua
   ```
2. A client file has to be sent to clients. In your `fxmanifest.lua`:

   ```lua
   files { 'bridge/client.lua' }
   ```
3. Register it on the server when your resource starts:

   ```lua
   -- my_notify/server.lua
   local function register()
       if GetResourceState('nexus_bridge') ~= 'started' then return end
       local ok, why = exports.nexus_bridge:RegisterAdapter('notify', {
           name = 'my_notify',
           client = 'bridge/client.lua',      -- paths inside your resource
           -- server = 'bridge/server.lua',
       })
       if not ok then print('nexus_bridge did not take the adapter: ' .. tostring(why)) end
   end

   register()
   -- The bridge may start, or restart, after you.
   AddEventHandler('onResourceStart', function(resource)
       if resource == 'nexus_bridge' then register() end
   end)
   ```

`RegisterAdapter` answers `true`, or `false` and the reason. From then on:

- with `'auto'` in the config, a registered adapter wins over detection, because somebody asked for it;
- `Config.adapters.notify = 'my_notify'` names it explicitly, and any other name overrules it;
- when your resource stops, the registration goes with it and the category falls back to what detection finds;
- `exports.nexus_bridge:UnregisterAdapter('notify')` takes it back by hand.

The file is read from your resource and runs inside every resource that uses the bridge, the same as a built in adapter. It receives the same helper.

## 3. Adding it to the bridge itself

For a pull request. Three things belong together.

1. **The adapter**: `bridge/<category>/<resource name>/server.lua` and/or `client.lua`. Begin the file with a comment that says which version you read and what a reader needs to know about the resource: where it is odd, what it answers on failure, what it does not check. That comment is the most useful part of the file a year from now.
2. **A line in `shared/registry.lua`**, at the place in the order where detection should try it, with its evidence mark: `tested`, `source` or `docs`.
3. **A row in `docs/adapters.md`**: the resource, the mark, the version or commit you read, a link, and every call the adapter makes.

A client or shared file also needs its line under `files` in `fxmanifest.lua`.

Then start it on a server that runs the resource, with `examples/bridge_test` beside it, and read what `bridge doctor` and `bridge selftest` print.

The rules for what goes into an adapter:

- **Never invent a call.** Every export, event, state and table has to be something you read in the resource's source or its vendor's documentation, at a version you can name. If the documentation does not say what a call answers on failure, the adapter does not rely on the answer: it reads the state before and after.
- **Nothing copied.** Read the resource to learn how it is called; write the adapter yourself. Other people's licences do not come along.
- **The category's promise comes first.** If the resource lets a balance go negative, the adapter checks the balance first. If it answers `true` for half an item delivery, the adapter counts what arrived.
- **Say what it cannot do** with `caps`, rather than pretending.

If you run the resource and can show the adapter working on a real server, say so in the pull request: that is what turns `source` or `docs` into `tested`.
