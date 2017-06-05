local posix = require('posix')

local function handler(opts, wsapi_env)
    if wsapi_env.REQUEST_METHOD ~= 'GET' then
        return 405, { Allow = 'GET' }, function() return nil end
    end

    -- Try to list the contents for `dir_path` without even checking it is valid
    local dir_path = opts.root_path .. '/' .. wsapi_env.PATH_INFO
    local status, result = pcall(function() return posix.dir(dir_path) end)
    if status == true then
        local json_file_list = '["' .. table.concat(result, '","') .. '"]'
        local body = coroutine.wrap(function() return coroutine.yield(json_file_list) end)
        return 200, { ['Content-Type'] = 'application/json' }, body
    else
        -- For now, we don't detail about the error
        return 404, {}, function() return nil end
    end
end

return {
    handler = handler
}
