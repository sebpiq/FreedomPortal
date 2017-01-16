local utils = require('freedomportal.utils')
local clients = require('freedomportal.clients.init')
local config = require('freedomportal.config')

local function run(wsapi_env)

    local ip = wsapi_env.REMOTE_ADDR
    local update_client_infos = {}
    local logger = config.get('logger')

    -- Get client infos, refreshing the clients if our client was not found
    local client_infos = clients.get(ip)
    if not client_infos then
        local clients_table = clients.refresh()
        client_infos = utils.search_collection(clients_table, 'ip', ip)
        if not client_infos then
            error('received request from ip ' .. ip .. ' but client could not be found')
        end
    end

    -- Try to assign a handler to the client if it doesn't have one yet
    if not client_infos.handler then
        for key, handler in pairs(config.get('client_handlers')) do
            if handler.recognizes(wsapi_env) then
                client_infos.handler = key
                update_client_infos.handler = key
                break
            end
        end
        logger(ip .. '\n\tUser-Agent : ' .. wsapi_env.HTTP_USER_AGENT 
            .. '\n\tHOST : ' .. wsapi_env.HTTP_HOST
            .. '\n\tURL : ' .. wsapi_env.PATH_INFO)
        if client_infos.handler then logger('\n\thandler : ' .. client_infos.handler .. '\n') end
    end

    -- Call client handler if it has one
    -- Otherwise, just redirect to success url
    local response
    if client_infos.handler then
        response = config.get('client_handlers')[client_infos.handler].run(client_infos, wsapi_env)
        if response.client_infos then
            utils.extend_table(update_client_infos, response.client_infos)
        end
    else 
        response = { code = 'PASS' }
    end

    -- If needed, we update `client_infos`
    if next(update_client_infos) ~= nil then
        clients.set_fields(ip, update_client_infos)
    end

    -- WSAPI expects a function for `body` so we make one
    if response.body == nil then
        response.body = function() return nil end
    elseif type(response.body) == 'string' then
        local body_str = response.body
        response.body = coroutine.wrap(function() return coroutine.yield(body_str) end)
    end

    -- Default headers
    if response.headers == nil then response.headers = {} end
    
    -- Returns the appropriate answer
    if response.code == 'PASS' then
        return 302, { Location = config.get('redirect_success') }, response.body
    else
        return response.code, response.headers, response.body
    end
end

return {
    run = run
}