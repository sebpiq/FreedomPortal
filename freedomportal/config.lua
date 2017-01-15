local _config = {
    redirect_success = '/freedomportal_content',
    captive_static_root_url = '/freedomportal_static',
    captive_dynamic_root_url = '/freedomportal',
    client_handlers = {},
    get_connected_clients = function() return {} end
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