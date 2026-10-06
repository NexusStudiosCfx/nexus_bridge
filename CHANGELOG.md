# Changelog

Versions follow semantic versioning. A resource says what it needs with `Bridge.require('>=1.0')`: a new function is a minor version, and nothing a resource calls changes its meaning or its answer within a major version.

## 1.0.0

The first release.

### The bridge

- One global, `Bridge`, from `shared_script '@nexus_bridge/init.lua'`. Modules are read on first use, in the resource's own Lua state; every function is also an export of `nexus_bridge`.
- Detection for every category, with `config.lua` to name an adapter, use a custom one or switch a category off. Decisions are made again when a resource starts or stops, and clients follow.
- A category nothing serves answers with harmless defaults and says so once.
- `supports(feature)` on every category.
- Events that are the same on every framework: `playerLoaded`, `playerUnloaded`, `jobChanged`, `moneyChanged`, `itemUsed`, `playerDied`, `playerRevived`.
- Custom adapters in `bridge/custom/`, and `RegisterAdapter` for a resource that brings its own.
- `Bridge.version` and `Bridge.require(range)`.
- `bridge doctor`, `bridge selftest` (behind `set nexus_bridge_selftest 1`), `bridge version`, and an optional check for a newer release.
- The bridge can be restarted under running resources.

### Categories and adapters

- framework: qbx_core, qb-core, es_extended, including job management (hire, fire, duty, employees, grades).
- inventory: ox_inventory, qb-inventory 2.x, the ESX inventory.
- target: ox_target, qb-target, sleepless_interact, and a key prompt for servers without one.
- notify: okokNotify, wasabi_notify, lation_ui, brutal_notify, t-notify, mythic_notify, pNotify, ox_lib, the framework's own, the game's feed.
- banking: Renewed-Banking, qb-banking, esx_addonaccount.
- vehicles: qbx_vehicles, and the vehicle tables of QBCore and ESX.
- keys: qbx_vehiclekeys, qb-vehiclekeys, Renewed-Vehiclekeys, MrNewbVehicleKeys, wasabi_carlock, vehicles_keys, cd_garage.
- fuel: ox_fuel, Renewed-Fuel, LegacyFuel, cdn-fuel, ps-fuel, qb-fuel, lc_fuel, qs-fuelstations, BigDaddy-Fuel, rcore_fuel, ti_fuel, and the game's own level.
- dispatch: ps-dispatch, cd_dispatch, qs-dispatch, core_dispatch, rcore_dispatch, tk_dispatch, codem-dispatchv2, origen_police, lb-tablet, and an alert of its own.
- phone: lb-phone, yseries, gksphone, 17mov_Phone, roadphone, npwd, qb-phone.
- medical: nexus_ems, wasabi_ambulance, wasabi_ambulance_v2, ars_ambulancejob, qbx_medical, qb-ambulancejob, esx_ambulancejob.
- voice: pma-voice, saltychat.
- weather: Renewed-Weathersync, cd_easytime, qb-weathersync, qbx_weathersync.
- appearance: illenium-appearance, fivem-appearance, qb-clothing, esx_skin.
- log: Discord webhooks, fmsdk, fm-logs, qb-smallresources, ESX.

Each is marked tested, source or docs in `docs/adapters.md`, with every call it makes and where that was read.

### Utilities

- `Bridge.permission`: rules by ace, job, grade, gang, boss and duty.
- `Bridge.cooldown`: for everybody or per character, surviving restarts.
- `Bridge.ratelimit`: a limit and a lock for events a client can trigger.
- `Bridge.db`: oxmysql without its library, and migrations.
- `Bridge.format`: numbers and money in the server's format.
- `Bridge.locale`: a resource's texts in the server's language.
- `Bridge.point`, `Bridge.ped`: places and peds that cost nothing while the player is elsewhere.
- `Bridge.placer`: setting an object down with a preview, and settling a new object on the ground.

### Proof

- Started on Qbox, QBCore, ESX and ESX with ox_inventory with `examples/bridge_test`.
- `examples/nexus_shop`: a real resource moved onto the bridge.
