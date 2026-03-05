shared_script '@WaveShield/resource/include.lua'

fx_version 'cerulean'
author 'Dalton Life'
game 'gta5'
description 'Admin Commands for CelestialRP'
lua54 'yes'
version '1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/**.lua'
}

client_scripts {
    'client/**.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/**.lua',
}

dependicies {
    'ox_lib',
}

files { }
