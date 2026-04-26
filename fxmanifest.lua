fx_version 'cerulean'
game 'gta5'

author 'AbsoluteNoobStudio'
description 'Standalone/framework-compatible FiveM fight club script'
version '1.1.0'

shared_script 'config.lua'

server_scripts {
    'bridge.lua',
    'server.lua'
}

client_script 'client.lua'