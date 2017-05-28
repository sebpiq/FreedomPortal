local luaunit = require('luaunit')
local posix = require('posix')
local connector = require('wsapi.mock')

local ls = require('src.ls')

function run(wsapi_env)
    return ls.handler({ root_path = posix.getcwd() }, wsapi_env)
end
local app = connector.make_handler(run)

function _log_errors(response)
    if response.code == 500 then
        print(response.body)
    end
end

Test_ls = {}

    function Test_ls:test_ls_dir()
        local response, request = app:get('/')
        _log_errors(response)

        luaunit.assertEquals(response.code, 200)
        luaunit.assertEquals(response.headers['Content-Type'], 'application/json')
        luaunit.assertEquals(response.body,
            '["config.lua","freedomportal",".gitignore","deps",".","run_tests.lua","..","example","test","configure.lua","README.md","src","LICENSE-MIT",".git"]')
    end

    function Test_ls:test_unallowed_method()
        local response, request = app:post('/', 'abc', { ['Content-Type'] = 'text/plain' })
        _log_errors(response)

        luaunit.assertEquals(response.code, 405)
        luaunit.assertEquals(response.headers['Allow'], 'GET')
    end

    function Test_ls:test_unknown_file()
        local response, request = app:get('/unknown_file')
        _log_errors(response)

        luaunit.assertEquals(response.code, 404)
    end
