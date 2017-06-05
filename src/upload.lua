local block_size = 1024

local function handler(opts, wsapi_env)
    if wsapi_env.REQUEST_METHOD ~= 'POST' then
        return 405, { Allow = 'POST' }, function() return nil end
    end

    -- Stream file to disk
    local file_path = opts.root_path .. '/' .. wsapi_env.PATH_INFO
    local uploaded_file = assert(io.open(file_path, 'w'))
    local block
    while true do
        block = wsapi_env.input:read(block_size)
        if block == nil then break end
        uploaded_file:write(block)
    end
    uploaded_file:close()

    -- All good
    return 201, {}, function() return nil end
end

return {
    handler = handler
}
