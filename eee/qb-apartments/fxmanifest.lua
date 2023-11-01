
fx_version 'cerulean'
game 'gta5'

description 'ZomerX#6153  Benz#0579  Discord  - https://discord.gg/5xHA3RY3Fq'
version '2.1.0'

shared_scripts {
    'config.lua',
    '@qb-core/shared/locale.lua',
    'locales/en.lua', -- Change to the language you want
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_scripts {
	'client/main.lua',
	'client/gui.lua',
	'@PolyZone/client.lua',
	'@PolyZone/BoxZone.lua',
	'@PolyZone/CircleZone.lua',
}

dependencies {
	'qb-core',
	'qb-interior',
	'qb-clothing',
	'qb-weathersync'
}

lua54 'yes'
server_scripts { '@mysql-async/lib/MySQL.lua' }