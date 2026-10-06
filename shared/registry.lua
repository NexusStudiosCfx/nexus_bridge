--[[
    Every module of the bridge, and every adapter it ships.

    `adapters[module]` is in the order 'auto' tries them: the first entry whose resource is
    running serves the module. An entry without a resource needs none (the key prompt, the
    game's own fuel level) and therefore always matches, so it goes last.

      name       the adapter, and its folder: bridge/<module>/<name>/
      resource   the resource it wraps, or a list of resources with the same API
      auto       false for an adapter that is only used when config.lua names it
      configured a place in config.lua ('log.webhooks') that has to hold something before
                 'auto' picks the adapter
      fallback   true for the adapter 'auto' ends up with when nothing else was found
      evidence   how sure we are of it, as docs/adapters.md explains:
                   'tested'  run against the real resource on a real server
                   'source'  written against the resource's published source
                   'docs'    written against the vendor's documentation (escrowed resources)

    Adding an adapter means adding its folder, a line here and its sources in docs/adapters.md.
]]

BridgeRegistry = {
    -- In the order the doctor prints them.
    modules = {
        'framework',
        'inventory',
        'target',
        'notify',
        'banking',
        'vehicles',
        'keys',
        'fuel',
        'dispatch',
        'phone',
        'medical',
        'voice',
        'weather',
        'appearance',
        'log',
    },

    -- Modules that wrap nothing: the utilities.
    utilities = {
        'format',
        'db',
        'cooldown',
        'ratelimit',
        'permission',
        'locale',
        'point',
        'ped',
        'placer',
    },

    adapters = {
        framework = {
            -- Qbox answers to the name qb-core as well, so it has to be asked first.
            { name = 'qbx_core', resource = 'qbx_core', evidence = 'tested' },
            { name = 'qb-core', resource = 'qb-core', evidence = 'tested' },
            { name = 'es_extended', resource = 'es_extended', evidence = 'tested' },
        },

        inventory = {
            { name = 'ox_inventory', resource = 'ox_inventory', evidence = 'tested' },
            { name = 'qb-inventory', resource = 'qb-inventory', evidence = 'tested' },
            -- The plain inventory inside ESX: last, so that any inventory resource wins.
            { name = 'es_extended', resource = 'es_extended', evidence = 'tested' },
        },

        target = {
            { name = 'ox_target', resource = 'ox_target', evidence = 'source' },
            { name = 'qb-target', resource = 'qb-target', evidence = 'source' },
            { name = 'sleepless_interact', resource = 'sleepless_interact', evidence = 'source' },
            -- No target resource: world points get a key prompt.
            { name = 'prompt' },
        },

        notify = {
            -- A notification resource wins over what the framework would show by itself.
            { name = 'okokNotify', resource = 'okokNotify', evidence = 'docs' },
            { name = 'wasabi_notify', resource = 'wasabi_notify', evidence = 'docs' },
            { name = 'lation_ui', resource = 'lation_ui', evidence = 'docs' },
            { name = 'brutal_notify', resource = 'brutal_notify', evidence = 'docs' },
            { name = 't-notify', resource = 't-notify', evidence = 'source' },
            { name = 'mythic_notify', resource = 'mythic_notify', evidence = 'source' },
            { name = 'pNotify', resource = 'pNotify', evidence = 'source' },
            { name = 'framework', resource = { 'qbx_core', 'qb-core', 'es_extended' }, evidence = 'source' },
            -- After the frameworks: ox_lib runs on most servers as a library, also on the
            -- ones that show their notifications with something else.
            { name = 'ox_lib', resource = 'ox_lib', evidence = 'source' },
            -- The game's own feed needs nothing.
            { name = 'native' },
        },

        banking = {
            { name = 'Renewed-Banking', resource = 'Renewed-Banking', evidence = 'tested' },
            { name = 'qb-banking', resource = 'qb-banking', evidence = 'source' },
            { name = 'esx_addonaccount', resource = 'esx_addonaccount', evidence = 'source' },
        },

        vehicles = {
            { name = 'qbx_vehicles', resource = 'qbx_vehicles', evidence = 'tested' },
            -- QBCore and ESX have no function for this: their adapters work on the table
            -- the framework's own garage and vehicle shop use.
            { name = 'qb-core', resource = 'qb-core', evidence = 'tested' },
            { name = 'es_extended', resource = 'es_extended', evidence = 'tested' },
        },

        keys = {
            { name = 'qbx_vehiclekeys', resource = 'qbx_vehiclekeys', evidence = 'source' },
            { name = 'qb-vehiclekeys', resource = 'qb-vehiclekeys', evidence = 'source' },
            { name = 'Renewed-Vehiclekeys', resource = 'Renewed-Vehiclekeys', evidence = 'docs' },
            { name = 'MrNewbVehicleKeys', resource = 'MrNewbVehicleKeys', evidence = 'docs' },
            { name = 'wasabi_carlock', resource = 'wasabi_carlock', evidence = 'docs' },
            { name = 'vehicles_keys', resource = 'vehicles_keys', evidence = 'docs' },
            -- A garage with keys built in: after the resources that are only about keys.
            { name = 'cd_garage', resource = 'cd_garage', evidence = 'docs' },
        },

        fuel = {
            { name = 'ox_fuel', resource = 'ox_fuel', evidence = 'source' },
            { name = 'Renewed-Fuel', resource = 'Renewed-Fuel', evidence = 'docs' },
            -- One file for the resources that kept LegacyFuel's two exports. Two of them
            -- also answer to the name LegacyFuel, so that name is asked for last.
            { name = 'LegacyFuel', resource = { 'cdn-fuel', 'ps-fuel', 'qb-fuel', 'lc_fuel', 'LegacyFuel' }, evidence = 'source' },
            { name = 'qs-fuelstations', resource = 'qs-fuelstations', evidence = 'docs' },
            { name = 'BigDaddy-Fuel', resource = 'BigDaddy-Fuel', evidence = 'docs' },
            { name = 'rcore_fuel', resource = 'rcore_fuel', evidence = 'docs' },
            { name = 'ti_fuel', resource = 'ti_fuel', evidence = 'docs' },
            -- No fuel resource: the game's own fuel level.
            { name = 'native' },
        },

        dispatch = {
            { name = 'ps-dispatch', resource = 'ps-dispatch', evidence = 'source' },
            { name = 'cd_dispatch', resource = 'cd_dispatch', evidence = 'docs' },
            { name = 'qs-dispatch', resource = 'qs-dispatch', evidence = 'docs' },
            { name = 'core_dispatch', resource = 'core_dispatch', evidence = 'docs' },
            { name = 'rcore_dispatch', resource = 'rcore_dispatch', evidence = 'docs' },
            { name = 'tk_dispatch', resource = 'tk_dispatch', evidence = 'docs' },
            { name = 'codem-dispatchv2', resource = 'codem-dispatchv2', evidence = 'docs' },
            { name = 'origen_police', resource = 'origen_police', evidence = 'docs' },
            -- A tablet that many servers run next to a dispatch of its own: after those.
            { name = 'lb-tablet', resource = 'lb-tablet', evidence = 'tested' },
            -- No dispatch resource: a notification and a blip for whoever is on duty.
            { name = 'builtin' },
        },

        phone = {
            { name = 'lb-phone', resource = 'lb-phone', evidence = 'docs' },
            { name = 'yseries', resource = 'yseries', evidence = 'docs' },
            { name = 'gksphone', resource = 'gksphone', evidence = 'docs' },
            { name = '17mov_Phone', resource = '17mov_Phone', evidence = 'docs' },
            { name = 'roadphone', resource = 'roadphone', evidence = 'docs' },
            { name = 'npwd', resource = 'npwd', evidence = 'source' },
            { name = 'qb-phone', resource = 'qb-phone', evidence = 'source' },
        },

        medical = {
            { name = 'nexus_ems', resource = 'nexus_ems', evidence = 'source' },
            { name = 'wasabi_ambulance_v2', resource = 'wasabi_ambulance_v2', evidence = 'docs' },
            { name = 'wasabi_ambulance', resource = 'wasabi_ambulance', evidence = 'docs' },
            { name = 'ars_ambulancejob', resource = 'ars_ambulancejob', evidence = 'source' },
            { name = 'qbx_medical', resource = 'qbx_medical', evidence = 'source' },
            { name = 'qb-ambulancejob', resource = 'qb-ambulancejob', evidence = 'source' },
            { name = 'esx_ambulancejob', resource = 'esx_ambulancejob', evidence = 'source' },
        },

        voice = {
            { name = 'pma-voice', resource = 'pma-voice', evidence = 'source' },
            { name = 'saltychat', resource = 'saltychat', evidence = 'source' },
        },

        weather = {
            { name = 'Renewed-Weathersync', resource = 'Renewed-Weathersync', evidence = 'source' },
            { name = 'cd_easytime', resource = 'cd_easytime', evidence = 'source' },
            { name = 'qb-weathersync', resource = 'qb-weathersync', evidence = 'source' },
            { name = 'qbx_weathersync', resource = 'qbx_weathersync', evidence = 'source' },
            -- No weather resource: the client still reads the game's own sky and clock.
            { name = 'native' },
        },

        appearance = {
            { name = 'illenium-appearance', resource = 'illenium-appearance', evidence = 'source' },
            { name = 'fivem-appearance', resource = 'fivem-appearance', evidence = 'source' },
            { name = 'qb-clothing', resource = 'qb-clothing', evidence = 'source' },
            { name = 'esx_skin', resource = 'esx_skin', evidence = 'source' },
        },

        log = {
            -- The bridge's own Discord webhooks: first once config.lua holds one, and what
            -- is left when no log resource runs (it then drops every line).
            { name = 'webhook', configured = 'log.webhooks', fallback = true },
            { name = 'fmsdk', resource = 'fmsdk', evidence = 'source' },
            { name = 'fm-logs', resource = 'fm-logs', evidence = 'source' },
            -- Part of nearly every QBCore and ESX server, with webhooks few have filled in.
            { name = 'qb-smallresources', resource = 'qb-smallresources', evidence = 'source', auto = false },
            { name = 'es_extended', resource = 'es_extended', evidence = 'source', auto = false },
        },
    },
}
