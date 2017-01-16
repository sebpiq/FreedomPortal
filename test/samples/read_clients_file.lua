package.path = package.path .. ';../../freedomportal/?.lua'
local clients_file_storage = require('freedomportal.clients.file_storage')
print(clients_file_storage._serialize(clients_file_storage.get_all()))