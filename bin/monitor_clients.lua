package.path = package.path .. ';../freedomportal/?.lua'

local clients = require('freedomportal.clients')
local openwrt = require('freedomportal.openwrt')

local posix = require('posix')


while true do
    clients.refresh(openwrt.get_connected_clients)
    posix.sleep(1)
end