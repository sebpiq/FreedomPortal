package.path = package.path .. ';./deps/?.lua'

-- Check that we have the right arguments, error message otherwise
if (arg[1] == nil) then
    print('usage : \n' .. arg[-1] .. ' ' .. arg[0] .. ' <config>')
    os.exit(1)
end

local lustache = require('lustache')
local config = require(arg[1])

-- Helpers
function run_command(cmd)
    local process = assert(io.popen(cmd, 'r'))
    local out = process:read('*all')
    process:close()
    return out
end

function render_template(context, source, destination)
    local source_file = assert(io.open(source, 'r'))
    local template = source_file:read('*all')
    local rendered = lustache:render(template, context)

    local destination_file = assert(io.open(destination, 'w'))
    destination_file:write(rendered)
    destination_file:close()
end

-- Build folder structure for configured files
run_command('rm -rf ' .. config.configured_dir)
run_command('mkdir ' .. config.configured_dir)
run_command('mkdir ' .. config.configured_dir .. '/pages')
run_command('mkdir ' .. config.configured_dir .. '/scripts')

-- Render configured files to `configured_dir`
local context = {
    glversion = run_command('cat /etc/glversion'),
    config = config
}

render_template(context, 'freedomportal/freedomportal.init.d', config.configured_dir .. '/freedomportal.init.d')
render_template(context, 'freedomportal/lighttpd.conf', config.configured_dir .. '/lighttpd.conf')
render_template(context, 'freedomportal/pages/redirection.html', config.configured_dir .. '/pages/redirection.html')
render_template(context, 'freedomportal/scripts/upload.lua', config.configured_dir .. '/scripts/upload.lua')
