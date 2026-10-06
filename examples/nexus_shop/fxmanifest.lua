fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'nexus_shop'
description 'A simple shop built with Nexus UI: a clerk, a target option and a basket. This copy runs on nexus_bridge.'
version '1.1.0'
author 'Nexus Studios'

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/**/*',
    'locales/*.json',
}

-- The framework, the inventory and the target resource are whichever the server runs:
-- nexus_bridge finds them. It is not listed as a dependency on purpose: FXServer stops the
-- dependents of a resource that restarts and does not start them again. The first line
-- below says so itself when nexus_bridge is missing or starts too late.
shared_scripts {
    '@nexus_bridge/init.lua',
    'config.lua',
    'nexus/contract.lua',
}

client_scripts {
    'nexus/screens.lua',
    'nexus/client.lua',
    'client/main.lua',
}

server_scripts {
    'nexus/server.lua',
    'server/main.lua',
}
