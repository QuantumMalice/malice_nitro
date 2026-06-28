fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'malice_nitro'
description 'Simple vehicle nitrous system using statebags'
author 'QuantumMalice'
version '1.0.0'

dependencies {
	'ox_lib',
    'ox_target',
    'ox_inventory'
}

files {
    'locales/*.json',
    'data/progress.lua',
    'data/settings.lua',
    'data/notify.lua',
    'class/nitrous.lua',
}

shared_script '@ox_lib/init.lua'
client_script 'client.lua'
server_script 'server.lua'