local lustache = require('lustache')

local config = require('freedomportal.config')
--local local_config = require('')

-- Helper to run commands
function run_command(cmd)
    local process = assert(io.popen(cmd, 'r'))
    process:read('*all')
    process:close()
    return process
end

local configured_root_path = '/tmp/configured'

-- Build folder structure for configured files
run_command('rm -rf ' .. configured_root_path)
run_command('mkdir ' .. configured_root_path)
run_command('mkdir ' .. configured_root_path .. '/scripts')

local context = {
    VERSION = 'TODO',
    configured_root_path = configured_root_path,
    config = {
        host = config.get('host')
    }
}

-- Render configured lighttpd.conf
local lighttpd_conf_template = assert(io.open('scripts/lighttpd.conf', 'r'))
local lighttpd_conf = lighttpd_conf_template:read('*all')
lighttpd_conf = lustache:render(lighttpd_conf, context)

local lighttpd_conf_final = assert(io.open(configured_root_path .. '/scripts/lighttpd.conf', 'w'))
lighttpd_conf_final:write(lighttpd_conf)
lighttpd_conf_final:close()
