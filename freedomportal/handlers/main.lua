local utils = require('freedomportal.utils')
local clients = require('freedomportal.clients')

local config = {
    client_handlers = {},
    get_connected_clients = function() return {} end
}

local function set_config(params)
    for key, value in pairs(params) do
        config[key] = value
    end
end

local function run(wsapi_env)
    local ip = wsapi_env.REMOTE_ADDR
    local update_client_infos = {}
    
    local client_infos = clients.get(ip)
    if not client_infos then
        local clients_table = clients.refresh(config.get_connected_clients)
        client_infos = utils.search_collection(clients_table, 'ip', ip)
        if not client_infos then
            error('received request from ip ' .. ip .. ' but client could not be found')
        end
    end

    if not client_infos.handler then
        for key, handler in pairs(config.client_handlers) do
            if handler.recognizes(wsapi_env) then
                client_infos.handler = key
                update_client_infos.handler = key
                break
            end
        end
    end

    local status, headers, body
    if client_infos.handler then
        update_client_infos_extra, status, headers, body 
            = config.client_handlers[client_infos.handler].run(wsapi_env)
        for k,v in pairs(update_client_infos_extra) do update_client_infos[k] = v end
    else 
        -- TODO : WHAT NOW ?
    end

    -- If needed, we update `client_infos`
    if next(update_client_infos) ~= nil then
        clients.set_fields(ip, update_client_infos)
    end

    return status, headers, body
end

return {
    run = run,
    set_config = set_config
}