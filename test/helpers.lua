local connector = require('wsapi.mock')
local handlers_main = require('freedomportal.handlers.main')

local function http_get(url, headers)
    local app = connector.make_handler(handlers_main.run)
    local response, request = app:get(url, {}, headers)
    if response.code == "500 Internal Server Error" then print(response.body) end
    return response
end

return {
    http_get = http_get
}