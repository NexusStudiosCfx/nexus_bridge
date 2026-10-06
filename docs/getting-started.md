# Getting started

For server owners. Nexus Bridge is one resource that the scripts on your server use to talk to your framework, your inventory and the rest. You install it once, and every script that is built on it works with what you run.

## Install

1. Download the release and put the folder into your resources. The folder has to be called `nexus_bridge`.
2. In `server.cfg`, start it after the resources it should find and before the scripts that use it:

   ```cfg
   ensure oxmysql
   ensure qbx_core          # or qb-core, or es_extended
   ensure ox_inventory
   ensure ox_target

   ensure nexus_bridge

   ensure nexus_shop        # everything built on the bridge comes after it
   ```

   The framework has to be above the bridge. For everything else the order only decides how soon it is found: a resource that starts later is picked up when it starts.
3. Start the server and type `bridge doctor` in the server console.

That is all. There is no SQL to import and nothing to build.

## What the doctor tells you

```
nexus_bridge 1.0.0, server side

module      adapter              resource                  evidence  capabilities
framework   qbx_core             qbx_core 1.23.0           tested    yes: offlineMoney, multiJob, duty, gangs, metadata, ...
inventory   ox_inventory         ox_inventory 2.47.9       tested    yes: metadata, slots, stashes, weight, images, usableItems
target      ox_target            ox_target 1.18.1          source
notify      framework            qbx_core 1.23.0           source
banking     none                 no resource the bridge knows for it is running
...

Resources using the bridge:
  nexus_shop 1.1.0: framework (qbx_core), inventory (ox_inventory), requires >=1.0 (satisfied)
```

- **adapter** is what serves the category. `none` means the bridge found nothing for it: scripts get a harmless answer there (no balance, nothing given) and the console names the first call that came back empty.
- **resource** is what the adapter talks to, with the version it reports.
- **evidence** is how sure we are of the adapter: `tested`, `source` or `docs`. [adapters.md](adapters.md) explains the three.
- **capabilities** is what that resource can do. A script asks before it relies on one.
- Under it: every resource that uses the bridge, the version it needs, and anything it asked for that your server could not give. If a script misbehaves, that last part is where to look first.

`bridge doctor` on a client (F8 console) shows the same for the client side.

## The config

`config.lua` is read on the server only and never sent to players.

```lua
Config.adapters = {
    framework = 'auto',
    inventory = 'auto',
    target = 'auto',
    ...
}
```

For each category:

| value | meaning |
|---|---|
| `'auto'` | the first resource of the category's list that is running. The lists are in the README |
| a name, like `'qb-inventory'` | use that one, whatever else runs. If it is not running the category serves nothing and the doctor says why |
| `'custom'` | your own adapter in `bridge/custom/<category>/`. See [adding-an-adapter.md](adding-an-adapter.md) |
| `false` | off: every script gets the harmless default |

You only need this when detection picks the wrong one of two resources you run, or when you want a category off.

`Config.settings` holds the few choices that are yours and not a script's:

| setting | what it does |
|---|---|
| `locale` | the language of the bridge's own texts, and the one `Bridge.locale` loads for every script |
| `framework.bossGrades` | ESX only: the grade names that count as the boss of a job |
| `target.promptKey`, `target.entityKey`, `target.distance` | the keys and the reach of the built in prompt, for servers without a target resource |
| `notify.duration`, `notify.title` | what a notification gets when a script gives none |
| `dispatch.jobs` | who an alert goes to when a script names nobody |
| `phone.sender`, `phone.domain` | who an e-mail is from when a script names nobody |
| `format` | the currency sign and the separators for every amount of money scripts show |

`Config.log.webhooks` takes Discord webhooks by channel. `default` receives every channel that has no line of its own; a channel set to `''` is dropped. With no webhook at all, logs go to fmsdk or fm-logs when one of them runs, and nowhere otherwise.

The settings reach clients; the webhooks never do.

## The self-test

```cfg
set nexus_bridge_selftest 1
```

With this line in `server.cfg`, `bridge selftest` in the server console runs a round of checks through every category and prints `PASS`, `FAIL`, `SKIP` or `NOTE` for each step, and a count at the end. It moves a test item through a stash and takes it out again, and otherwise only reads. Without the line the command only says how to turn it on, so nobody runs it on a live server by accident. Take the line out again when you are done.

A step that needs a player is skipped while nobody is online: run it once with somebody on the server for the full picture. For the client half, use `setr` instead of `set` and type `bridge selftest` in the F8 console.

## Updating

Replace the folder, keep your `config.lua` and anything in `bridge/custom/`, and `restart nexus_bridge`. The scripts that use it keep running and pick the new version up by themselves; there is no need to restart them or the server.

The bridge looks for a newer release once when it starts and says so in the console. `Config.updateCheck = false` turns that off.

A script that needs a newer bridge than you run stops with a message that names both versions.

## When something is wrong

| what you see | what to do |
|---|---|
| `nexus_bridge is not started` from a script | `ensure nexus_bridge` has to be above that script in `server.cfg` |
| a category shows `none` and you do run a resource for it | check the list in the README. If yours is not on it, it needs an adapter: [adding-an-adapter.md](adding-an-adapter.md) |
| the wrong resource was picked | name the right one in `Config.adapters` |
| `asked for and did not get` under a script | that script needs something your server's resource cannot do. The capability named there tells you what |
| a script needs items | `Bridge.inventory.check` prints the item names that are missing from your inventory, once, when the script starts |
