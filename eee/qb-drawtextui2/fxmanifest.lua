
fx_version 'cerulean'
games { 'gta5' }

author 'ZomerX#6153  Benz#0579  Discord  - https://discord.gg/5xHA3RY3Fq'
description 'ZomerX#6153  Benz#0579  Discord  - https://discord.gg/5xHA3RY3Fq'
version '1.0.0'

lua54 'yes'

client_script {
    'client.lua',
    'barber.lua',
    'bank.lua',
    'clothing.lua',
    'bossmenu.lua',
    'garages.lua',
    'bennys.lua',
    'tattoo.lua',
    'apartments.lua',
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/CircleZone.lua'
}

ui_page "nui/index.html"
files { 'nui/**/*' }

escrow_ignore {
    'nui/**',
}