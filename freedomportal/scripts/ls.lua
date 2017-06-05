package.path = package.path .. ';{{{ config.FreedomPortal_dir }}}/?.lua'

local ls = require('src.ls')
local opts = {
    root_path = '{{{ config.ls_dir }}}'
}

return {
    run = function(wsapi_env) return ls.handler(opts, wsapi_env) end
}
