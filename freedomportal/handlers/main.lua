local utils = require('freedomportal.utils')
local clients = require('freedomportal.clients')
local config = require('freedomportal.config')

local function run(wsapi_env)
    
    local ip = wsapi_env.REMOTE_ADDR
    local update_client_infos = {}
    local logger = config.get('logger')

    -- Get client infos, refreshing the clients if our client was not found
    local client_infos = clients.get(ip)
    if not client_infos then
        local clients_table = clients.refresh(config.get('get_connected_clients'))
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
    local client_infos_extra, status, headers, body
    if client_infos.handler then
        client_infos_extra, status, headers, body 
            = config.get('client_handlers')[client_infos.handler].run(client_infos, wsapi_env)
        for k, v in pairs(client_infos_extra) do update_client_infos[k] = v end
    else 
        status = 'success'
    end

    -- If needed, we update `client_infos`
    if next(update_client_infos) ~= nil then
        clients.set_fields(ip, update_client_infos)
    end

    -- WSAPI expects a function for `body` so we make one
    if body == nil then
        body = function() return nil end
    elseif type(body) == 'string' then
        local body_str = body
        body = coroutine.wrap(function() return coroutine.yield(body_str) end)
    end
    
    -- Returns the appropriate answer
    if status == 'success' then
        return 302, { Location = config.get('redirect_success') }, body
    else
        return status, headers, body
    end
end

return {
    run = run
}