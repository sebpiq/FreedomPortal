local luaunit = require('luaunit')
local clients = require('freedomportal.clients.init')
local config = require('freedomportal.config')

local clients_refreshed = false

Test_handlers_main = {}

    function Test_handlers_main:setUp()
        helpers.setUp()
        
        -- Setup mockup client handlers
        local headers = { ['Content-type'] = 'text/html' }

        config.set('client_handlers', {
            ['bla_handler'] = {
                recognizes = function(wsapi_env) return wsapi_env.PATH_INFO == '/bla' end,
                run = function(client_infos, wsapi_env) 
                    return {
                        code = 200, headers = headers, body = 'blabla',
                        client_infos = { some_field = wsapi_env.HTTP_SOME_FIELD }
                    }
                end
            },
            ['blo_handler'] = {
                recognizes = function(wsapi_env) return wsapi_env.PATH_INFO == '/blo' end,
                run = function(client_infos, wsapi_env)
                    return {
                        code = 200, headers = headers, body = 'bloblo',
                        client_infos = { some_attr = wsapi_env.HTTP_SOME_ATTR }
                    }
                end
            }
        })

        config.set('clients_storage', helpers.dummy_clients_storage)

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