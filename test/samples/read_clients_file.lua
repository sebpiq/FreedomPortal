package.path = package.path .. ';../../freedomportal/?.lua'
local clients = require('freedomportal.clients')
print(clients._read_file())