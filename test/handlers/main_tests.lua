package.path = package.path .. ';../../freedomportal/?.lua'

local luaunit = require('luaunit')
local connector = require('wsapi.mock')
local handlers_main = require('freedomportal.handlers.main')
local clients = require('freedomportal.clients')
local config = require('freedomportal.config')

-- Setup mockup client handlers
local headers = { ['Content-type'] = 'text/html' }
local function respond_bla(text) coroutine.yield('blabla') end
local function respond_blo(text) coroutine.yield('bloblo') end
local clients_refreshed = false

config.set('client_handlers', {
    ['bla_handler'] = {
        recognizes = function(wsapi_env) return wsapi_env.PATH_INFO == '/bla' end,
        run = function(client_infos, wsapi_env) 
            return { some_field = '12345' }, 200, headers, coroutine.wrap(respond_bla) 
        end
    },
    ['blo_handler'] = {
        recognizes = function(wsapi_env) return wsapi_env.PATH_INFO == '/blo' end,
        run = function(client_infos, wsapi_env) 
            return { some_attr = '67890' }, 200, headers, coroutine.wrap(respond_blo) 
        end
    }
})

config.set('get_connected_clients', function()
    clients_refreshed = true
    return {
        ['11:11:11:11:11:11'] = '127.0.0.1'
    }
end)

Test_handlers_main = {}

    function Test_handlers_main:setUp()
        local clients_file = io.open(clients.CLIENTS_FILE_PATH, 'w')
        clients_file:write('')
        clients_file:close()
        clients_refreshed = false
    end

    function Test_handlers_main:test_should_assign_a_client_handler()
        local app = connector.make_handler(handlers_main.run)
        local response, request = app:get('/blo')
        luaunit.assertEquals(response.code, 200)
        luaunit.assertEquals(request.request_method, 'GET')
        luaunit.assertEquals(response.headers['Content-type'], 'text/html')
        luaunit.assertEquals(response.body, 'bloblo')
        luaunit.assertEquals(clients_refreshed, true)
        luaunit.assertEquals(clients.get('127.0.0.1'), {
            ip = '127.0.0.1',
            handler = 'blo_handler',
            some_attr = '67890',
        })
    end

    function Test_handlers_main:test_shouldnt_reassign_handler()
        local app = connector.make_handler(handlers_main.run)
        local response, request = app:get('/bla')
        luaunit.assertEquals(clients_refreshed, true)
        luaunit.assertEquals(clients.get('127.0.0.1'), {
            ip = '127.0.0.1',
            handler = 'bla_handler',
            some_field = '12345',
        })

        -- Second request, handler shouldnt be reassigned
        clients_refreshed = false
        local response, request = app:get('/blo')
        luaunit.assertEquals(clients_refreshed, false)
        luaunit.assertEquals(clients.get('127.0.0.1'), {
            ip = '127.0.0.1',
            handler = 'bla_handler',
            some_field = '12345',
        })
    end