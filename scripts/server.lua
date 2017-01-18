package.path = package.path .. ';/root/FreedomPortal/?.lua'

local main = require('freedomportal.handlers.main')
local android = require('freedomportal.handlers.android')
local ios = require('freedomportal.handlers.ios')
local openwrt = require('freedomportal.openwrt')
local clients_file_storage = require('freedomportal.clients.file_storage')
local config = require('freedomportal.config')

config.set('get_connected_clients', openwrt.get_connected_clients)
config.set('clients_storage', clients_file_storage)
config.set('redirect_success', 'http://freedomportal.com/index.html')
config.set('captive_static_root_url', 'http://freedomportal.com/_freedomportal')
config.set('client_handlers', { android = android.cna, ios = ios.cna })
config.set('logger', function(msg)
    local log_file = io.open('/mnt/PORTALKEY/log/server-access.log', 'a')
    log_file:write(msg)
    log_file:close()
end)

-- Create clients file if it doesn't exist
local touch_process = assert(io.popen('touch ' .. config.get('clients_file_path'), 'r'))
touch_process:read('*all')
touch_process:close()

return {
    run = main.run
}
