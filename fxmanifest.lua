fx_version 'cerulean'
game 'gta5'

author 'AbsoluteNoobStudio'
description 'Standalone/framework-compatible FiveM fight club script'
version '1.2.1'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

shared_script 'config.lua'

server_scripts {
    'bridge.lua',
    'server.lua'
}

client_script 'client.lua'
