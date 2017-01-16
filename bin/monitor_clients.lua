package.path = package.path .. ';../freedomportal/?.lua'

local posix = require('posix')
local clients = require('freedomportal.clients')
local openwrt = require('freedomportal.openwrt')

while true do
    clients.refresh()
    posix.sleep(1)
end