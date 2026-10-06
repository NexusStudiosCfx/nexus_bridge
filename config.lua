--[[
    nexus_bridge configuration. This file only runs on the server: nothing in it is sent to
    players, except `Config.settings`, which the client half of the modules needs.

    Most servers change nothing here. Every category finds the resource it knows by itself.
]]

Config = {}

--[[
    Which resource serves each category.

      'auto'      the first resource of the category's list that is running (README, "Supported")
      '<name>'    always this adapter, for example 'ox_inventory'
      'custom'    your own adapter in bridge/custom/<category>/ (docs/adding-an-adapter.md)
      false       switch the category off: its functions answer with a harmless default

    A category that finds nothing behaves like one that is switched off, and `bridge doctor`
    says which those are.
]]
Config.adapters = {
    framework = 'auto',
    inventory = 'auto',
    target = 'auto',
    notify = 'auto',
    banking = 'auto',
    vehicles = 'auto',
    keys = 'auto',
    fuel = 'auto',
    dispatch = 'auto',
    phone = 'auto',
    appearance = 'auto',
    medical = 'auto',
    voice = 'auto',
    weather = 'auto',
    log = 'auto',
}

-- Sent to every client. Never put a webhook, a key or a password in here.
Config.settings = {
    -- The language of the few texts the bridge shows itself (the key prompt, the prop placer).
    locale = 'en',

    framework = {
        -- ESX has no boss flag on a job. The grades with these names count as the boss.
        bossGrades = { 'boss' },
    },

    target = {
        -- With no target resource running, world points show a key prompt instead.
        promptKey = 38,        -- the control to press (38 is E)
        entityKey = 'G',       -- default key for "interact with what is next to me"
        distance = 2.0,        -- how close a point's option can be used when it sets no distance
    },

    notify = {
        duration = 5000,       -- milliseconds, when the caller gives none
        title = nil,           -- a title for notification resources that show one, when the caller gives none
    },

    dispatch = {
        -- The jobs an alert goes to when the caller names none.
        jobs = { 'police' },
    },

    phone = {
        -- Who an e-mail is from when the caller names nobody.
        sender = 'City Services',
        -- Phones that want an address for the sender get name@domain.
        domain = 'city.mail',
    },

    -- How Bridge.format writes money, for every resource that uses it.
    format = {
        symbol = '$',
        after = false,         -- true puts the sign behind the number: 1,500$
        thousands = ',',
        decimal = '.',
    },
}

-- Webhooks for Bridge.log, by channel. 'default' receives every channel that has no line of
-- its own. Leave a channel empty to drop it. These stay on the server.
Config.log = {
    username = 'Nexus Bridge',
    webhooks = {
        default = '',
        -- shop = 'https://discord.com/api/webhooks/...',
    },
    -- Only for Config.adapters.log = 'qb-smallresources': which of its webhook names a
    -- channel goes to. A channel without a line goes to its 'default'.
    names = {},
}

-- The console command: `bridge doctor`, `bridge selftest`, `bridge version`. Change the name
-- if another resource already owns it.
Config.command = 'bridge'

-- Looks for a newer release on GitHub once at start-up and says so in the console.
Config.updateCheck = true

-- Prints which adapter every resource loads, and each rebuild.
Config.debug = false
