fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'nexus_bridge'
author 'Nexus Studios'
description 'One bridge to frameworks, inventories, targets and the rest. Nexus Studios resources are built on it.'
version '1.0.2'
repository 'https://github.com/NexusStudiosCfx/nexus_bridge'
license 'MIT'

-- The bridge runs its own loader: its exports and events come from the same modules that
-- other resources load.
shared_scripts {
    'shared/registry.lua',
    'init.lua',
}

server_scripts {
    'config.lua',
    'server/resolve.lua',
    'shared/selftest.lua',
    'shared/doctor.lua',
    'shared/hub.lua',
    'server/update.lua',
}

client_scripts {
    'client/prompt.lua',
    'shared/selftest.lua',
    'shared/doctor.lua',
    'shared/hub.lua',
}

-- What a client may read. The server halves in bridge/ are read from disk and never sent.
-- Every file is named: a pattern that reaches two folders deep is not something every
-- server build reads the same way, and a client half that does not arrive fails quietly.
-- A client or shared file in bridge/ that is missing here never reaches a client.
files {
    'init.lua',
    -- A server owner's own adapters: bridge/custom/<module>/client.lua
    'bridge/custom/**/client.lua',
    'bridge/custom/**/shared.lua',
    'bridge/appearance/client.lua',
    'bridge/dispatch/client.lua',
    'bridge/format/shared.lua',
    'bridge/framework/client.lua',
    'bridge/fuel/client.lua',
    'bridge/inventory/client.lua',
    'bridge/locale/shared.lua',
    'bridge/medical/client.lua',
    'bridge/notify/client.lua',
    'bridge/ped/client.lua',
    'bridge/phone/client.lua',
    'bridge/placer/client.lua',
    'bridge/point/client.lua',
    'bridge/target/client.lua',
    'bridge/voice/client.lua',
    'bridge/weather/client.lua',
    'bridge/appearance/esx_skin/client.lua',
    'bridge/appearance/fivem-appearance/client.lua',
    'bridge/appearance/illenium-appearance/client.lua',
    'bridge/appearance/qb-clothing/client.lua',
    'bridge/dispatch/builtin/client.lua',
    'bridge/dispatch/ps-dispatch/client.lua',
    'bridge/framework/es_extended/client.lua',
    'bridge/framework/qb-core/client.lua',
    'bridge/framework/qbx_core/client.lua',
    'bridge/fuel/BigDaddy-Fuel/client.lua',
    'bridge/fuel/LegacyFuel/client.lua',
    'bridge/fuel/Renewed-Fuel/client.lua',
    'bridge/fuel/native/client.lua',
    'bridge/fuel/ox_fuel/client.lua',
    'bridge/fuel/qs-fuelstations/client.lua',
    'bridge/fuel/rcore_fuel/client.lua',
    'bridge/fuel/ti_fuel/client.lua',
    'bridge/inventory/es_extended/client.lua',
    'bridge/inventory/ox_inventory/client.lua',
    'bridge/inventory/qb-inventory/client.lua',
    'bridge/medical/ars_ambulancejob/client.lua',
    'bridge/medical/esx_ambulancejob/client.lua',
    'bridge/medical/nexus_ems/client.lua',
    'bridge/medical/qb-ambulancejob/client.lua',
    'bridge/medical/qbx_medical/client.lua',
    'bridge/medical/wasabi_ambulance/client.lua',
    'bridge/medical/wasabi_ambulance_v2/client.lua',
    'bridge/notify/brutal_notify/client.lua',
    'bridge/notify/framework/client.lua',
    'bridge/notify/lation_ui/client.lua',
    'bridge/notify/mythic_notify/client.lua',
    'bridge/notify/native/client.lua',
    'bridge/notify/okokNotify/client.lua',
    'bridge/notify/ox_lib/client.lua',
    'bridge/notify/pNotify/client.lua',
    'bridge/notify/t-notify/client.lua',
    'bridge/notify/wasabi_notify/client.lua',
    'bridge/phone/17mov_Phone/client.lua',
    'bridge/phone/gksphone/client.lua',
    'bridge/phone/lb-phone/client.lua',
    'bridge/phone/npwd/client.lua',
    'bridge/phone/roadphone/client.lua',
    'bridge/phone/yseries/client.lua',
    'bridge/target/ox_target/client.lua',
    'bridge/target/prompt/client.lua',
    'bridge/target/qb-target/client.lua',
    'bridge/target/sleepless_interact/client.lua',
    'bridge/voice/pma-voice/client.lua',
    'bridge/weather/Renewed-Weathersync/client.lua',
    'bridge/weather/cd_easytime/client.lua',
    'bridge/weather/native/client.lua',
    'bridge/weather/qb-weathersync/client.lua',
    'bridge/weather/qbx_weathersync/client.lua',
}
