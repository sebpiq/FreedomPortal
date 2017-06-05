package.path = package.path .. ';{{{ config.FreedomPortal_dir }}}/?.lua'

local upload = require('src.upload')
local opts = {
    root_path = '{{{ config.upload_dir }}}'
}

return {
    run = function(wsapi_env) return upload.handler(opts, wsapi_env) end
}
