local connector = require('wsapi.mock')
local handlers_main = require('freedomportal.handlers.main')

local function http_get(url, headers)
    local app = connector.make_handler(handlers_main.run)
    local response, request = app:get(url, {}, headers)
    if response.code == "500 Internal Server Error" then print(response.body) end
    return response
end

local function file_write(path, contents)
    local file = io.open(path, 'w')
    file:write(contents)
    file:close()
end

local function file_read(path)
    local file = io.open(path, 'r')
    local contents = file:read('*a')
    file:close()
    return contents
end

local dummy_clients_storage = {
    clients = {},
    get_all = function()
        return helpers.dummy_clients_storage.clients
    end,
    replace_all = function(get_clients)
        helpers.dummy_clients_storage.clients = get_clients(helpers.dummy_clients_storage.clients)
    end,
}

local setUp = function()
    dummy_clients_storage.clients = {}
end

return {
    setUp = setUp,
    http_get = http_get,
    file_write = file_write,
    file_read = file_read,
    dummy_clients_storage = dummy_clients_storage,
}