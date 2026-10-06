fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'bridge_test'
author 'Nexus Studios'
description 'Exercises every module of nexus_bridge on the server it runs on, at start and by command.'
version '1.0.0'


shared_script '@nexus_bridge/init.lua'
server_script 'server/main.lua'
client_script 'client/main.lua'
