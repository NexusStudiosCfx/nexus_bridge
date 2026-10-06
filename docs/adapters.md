# Adapters and where every call comes from

The bridge never guesses at another resource. Every export, event, state and table an adapter touches was read somewhere first, and this page says where. If a call here is wrong for the version you run, the line tells you which version it was read from, and the adapter's own file has the notes.

## The three marks

| mark | what it means |
|---|---|
| tested | The adapter ran against the real resource on a real FXServer. What exactly ran is listed under [What ran on a real server](#what-ran-on-a-real-server). |
| source | Written against the published source code of the resource, at the version or commit named. Nobody has run it against the real thing here. |
| docs | The resource is escrowed or paid, so only the vendor's documentation could be read. The most likely kind to need a fix: tell us when one does. |

Every adapter, whatever its mark, keeps the promise of its category: the same answers for every adapter there.

`bridge doctor` in the server console shows the mark of each adapter your server is using.

## Frameworks, inventories and targets

| category | resource | mark | read at | what the adapter calls |
|---|---|---|---|---|
| framework | `qbx_core` | tested | 1.23.0 and [1825a3c](https://github.com/Qbox-project/qbx_core/tree/1825a3c3cf6b5057d6909a44a8fc4444ac3f89d3) (1.24.0) | exports `GetPlayer`, `GetPlayerByCitizenId`, `GetOfflinePlayer`, `GetQBPlayers`, `GetMoney`, `AddMoney`, `RemoveMoney`, `GetJob`, `GetJobs`, `GetDutyCountJob`, `GetMetadata`, `SetMetadata`, `CreateUseableItem`, `Notify`, `SetJob`, `AddPlayerToJob`, `RemovePlayerFromJob`, `SetPlayerPrimaryJob`, `SetJobDuty`, `GetGroupMembers`, `UpsertJobGrade`, `RemoveJobGrade`; events `QBCore:Server:PlayerLoaded`, `QBCore:Server:OnPlayerUnload`, `qbx_core:server:playerLoggedOut`, `QBCore:Server:OnJobUpdate`, `QBCore:Server:SetDuty`, `qbx_core:server:onGroupUpdate`, `QBCore:Server:OnMoneyChange`; client: export `GetPlayerData`, events `QBCore:Client:OnPlayerLoaded`, `QBCore:Client:OnPlayerUnload`, `qbx_core:client:playerLoggedOut`, `QBCore:Player:SetPlayerData`, state `isLoggedIn` |
| framework | `qb-core` | tested | two builds that both call themselves 1.3.0: [9b3cddc](https://github.com/qbcore-fivem/qb-core/tree/9b3cddcce93e5e12cbcf6b47b866b687d32ac7bf) and [36d8986](https://github.com/qbcore-fivem/qb-core/tree/36d8986b4298b3e762c9e799b23241b56eaf78b5) | export `GetCoreObject`; `QBCore.Functions.GetPlayer`, `GetPlayerByCitizenId`, `GetOfflinePlayerByCitizenId`, `GetPlayers`, `GetQBPlayers`, `GetPlayersOnDuty`, `CreateUseableItem`; `Player.Functions.AddMoney`, `RemoveMoney`, `SetJob`, `SetJobDuty`, `SetMetaData`, `Save`; export `UpdateJob`; `QBCore.Shared.Jobs`, `Gangs`; table `players` (`citizenid`, `charinfo`, `job`) for the employees of a job; events `QBCore:Server:PlayerLoaded`, `QBCore:Server:OnPlayerUnload`, `QBCore:Server:OnJobUpdate`, `QBCore:Server:SetDuty`, `QBCore:Server:OnMoneyChange`, `QBCore:Server:UpdateObject`; client: `QBCore.Functions.GetPlayerData`, events `QBCore:Client:OnPlayerLoaded`, `OnPlayerUnload`, `OnPlayerUpdated`, `OnJobUpdate`, `OnGangUpdate`, `SetDuty`, `QBCore:Player:SetPlayerData`, `QBCore:Notify` |
| framework | `es_extended` | tested | ESX Legacy 1.15.2, [ddd71a5](https://github.com/esx-framework/esx_core/tree/ddd71a58f1ea6279d68413fb4a44e0ef34ede2fa) | export `getSharedObject` (event `esx:getSharedObject` on very old cores); `ESX.GetPlayerFromId`, `GetPlayerFromIdentifier`, `GetExtendedPlayers`, `GetJobs`, `RefreshJobs`, `RegisterUsableItem`; `xPlayer.getAccount`, `addAccountMoney`, `removeAccountMoney`, `getJob`, `setJob`, `getName`, `getMeta`, `setMeta`; tables `users` (`identifier`, `job`, `job_grade`, `firstname`, `lastname`) and `job_grades`; events `esx:playerLoaded`, `esx:playerLogout`, `esx:playerDropped`, `esx:setJob`, `esx:addAccountMoney`, `esx:removeAccountMoney`, `esx:setAccountMoney`; client: `ESX.GetPlayerData`, `ESX.IsPlayerLoaded`, events `esx:playerLoaded`, `esx:onPlayerLogout`, `esx:setJob`, `esx:updatePlayerData`, `esx:showNotification` |
| inventory | `ox_inventory` | tested | 2.47.9 ([overextended](https://github.com/overextended/ox_inventory/tree/v2.47.9)) and 2.45.0 ([CommunityOx 89736ce](https://github.com/CommunityOx/ox_inventory/tree/89736ce589f1ff6629779ad3097bbb3c38863595)) | exports `Items`, `GetInventoryItems`, `GetSlot`, `GetItemCount`, `CanCarryItem`, `AddItem`, `RemoveItem`, `SetMetadata`, `ClearInventory`, `RegisterStash`, `forceOpenInventory`; event `ox_inventory:usedItem`; convar `inventory:imagepath`; client: exports `Items`, `GetPlayerItems`, `GetItemCount` |
| inventory | `qb-inventory` | tested | 2.2.3, [dc3d07f](https://github.com/qbcore-framework/qb-inventory/tree/dc3d07fc60139de569df38c5ac178ed4cada4577). Version 1.x is refused with a message | exports `GetInventory`, `GetSlots`, `CanAddItem`, `AddItem`, `RemoveItem`, `SetItemData`, `ClearInventory`, `CreateInventory`, `OpenInventory`, `ClearStash`; `QBCore.Shared.Items`; the player's items from the QBCore player; client: `QBCore.Functions.GetPlayerData`, event `QBCore:Client:UpdateObject` |
| inventory | `es_extended` | tested | the plain inventory inside ESX Legacy 1.15.2 | `ESX.GetItems` (or `ESX.Items`); `xPlayer.getInventory`, `getInventoryItem`, `canCarryItem`, `addInventoryItem`, `removeInventoryItem`; client: `ESX.GetPlayerData().inventory` |
| target | `ox_target` | source | 1.18.1, [overextended/ox_target](https://github.com/overextended/ox_target) | exports `addSphereZone`, `addBoxZone`, `removeZone`, `addEntity`, `addLocalEntity`, `removeEntity`, `removeLocalEntity`, `addModel`, `removeModel`, `addGlobalPlayer`, `addGlobalVehicle`, `addGlobalPed`, `addGlobalObject` and their `removeGlobal...`, `disableTargeting` |
| target | `qb-target` | source | 5.5.0, [qbcore-framework/qb-target](https://github.com/qbcore-framework/qb-target) | exports `AddCircleZone`, `AddBoxZone`, `RemoveZone`, `AddTargetEntity`, `RemoveTargetEntity`, `AddTargetModel`, `RemoveTargetModel`, `AddGlobalPlayer`, `AddGlobalVehicle`, `AddGlobalPed`, `AddGlobalObject` and their `RemoveGlobal...`, `AllowTargeting` |
| target | `sleepless_interact` | source | 2.4.1, [a6c4cb8](https://github.com/Sleepless-Development/sleepless_interact/tree/a6c4cb8d0318b4d91ce1dd223cc1c16aa599a073) | exports `addCoords`, `removeCoords`, `addEntity`, `addLocalEntity`, `removeEntity`, `removeLocalEntity`, `addModel`, `removeModel`, `addGlobalPlayer`, `addGlobalVehicle`, `addGlobalPed`, `addGlobalObject` and their `removeGlobal...`. It has points only: a box becomes a point |
| target | (none) | built in | `prompt` | No target resource: the bridge's own key prompt (`client/prompt.lua`). World points show "press E", entities use a key that can be rebound |

## Notifications

A notification resource wins over what the framework would show by itself. All of these are client calls: `Bridge.notify.send` on the server hands the message to the bridge's client half.

| category | resource | mark | read at | what the adapter calls |
|---|---|---|---|---|
| notify | `okokNotify` | docs | [vendor documentation](https://docs.okokscripts.io/scripts/okoknotify), 2026-10-06 | export `Alert(title, message, time, type, playSound)` |
| notify | `wasabi_notify` | docs | [vendor documentation](https://docs.wasabiscripts.com/core-ui-series/wasabi-notify/exports-events), 2026-10-06 | export `notify(title, message, time, type)` |
| notify | `lation_ui` | docs | [vendor documentation](https://lationscripts.com/docs/modern-ui/components/notify), 2026-10-06 | export `notify({ title, message, type, duration })` |
| notify | `brutal_notify` | docs | [vendor documentation](https://docs.brutalscripts.com/site/scripts/notify/exports-triggers), 2026-10-06 | export `SendAlert(title, message, time, type, sound)` |
| notify | `t-notify` | source | 2.1.0, [c5f5529](https://github.com/TasoOneAsia/t-notify/tree/c5f552952efd6fabc41672a57595f0aa9e8a61d3) | exports `Custom({ style, title, message, duration })` and `Alert({ style, message, duration })` |
| notify | `mythic_notify` | source | 1.0.3, [7989c9f](https://github.com/JayMontana36/mythic_notify/tree/7989c9f89421954e9f7b8152d52f7871e9cb0bda) | export `DoCustomHudText(type, text, length)`. It renders HTML, so the text is escaped |
| notify | `pNotify` | source | [d8c1350](https://github.com/Nick78111/pNotify/tree/d8c135071cd82c5ae48329786b1e5d17a30fcb21) | export `SendNotification({ text, type, timeout })`. It renders HTML, so the text is escaped |
| notify | `qbx_core` | source | 1.23.0 | The framework's own notification, through `Bridge.framework.notify`: export `Notify` |
| notify | `qb-core` | source | 1.3.0 | The framework's own notification: event `QBCore:Notify` |
| notify | `es_extended` | source | 1.15.2 | The framework's own notification: event `esx:showNotification` |
| notify | `ox_lib` | source | 3.39.0, [overextended/ox_lib](https://github.com/overextended/ox_lib) | export `notify({ title, description, type, duration })`. Asked after the frameworks: ox_lib runs on most servers as a library, also on the ones that show notifications with something else |
| notify | (none) | built in | `native` | The game's own feed: `BeginTextCommandThefeedPost`, text in pieces of 99 characters, `EndTextCommandThefeedPostTicker` |

## Society money

| category | resource | mark | read at | what the adapter calls |
|---|---|---|---|---|
| banking | `Renewed-Banking` | tested | 2.1.4, [e4c3c63](https://github.com/Renewed-Scripts/Renewed-Banking/tree/e4c3c63fdec03a6e40a964c11a6d1908f05baec3) | exports `getAccountMoney`, `addAccountMoney`, `removeAccountMoney`, `handleTransaction`. `CreateJobAccount` raises in this release, so the adapter does not offer `ensure` |
| banking | `qb-banking` | source | 2.0.0, [b2dee4e](https://github.com/qbcore-framework/qb-banking/tree/b2dee4eae9eb9374f6adb303d9bf31cb1ddc3be8) | exports `GetAccount`, `AddMoney`, `RemoveMoney`, `CreateJobAccount`. It lets an account go negative, so the balance is checked first |
| banking | `esx_addonaccount` | source | 1.1 of ESX Legacy Addons 1.15.0, [ccda737](https://github.com/esx-framework/ESX-Legacy-Addons/tree/ccda737f7d4f73d224fab2097bee5083afd4dd4e) | exports `GetSharedAccount`, `AddSharedAccount` (event `esx_addonaccount:getSharedAccount` on releases without the export); `account.addMoney`, `account.removeMoney`. The account of a job is `society_<job>` |

## Owned vehicles and keys

QBCore and ESX have no function that says who owns a plate. Their own garage and vehicle shop read and write a table, and so do these two adapters, with the statements those resources use. A database without that table gets a line in the console, once, and "nobody owns it" from then on.

| category | resource | mark | read at | what the adapter calls |
|---|---|---|---|---|
| vehicles | `qbx_vehicles` | tested | 1.4.2, [5712829](https://github.com/Qbox-project/qbx_vehicles/tree/571282900c229a5caf75b1aff679ba4ec0456eb0) | exports `GetVehicleIdByPlate`, `GetPlayerVehicle`, `GetPlayerVehicles`, `CreatePlayerVehicle`, `SetPlayerVehicleOwner`, `DeletePlayerVehicles`; the column `plate` of `player_vehicles` for a row whose stored properties carry no plate |
| vehicles | `qb-core` | tested | table `player_vehicles` as in [qb-garages f22a09f](https://github.com/qbcore-fivem/qb-garages/tree/f22a09f2e8c0d887e8b167e171bdbb24fdd48f9e) (2.0.0) and [qb-vehicleshop e865297](https://github.com/qbcore-fivem/qb-vehicleshop/tree/e8652970aca3324d2a18a440f3d3871715338da8) (2.1.0) | columns `license`, `citizenid`, `vehicle`, `hash`, `mods`, `plate`, `garage`, `state`; `players.license` for the new owner |
| vehicles | `es_extended` | tested | table `owned_vehicles` as in ESX Legacy 1.15.2 (`[SQL]/legacy.sql`) and its addons esx_vehicleshop and esx_garage, [ccda737](https://github.com/esx-framework/ESX-Legacy-Addons/tree/ccda737f7d4f73d224fab2097bee5083afd4dd4e) | columns `owner`, `plate`, `vehicle`, `stored`, and `parking` where it exists; `users.identifier`; `ESX.GetExtendedVehicleFromPlate(plate):setOwner(owner)` for a vehicle the core spawned |
| keys | `qbx_vehiclekeys` | source | 1.0.3, [898783c](https://github.com/Qbox-project/qbx_vehiclekeys/tree/898783c67611a1ae529a3e2f6c850361aef7e4cb) | exports `GiveKeys(source, vehicle, skipNotification)`, `RemoveKeys`, `HasKeys`. By entity |
| keys | `qb-vehiclekeys` | source | 1.6.0, [36b54c2](https://github.com/qbcore-framework/qb-vehiclekeys/tree/36b54c2dc20f591eb613be22d892e982bf87fbbf) | exports `GiveKeys(source, plate)`, `RemoveKeys`, `HasKeys`. By plate |
| keys | `Renewed-Vehiclekeys` | docs | [vendor documentation](https://renewed.dev/key/exports), 2026-10-06 | exports `addKey(source, plate)`, `removeKey`, `hasKey` |
| keys | `MrNewbVehicleKeys` | docs | [vendor documentation](https://mrnewbs-scrips.gitbook.io/guide/vehiclekeys/vehicle-keys-exports/server-exports), 2026-10-06 | exports `GiveKeysByPlate(source, plate)`, `RemoveKeysByPlate`, `HasKeysByPlate` |
| keys | `wasabi_carlock` | docs | [vendor documentation](https://docs.wasabiscripts.com/advanced-series/wasabi-carlock/exports), 2026-10-06 | exports `GiveKey(source, plate)`, `RemoveKey`, `HasKey` |
| keys | `vehicles_keys` | docs | [vendor documentation](https://documentation.jaksam-scripts.com/vehicles-keys/), 2026-10-06 | exports `giveVehicleKeysToPlayerId(playerId, plate, 'temporary')`, `removeKeysFromPlayerId`, `isPlayerOwnerOfVehiclePlate` |
| keys | `cd_garage` | docs | [vendor documentation](https://docs.codesign.pro/paid-scripts/garage/developer-api/events), 2026-10-06 | client events `cd_garage:AddKeys (plate)` and `cd_garage:RemoveKeys (plate)`, sent to the player. The server cannot ask whether somebody has a key |

## Fuel, dispatch and phones

| category | resource | mark | read at | what the adapter calls |
|---|---|---|---|---|
| fuel | `ox_fuel` | source | 1.5.4 ([overextended 84f93ba](https://github.com/overextended/ox_fuel/tree/84f93ba2a3e24a663514c65cb9b3965c703ffed1)) and 1.5.2 ([CommunityOx 8d37f97](https://github.com/CommunityOx/ox_fuel/tree/8d37f9747952f651b6bdf3bbad56bcb436e810c2)) | No exports exist: the vehicle state `fuel`, written by the server with `Entity(vehicle).state:set('fuel', level, true)`, and `SetVehicleFuelLevel` on the client that drives |
| fuel | `Renewed-Fuel` | docs | [vendor documentation](https://renewed.dev/fuel/exports), 2026-10-06 | the vehicle state `fuel` to read; export `SetFuel(vehicle, amount)` on the client and on the server |
| fuel | `cdn-fuel` | source | 2.1.9, [edb6f55](https://github.com/CodineDev/cdn-fuel/tree/edb6f5591f20803c844379eca4c3d78697e10cb1) | client exports `GetFuel(vehicle)`, `SetFuel(vehicle, level)` |
| fuel | `ps-fuel` | source | 1.0.2, [1f5e21e](https://github.com/Project-Sloth/ps-fuel/tree/1f5e21e995776706f918daef180f338f658f3e37) | client exports `GetFuel`, `SetFuel` |
| fuel | `qb-fuel` | source | 0.0.4, [2e51aa3](https://github.com/qbcore-framework/qb-fuel/tree/2e51aa319af37ae3d8d9d36c8b1c298125262c61) | client exports `GetFuel`, `SetFuel` |
| fuel | `lc_fuel` | source | 1.2.4, [49d8864](https://github.com/LeonardoSoares98/lc_fuel/tree/49d8864aa91e98f20ad351a8c98d9595c4741438) | client exports `GetFuel`, `SetFuel` |
| fuel | `LegacyFuel` | source | 1.3, [a168ec5](https://github.com/InZidiuZ/LegacyFuel/tree/a168ec5b454fc0dcda9804390ba855138dcac2b6) | client exports `GetFuel`, `SetFuel`. One adapter file serves these five; `Config.adapters.fuel` may name any of them |
| fuel | `qs-fuelstations` | docs | [vendor documentation](https://www.quasar-store.com/docs/fuel-stations/commands-and-exports), 2026-10-06 | client exports `GetFuel(vehicle)`, `SetFuel(vehicle, fuelLevel)`, in percent |
| fuel | `BigDaddy-Fuel` | docs | [vendor wiki](https://wiki.bigdaddyscripts.com/documentation/fuel/), 2026-10-06 | client exports `GetFuel(vehicle)`, `SetFuel(vehicle, fuelLevel)`, 0 to 100 |
| fuel | `rcore_fuel` | docs | [vendor documentation](https://documentation.rcore.cz/paid-resources/rcore_fuel/api/client), 2026-10-06 | client exports `GetVehicleFuelPercentage(vehicle)`, `SetVehicleFuel(vehicle, percentage)` |
| fuel | `ti_fuel` | docs | [vendor documentation](https://tebit.gitbook.io/tebit-wiki/resources/fuel), 2026-10-06 | client exports `getFuel(vehicle)` (level and fuel type), `setFuel(vehicle, level, type)` |
| fuel | (none) | built in | `native` | No fuel resource: `GetVehicleFuelLevel`, `SetVehicleFuelLevel` |
| dispatch | `ps-dispatch` | source | 3.0.0 ([d488316](https://github.com/Project-Sloth/ps-dispatch/tree/d488316ae7f579740c93f8bd873fc552a48a7038)), 2.2.2 and 1.4.3 | client export `CustomAlert(data)`. It takes alerts from a client only, so the bridge raises it on one |
| dispatch | `cd_dispatch` | docs | [vendor documentation](https://docs.codesign.pro/paid-scripts/dispatch), 2026-10-06 | client event `cd_dispatch:AddNotification`, sent to everybody. `blip.time` in minutes |
| dispatch | `qs-dispatch` | docs | [vendor documentation](https://www.quasar-store.com/docs/dispatch-and-mdt/create-dispatch-call), 2026-10-06 | server event `qs-dispatch:server:CreateDispatchCall`. `blip.time` in milliseconds |
| dispatch | `core_dispatch` | docs | [vendor documentation](https://docs.c8re.store/core-dispatch/exports), 2026-10-06 | server export `sendAlert(data)` |
| dispatch | `rcore_dispatch` | docs | [vendor documentation](https://documentation.rcore.cz/paid-resources/rcore_dispatch/add-alerts), 2026-10-06 | server event `rcore_dispatch:server:sendAlert`. `blip_time` in seconds |
| dispatch | `tk_dispatch` | docs | [vendor documentation](https://tk-scripts.gitbook.io/docs/tk_dispatch), 2026-10-06 | server export `addCall(data)`. `removeTime` in milliseconds |
| dispatch | `codem-dispatchv2` | docs | [vendor documentation](https://codem.gitbook.io/codem-documentation/blvck/essentials/dispatch-v2/events-and-exports), 2026-10-06 | server export `SendDispatchAlert(data)`. `blip.length` in minutes |
| dispatch | `origen_police` | docs | [vendor documentation](https://docs.origennetwork.com/scripts/origen_police/exports), 2026-10-06 | server export `SendAlert({ coords, title, type, message, job })`, once for each job |
| dispatch | `lb-tablet` | tested | 1.7.0, [vendor documentation](https://docs.lbscripts.com/tablet/script-integration/server-exports/) and its open files | server export `AddDispatch(options)`. `time` in seconds |
| dispatch | (none) | built in | `builtin` | No dispatch resource: a notification (`Bridge.notify`) and a blip for whoever is on duty in the job (`Bridge.framework.getOnDuty`) |
| phone | `lb-phone` | docs | 2.8.0, [vendor documentation](https://docs.lbscripts.com/phone/exports/server-exports/) and its open files | server exports `GetEquippedPhoneNumber`, `GetEmailAddress`, `SendMail`, `SendNotification`; client export `IsOpen` |
| phone | `yseries` | docs | [vendor documentation](https://www.teamsgg.dev/docs/paid-scripts/phone), 2026-10-06 | server exports `GetPhoneNumberBySourceId`, `GetPhoneNumberByIdentifier`, `SendNotification(notification, toType, to)`, `SendMail(email, receiverType, receiver)`; client export `IsOpen` |
| phone | `gksphone` | docs | GKSPHONE V2, [vendor documentation](https://docs.gkshop.org/gksphone-v2/exports-and-events), 2026-10-06 | server exports `GetPhoneBySource`, `sendNotification`, `SendNewMail`, `SendNewMailOffline`; client export `isPhoneOpen` |
| phone | `17mov_Phone` | docs | [vendor documentation](https://docs.17movement.net/phone/exports), 2026-10-06 | server exports `GetNumberFromPlayer`, `GetNumberFromIdentifier`, `SendNotificationToSrc`, `Email_SendEmailBySrc`; client export `IsPhoneOpen` |
| phone | `roadphone` | docs | RoadPhone and RoadPhone Pro, [vendor documentation](https://docs.roadshop.org), 2026-10-06 | server exports `getNumberFromIdentifier`, `sendMailOffline`; client event `roadphone:sendNotification`; client export `isPhoneOpen` |
| phone | `npwd` | source | 3.16.0, [0f08eeb](https://github.com/project-error/npwd/tree/0f08eebbb628005aef68528a9268cd360bb163e2) | server export `getPlayerData({ source })`; client exports `createSystemNotification`, `isPhoneVisible`. No mail app |
| phone | `qb-phone` | source | 1.5.0, [333e813](https://github.com/qbcore-framework/qb-phone/tree/333e8132359b1c50c31c2bc6db8e8a64db6c93f6); the Renewed fork keeps both calls | client event `qb-phone:client:CustomNotification`; server export `sendNewMailToOffline`; the number is `charinfo.phone` of the QBCore character |

## Medical, voice, weather, clothing and logs

| category | resource | mark | read at | what the adapter calls |
|---|---|---|---|---|
| medical | `nexus_ems` | source | 1.0.0, the exports and events its README documents | server exports `IsDown`, `Revive`, `Heal(src, 'full')`; server events `nexus_ems:playerDown`, `nexus_ems:playerUp`; client export `IsDown` |
| medical | `wasabi_ambulance_v2` | docs | [vendor documentation](https://docs.wasabiscripts.com/advanced-series/wasabi-ambulance-v2/), 2026-10-06 | player states `wasabi:deathState` and `isDead`; server exports `RevivePlayer`, `ApplyHeal`; client export `isPlayerDead` |
| medical | `wasabi_ambulance` | docs | [vendor documentation](https://docs.wasabiscripts.com/advanced-series/wasabi-ambulance-v1/), 2026-10-06 | player state `dead` ('dead' or 'laststand'); server export `RevivePlayer`. No heal |
| medical | `ars_ambulancejob` | source | 1.0.4, [36046a7](https://github.com/Arius-Scripts/ars_ambulancejob/tree/36046a795d588fd0e2dfb16cd02d2ba5286bb726) | player state `dead`; client event `ars_ambulancejob:healPlayer` with `{ revive = true }` or `{ heal = true }` |
| medical | `qbx_medical` | source | 1.0.0, [b5649d2](https://github.com/Qbox-project/qbx_medical/tree/b5649d28c9faa162bb4c524134688052ea6d8c15) | player state `isDead`; server exports `Revive`, `Heal` |
| medical | `qb-ambulancejob` | source | 1.2.4, [19bb190](https://github.com/qbcore-framework/qb-ambulancejob/tree/19bb190d7c41e6b79d836a45d7498bd3762d0bd4) | metadata `isdead` and `inlaststand`; server events `hospital:server:SetDeathStatus`, `hospital:server:SetLaststandStatus` (listened to); client events `hospital:client:Revive`, `hospital:client:HealInjuries` |
| medical | `esx_ambulancejob` | source | 1.0.2 of ESX Legacy Addons, [ccda737](https://github.com/esx-framework/ESX-Legacy-Addons/tree/ccda737f7d4f73d224fab2097bee5083afd4dd4e) | player state `isDead`; client events `esx_ambulancejob:revive`, `esx_ambulancejob:heal ('big', true)` |
| voice | `pma-voice` | source | 7.0.1, [6c9d96e](https://github.com/AvarianKnight/pma-voice/tree/6c9d96ed7a02e30912f1a0ce92629bf9afbbca8c) | server exports `setPlayerRadio`, `setPlayerCall`; player states `radioChannel`, `callChannel`; natives `MumbleSetPlayerMuted`, `MumbleIsPlayerTalking` |
| voice | `saltychat` | source | 1.2.4, [2e816b0](https://github.com/SaltyHub-net/saltychat-fivem/tree/2e816b0ce56479ee55e29069747160d27fa2e405) | server exports `SetPlayerRadioChannel`, `RemovePlayerRadioChannel`, `AddPlayerToCall`, `RemovePlayerFromCall` |
| weather | `Renewed-Weathersync` | source | 1.1.8, [d36bf7c](https://github.com/Renewed-Scripts/Renewed-Weathersync/tree/d36bf7ca1e95a1facef38e354de67dfcd4db2496) | `GlobalState.weather`, `GlobalState.currentTime` (read and written); player state `syncWeather` |
| weather | `cd_easytime` | source | 2.0.5, [174ddc1](https://github.com/dsheedes/cd_easytime/tree/174ddc1e823d1aad54361988ea54c302c08b980a) | server exports `GetAllData`, `SetWeather`, `SetTime`; client event `cd_easytime:PauseSync` |
| weather | `qb-weathersync` | source | 2.3.0, [f7ae442](https://github.com/qbcore-framework/qb-weathersync/tree/f7ae442137ff0cd2e62fee75e2f963465c5429be) | server exports `getWeatherState`, `getTime`, `setWeather`, `setTime`; client events `qb-weathersync:client:DisableSync`, `qb-weathersync:client:EnableSync` |
| weather | `qbx_weathersync` | source | 2.0.0 (archived), [2edeb31](https://github.com/Qbox-project/qbx_weathersync/tree/2edeb3170f301ae0e170ab2e8cf5036a1c38ed5a) | server exports `getWeatherState`, `setWeather`, `setTime`; the client events of qb-weathersync, whose names it kept |
| weather | (none) | built in | `native` | No weather resource. The client half of every weather adapter reads the game: `GetPrevWeatherTypeHashName`, `GetRainLevel`, `GetClockHours`, `GetClockMinutes` |
| appearance | `illenium-appearance` | source | [1b003ec](https://github.com/iLLeniumStudios/illenium-appearance/tree/1b003ec169b15f145d519438ba7c6454bf746f27) and release 5.7.0 | client exports `startPlayerCustomization`, `getPedAppearance`, `setPlayerAppearance`; server event `illenium-appearance:server:saveAppearance`; client event `illenium-appearance:client:reloadSkin` |
| appearance | `fivem-appearance` | source | 1.3.0, [b06da32](https://github.com/pedr0fontoura/fivem-appearance/tree/b06da32881ed49042909b38a778c10dd9bd9eaed) | client exports `startPlayerCustomization`, `getPedAppearance`, `setPlayerAppearance`. It stores nothing, so there is no reload |
| appearance | `qb-clothing` | source | 1.2.0, [8cca400](https://github.com/qbcore-framework/qb-clothing/tree/8cca4009dd473ab30c30e443ecad50830b816ed7) | client event `qb-clothing:client:openMenu`; client export `reloadSkin(health)` |
| appearance | `esx_skin` | source | esx_skin and skinchanger 1.15.2, [ddd71a5](https://github.com/esx-framework/esx_core/tree/ddd71a58f1ea6279d68413fb4a44e0ef34ede2fa) | client events `esx_skin:openSaveableMenu`, `esx_skin:openSaveableRestrictedMenu`, `skinchanger:getSkin`, `skinchanger:loadSkin`; ESX server callback `esx_skin:getPlayerSkin` |
| log | (none) | built in | `webhook` | Discord webhooks from `Config.log` in config.lua: `PerformHttpRequest`, ten embeds to a request |
| log | `fmsdk` | source | 3.2.0, [0130320](https://github.com/fivemanage/sdk/tree/013032014577f8750376fbf09354544f2a8a74d1) | server export `LogMessage(level, message, metadata)` |
| log | `fm-logs` | source | 1.0.3, [fb92343](https://github.com/FiveMerr/fm-logs/tree/fb9234373bee63104f33c8f9ae076b9559967bc2) | server export `createLog(data)` |
| log | `qb-smallresources` | source | 1.5.0, [e69a957](https://github.com/qbcore-framework/qb-smallresources/tree/e69a95786ef29e53d962e4e0ec57eef36e195561) | server event `qb-log:server:CreateLog`. Only when config.lua names it |
| log | `es_extended` | source | ESX Legacy 1.15.2 | `ESX.DiscordLogFields(name, title, color, fields)`. Only when config.lua names it |

## What ran on a real server

"Tested" means it ran on a real FXServer with the real resource, in a test server with no player on it. That is a good deal less than everything, so here is exactly what ran. The servers were Qbox, QBCore, ESX and ESX with ox_inventory.

| adapter | what ran against the real resource | what did not run there |
|---|---|---|
| framework: `qbx_core` 1.23.0, `qb-core` 1.3.0 | the job list and grades; money of a character that is offline (added, refused beyond the balance, removed, compared with the database each time); hiring and firing a character that is offline; the employees of a job; making, changing and removing a grade | everything about a player who is online: identity, live money, duty, the events |
| framework: `es_extended` 1.15.2 | the job list and grades; hiring and firing a character that is offline; the employees of a job; making, changing and removing a grade in `job_grades` | the same, and ESX cannot reach the money of somebody offline at all |
| inventory: `ox_inventory` 2.47.9 | item definitions; a stash made, filled, read, a slot removed, emptied; refusing an unknown item | a player's own inventory, usable items |
| inventory: `qb-inventory` 2.2.3 | the same on its stashes, with unique items | a player's own inventory, usable items |
| inventory: `es_extended` 1.15.2 | item definitions, read after ESX finished loading them | giving and taking: the plain ESX inventory only exists on a player |
| banking: `Renewed-Banking` 2.1.4 | the balance of a job account, money added, a removal beyond the balance refused, money removed | nothing else to see |
| vehicles: `qbx_vehicles` 1.4.2 | a vehicle given to a throwaway character, read back, listed, a taken plate refused, the owner changed, a change to nobody refused, removed | nothing else to see |
| vehicles: `qb-core`, `es_extended` | the same against a real MySQL table. The table was created from the schema the garage resources publish, because the test servers do not run a garage: qb-garages and esx_garage themselves were not running | a vehicle that ESX's core spawned and tracks |
| dispatch: `lb-tablet` 1.7.0 | one alert accepted by `AddDispatch` (it answered an id) | how it looks on a tablet: nobody was on duty |

Also run on the real resources without earning the mark, because nothing could be delivered without a player: `lb-phone` 2.8.0 (the phone number of nobody, an e-mail to nobody) and `qbx_medical` 1.0.0 (the bridge listening for its player state).

The adapters marked "source" and "docs" that most servers run every day are the first candidates for "tested" once somebody runs the self-test with a player online: `set nexus_bridge_selftest 1`, then `bridge selftest`.

## Wanted

Resources that were looked at and have no adapter yet. Each has a reason, and most need one thing: somebody who runs the resource and can confirm what a call really does. A pull request with an adapter, a stand-in and the sources of its calls is welcome (see [adding-an-adapter.md](adding-an-adapter.md)).

| category | resource | why not yet |
|---|---|---|
| framework | ox_core, ND_Core | read, not written: no test server to run them on |
| framework | ESX before 1.9 | the adapter is written for ESX Legacy; older cores lack functions it calls |
| inventory | qb-inventory 1.x, ps-inventory | the generation that keeps items inside qb-core. The adapter refuses it with a message instead of half working |
| inventory | qs-inventory, tgiann-inventory, origen_inventory, codem-inventory, core_inventory, ak47_inventory | documentation only, and it leaves open what a failed add or a partial removal answers, which is the part an economy depends on |
| target | interact | read; not written yet |
| target | qtarget, meta_target | no longer maintained: only that was checked, no call of theirs was read |
| notify | ps-ui | its notification is tied to its own menus |
| banking | okokBanking, fd_banking, wasabi_banking, tgg-banking, snipe-banking, kartik-banking, crm-banking, RxBanking, ps-banking | their documentation does not say whether a removal refuses when the balance is short, or what it answers. A bank adapter that guesses loses money |
| banking | the old qb-management, esx_society | replaced by qb-banking and esx_addonaccount, which are covered |
| keys | qs-vehiclekeys, ti_vehicleKeys, t1ger_keys | want the vehicle's model or display name next to the plate |
| keys | ak47_vehiclekeys, mk_vehiclekeys, mono_carkeys, tgiann-hotwire, okokGarage | documented; not written yet |
| keys | dusa_vehiclekeys, F_RealCarKeysSystem, sna-vehiclekeys | no documented way for the server to give a chosen player a key |
| fuel | x-fuel, okokGasStation | the documentation does not say on which side the exports run or what the vehicle argument is |
| fuel | esx-sna-fuel | archived, and published without a licence |
| dispatch | cd_dispatch3d, kartik-mdt, redutzu-mdt, piotreq_gpt, p_mdt, dusa_dispatch, l2s-dispatch, aty_dispatch, fd_dispatch, wasabi_mdt, bub-mdt, ND_MDT, gks-tablet, linden_outlawalert | documented or read; not written yet. Several answer to another dispatch's names, so each needs care |
| dispatch | codem-dispatch (the first one) | its one documented call has no place for coordinates |
| phone | okokPhone | the unit of a notification's duration and the names of its apps are not documented |
| phone | high-phone, jpr-phonesystem | documented; not written yet |
| phone | qs-smartphone, qs-smartphone-pro | two generations with different calls under one resource name, one of them only in archived documentation |
| medical | osp_ambulance, ak47_ambulancejob, brutal_ambulancejob, tk_ambulancejob, p_ambulancejob, visn_are, ND_Ambulance, randol_medical | documented; not written yet |
| voice | mumble-voip | archived; pma-voice took its place and kept most of its export names |
| weather | av_weather | weather by zone: there is no one weather to read or set |
| weather | vSync | has no export and no event to set anything, only chat commands |
| appearance | rcore_clothing, bl_appearance, tgiann-clothing, crm-appearance, codem-appearance, dx_clothing, onex-creation, 17mov_CharacterSystem | documented; not written yet |
| log | ox_lib's logger | it is part of the library a resource includes, and the bridge includes no library |
