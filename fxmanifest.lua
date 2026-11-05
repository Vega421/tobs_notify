fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tobs_notify'
author 'tobs'
description 'Notifications drawn in light: a shape per kind, four styles to choose from'
version '1.0.0'
license 'GPL-3.0-or-later'

shared_script 'config.lua'

client_script 'client/main.lua'
server_script 'server/main.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}
