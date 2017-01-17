package.path = package.path .. ';/root/FreedomPortal/?.lua'

local posix = require('posix')
local clients = require('freedomportal.clients.init')
local openwrt = require('freedomportal.openwrt')
local clients_file_storage = require('freedomportal.clients.file_storage')
local config = require('freedomportal.config')

config.set('get_connected_clients', openwrt.get_connected_clients)
config.set('clients_storage', clients_file_storage)

-- Create clients file if it doesn't exist
local touch_process = assert(io.popen('touch ' .. config.get('clients_file_path'), 'r'))
touch_process:read('*all')
touch_process:close()

while true do
    clients.refresh()
    posix.sleep(1)
end