# Capabilities

Not every inventory has stashes, not every framework has duty, not every phone has e-mail. A capability is how a script finds out before it relies on one:

```lua
if Bridge.inventory.supports('metadata') then
    Bridge.inventory.add(src, 'weed_bag', 1, { strain = 'haze', quality = 87 })
else
    Bridge.inventory.add(src, 'weed_bag_haze', 1)
end
```

`Bridge.<category>.supports(feature)` answers `true` or `false`. `Bridge.supports('inventory.metadata')` is the same from anywhere. `Bridge.<category>.capabilities()` is the whole table. An unknown feature, a category that is switched off and a category nothing serves all answer `false`.

Capabilities are about the adapter that is running now. They can change while the server runs (a resource restarts, another one takes over), so ask at the moment you need to know rather than once when the script loads. `bridge doctor` prints them for your server.

Calling a function the adapter lacks is not an error: it answers with the harmless default (`false`, `nil`, an empty table) and the console names it once. The doctor lists it under the resource as "asked for and did not get".

## framework

| capability | means | qbx_core | qb-core | es_extended |
|---|---|---|---|---|
| `offlineMoney` | the `...ById` money functions reach a character that is offline | yes | yes | no |
| `multiJob` | a character can hold several jobs; `setJob(..., { add = true })` | yes | no | no |
| `duty` | the framework keeps on and off duty | yes | yes | from ESX 1.11.0 |
| `gangs` | `getGang` | yes | yes | no |
| `metadata` | `getMetadata`, `setMetadata` | yes | yes | from ESX 1.9.4 |
| `usableItems` | `registerUsable` | yes | yes | yes |
| `moneyEvents` | the `moneyChanged` event | yes | yes | from ESX 1.9.4 |
| `jobs` | `setJob`, `removeJob`, `setDuty`, `listEmployees` | yes | yes | yes |
| `grades` | `setGrade`, `removeGrade` | yes | yes | yes |
| `gradeBoss` | the boss flag of a grade can be changed | yes | yes | no: the boss is the grade with a certain name |
| `gradesPersist` | a changed grade is still there after a restart | no | no | yes |

## inventory

| capability | means | ox_inventory | qb-inventory | the ESX inventory |
|---|---|---|---|---|
| `metadata` | an item keeps its own data | yes | yes | no |
| `slots` | `slot`, `removeSlot`, `setMetadata` go by slot | yes | yes | no |
| `stashes` | `registerStash`, `openStash`, `stashItems`, `clearStash`, and a stash id as `inv` | yes | yes | no |
| `weight` | `canCarry` looks at the weight | yes | yes | yes |
| `images` | `image(name)` | yes | yes | no |
| `usableItems` | `registerUsable` | yes | yes | yes |

## target

| capability | means | ox_target | qb-target | sleepless_interact | key prompt |
|---|---|---|---|---|---|
| `eye` | the player aims with an eye, and options have icons | yes | yes | no | no |
| `boxes` | `addBox` is a real box. Without it a box is a point at its middle | yes | yes | no | yes |
| `entities`, `models`, `globals` | `addEntity`, `addModel`, `addGlobal` | yes | yes | yes | yes |

## notify

| capability | means | has it |
|---|---|---|
| `title` | a separate title. Without it the title goes in front of the message | okokNotify, wasabi_notify, lation_ui, brutal_notify, t-notify, ox_lib |
| `duration` | the duration is used | all but the game's own feed |
| `warning` | a warning looks different from information | all but mythic_notify and the game's own feed |

## The others

| category | capability | means | has it |
|---|---|---|---|
| banking | `create` | `ensure` can make an account | qb-banking, esx_addonaccount |
| banking | `statements` | a movement shows in the account's history | Renewed-Banking, qb-banking |
| vehicles | `give`, `transfer`, `remove` | `give`, `setOwner`, `remove` | all three |
| keys | `has` | the server can ask whether a player has a key | all but cd_garage |
| fuel (server) | `read` | the server can read a level | ox_fuel, Renewed-Fuel |
| dispatch | `blip` | the blip of the alert is used | all but origen_police |
| dispatch | `priority` | a high priority looks urgent | all but tk_dispatch and origen_police |
| dispatch | `code` | the code is shown | all |
| phone | `mail` | `mail` | all but npwd |
| phone | `offline` | an e-mail reaches a character that is not online | lb-phone, yseries, gksphone, roadphone, qb-phone |
| phone (client) | `open` | `isOpen` | all but qb-phone |
| medical | `heal` | `heal` | all but wasabi_ambulance (the first one) |
| medical | `events` | `playerDied` and `playerRevived` are raised | all |
| voice | `read` | `getRadio`, `getCall` | pma-voice |
| voice | `mute` | `mute` | pma-voice |
| voice (client) | `talking` | `isTalking` | pma-voice |
| weather (server) | `read`, `set` | `get`, `set`, `setTime` | every weather resource; nothing without one |
| weather (server) | `time` | `getTime` | all but qbx_weathersync |
| weather (client) | `pause` | `pause` | all |
| appearance | `result` | `open` calls `onDone` | illenium-appearance, fivem-appearance, esx_skin |
| appearance | `reload` | `reload` | illenium-appearance, qb-clothing, esx_skin |
| appearance | `snapshot` | `get`, `set` | illenium-appearance, fivem-appearance, esx_skin |

## In an adapter

An adapter says what it can do in its `caps` table, and the category's file lists the names it knows. A capability an adapter does not name is `false`:

```lua
return {
    caps = { metadata = true, slots = true, stashes = false },
    ...
}
```

An adapter names only capabilities its category knows.
