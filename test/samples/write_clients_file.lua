package.path = package.path .. ';../../freedomportal/?.lua'
local clients = require('freedomportal.clients')

clients._replace_file(function() return 'blabla' end)