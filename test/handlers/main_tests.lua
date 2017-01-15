local luaunit = require('luaunit')
local clients = require('freedomportal.clients')
local config = require('freedomportal.config')

local clients_refreshed = false

Test_handlers_main = {}

    function Test_handlers_main:setUp()
        local clients_file = io.open(clients.CLIENTS_FILE_PATH, 'w')
        clients_file:write('')
        clients_file:close()

        -- Setup mockup client handlers
        local headers = { ['Content-type'] = 'text/html' }
        local function respond_bla(text) coroutine.yield('blabla') end
        local function respond_blo(text) coroutine.yield('bloblo') end

        config.set('client_handlers', {
            ['bla_handler'] = {
                recognizes = function(wsapi_env) return wsapi_env.PATH_INFO == '/bla' end,
                run = function(client_infos, wsapi_env) 
                    return { some_field = wsapi_env.HTTP_SOME_FIELD }, 
                        200, headers, coroutine.wrap(respond_bla) 
                end
            },
            ['blo_handler'] = {
                recognizes = function(wsapi_env) return wsapi_env.PATH_INFO == '/blo' end,
                run = function(client_infos, wsapi_env) 
                    return { some_attr = wsapi_env.HTTP_SOME_ATTR }, 
                        200, headers, coroutine.wrap(respond_blo) 
                end
            }
        })

        config.set('get_connected_clients', function()
            clients_refreshed = true
            return {
                ['11:11:11:11:11:11'] = '127.0.0.1'
            }
        end)
    end

    function Test_handlers_main:test_should_assign_a_client_handler()
        local response = helpers.http_get('/blo', { HTTP_SOME_ATTR = '67890' })
        luaunit.assertEquals(response.code, 200)
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
        local response = helpers.http_get('/bla', { HTTP_SOME_FIELD = '12345' })
        luaunit.assertEquals(clients_refreshed, true)
        luaunit.assertEquals(clients.get('127.0.0.1'), {
            ip = '127.0.0.1',
            handler = 'bla_handler',
            some_field = '12345',
        })

        -- Second request, handler shouldnt be reassigned
        clients_refreshed = false
        local response = helpers.http_get('/blo', { HTTP_SOME_FIELD = '67890' })
        luaunit.assertEquals(clients_refreshed, false)
        luaunit.assertEquals(clients.get('127.0.0.1'), {
            ip = '127.0.0.1',
            handler = 'bla_handler',
            some_field = '67890',
        })
    end