package.path = package.path .. ';/root/FreedomPortal/?.lua'

local main = require('freedomportal.handlers.main')
local openwrt = require('freedomportal.openwrt')
local config = require('freedomportal.config')

config.set('get_connected_clients', openwrt.get_connected_clients)
config.set('redirect_success', '/freedomportal_content/index.html')

return {
    run = main.run
}
