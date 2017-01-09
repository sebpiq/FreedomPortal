package.path = package.path .. ';../freedomportal/?.lua'
local clients = require('freedomportal.clients')

clients._write_clients_file('blabla')