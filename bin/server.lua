package.path = package.path .. ';/root/FreedomPortal/?.lua'

local main = require('freedomportal.handlers.main')
local android = require('freedomportal.handlers.android')
local openwrt = require('freedomportal.openwrt')
local config = require('freedomportal.config')

config.set('get_connected_clients', openwrt.get_connected_clients)
config.set('redirect_success', 'http://freedomportal.com/index.html')
config.set('captive_static_root_url', 'http://freedomportal.com/_freedomportal')
config.set('client_handlers', { android = android.browser })
config.set('logger', function(msg)
    local log_file = io.open('/var/log/lighttpd/cgi-access.log', 'a')
    log_file:write(msg)
    log_file:close()
end)

return {
    run = main.run
}
