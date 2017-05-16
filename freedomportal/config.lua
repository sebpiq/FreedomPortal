local _config = {
    -- Logger function to implement custom logging
    logger = function(msg) end,

    -- Host on which lighttpd will serve custom web pages
    www_host = 'freedomportal.com',

    -- Root path for the custom web pages served on the static portal
    www_root_path = '/mnt/PORTALKEY/www',

    -- Root url where client handlers pages are served (ios/connected.html, android/connected.html ...)
    -- See pages/ folder to see all the pages.
    captive_static_root_url = '/freedomportal_static',

    -- Root for urls that are used by client handlers to change client status and walk through the
    -- connection process.
    captive_dynamic_root_url = '/freedomportal',

    -- Table of client handlers. Example :
    --[[
    {
        android = {
            -- function that returns ´true´ if handler should be activated for this client
            recognizes = function(wsapi_env) return should_I_handle_this() end

            -- handles a request once client has been associated to this handler
            run = function(client_infos, wsapi_env) return response end
        },
        ...
    }
    ]]
    client_handlers = {},

    -- A function that must return a table of currently connected clients: `{ mac = ip }`
    get_connected_clients = function() return {} end,

    -- Storage for clients. Example :
    --[[
    {
        -- Should return a list of all stored clients
        get_all = function() return clients_table end,

        -- Should replace the whole clients stored with new_clients_table
        replace_all = function(new_clients_table) return clients_table end
    }
    ]]
    clients_storage = '',

    -- File path for clients.file_storage. File must exist!
    clients_file_path = '/tmp/freedomportal_clients.txt',
}

local function set(key, value)
    if not _config[key] then
        error('invalid parameter name ' .. key)
    end
    _config[key] = value
end

local function get(key)
    return _config[key]
end

return {
    set = set,
    get = get,
}
