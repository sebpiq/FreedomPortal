local utils = require('freedomportal.utils')
local config = require('freedomportal.config')

-- Returns the client table of all currently connected clients
local function get_all()
    return config.get('clients_storage').get_all()
end

-- Returns the infos for client `ip`
local function get(ip)
    return utils.search_collection(get_all(), 'ip', ip) 
end

-- Refreshes the file of connected clients in an atomic way.
local function refresh()
    local clients_table
    config.get('clients_storage').replace_all(function(a_clients_table)
        clients_table = a_clients_table
        local connected_clients_table = config.get('get_connected_clients')()
        local modified = false

        -- We add all connected clients to clients_table if they are not there yet 
        for mac, ip in pairs(connected_clients_table) do
            if not clients_table[mac] then
                clients_table[mac] = { ip = ip, }
                modified = true
            end
        end

        -- We remove all clients from clients_table that are not connected
        for mac, infos in pairs(clients_table) do
            if not connected_clients_table[mac] then
                clients_table[mac] = nil
                modified = true
            end
        end        

        if modified == true then
            return clients_table
        else 
            return nil
        end
    end)
    return clients_table
end

-- Sets infos of client `ip` in an atomic way.
-- All keys and values of `fields_table` must be strings.
local function set_fields(ip, fields_table)
    for key, value in pairs(fields_table) do
        if type(key) ~= 'string' then error('keys must be strings, invalid : ' .. key) end
        if type(value) ~= 'string' then error('values must be strings, invalid : ' .. value) end
    end

    local client_infos
    config.get('clients_storage').replace_all(function(clients_table)
        -- Search client by IP
        client_infos = utils.search_collection(clients_table, 'ip', ip)

        -- If client found we set key, value and save the file
        -- even if client is not found we must re-write the whole table, 
        -- because of flags used to open it.
        if client_infos then
            for key, value in pairs(fields_table) do
                client_infos[key] = value
            end
        else
            print('WARN : client with ip ' .. ip .. ' could not be found')
        end
        return clients_table
    end)

    return client_infos
end

return {
    refresh = refresh,
    get_all = get_all,
    get = get,
    set_fields = set_fields,
}