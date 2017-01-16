package.path = package.path .. ';../../freedomportal/?.lua'
local clients_file_storage = require('freedomportal.clients.file_storage')
clients_file_storage.replace_all(function() return { ba = { ip = 'bi' } } end)