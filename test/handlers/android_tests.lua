local luaunit = require('luaunit')
local android = require('freedomportal.handlers.android')
local clients = require('freedomportal.clients.init')
local config = require('freedomportal.config')

Test_handlers_android = {}

    function Test_handlers_android:setUp()
        helpers.setUp()
        config.set('www_host', 'yeah.com')
        config.set('clients_storage', helpers.dummy_clients_storage)
        config.set('get_connected_clients', function()
            return {
                ['11:11:11:11:11:11'] = '127.0.0.1'
            }
        end)
    end

    function Test_handlers_android:test_run_cna()
        config.set('client_handlers', { android = android.cna })
        response = helpers.http_get('/blo', {
            HTTP_USER_AGENT = 'Mozilla/5.0 (Linux; Android 4.0.4; Galaxy Nexus Build/IMM76B) AppleWebKit/535.19 (KHTML, like Gecko) Chrome/18.0.1025.133 Mobile Safari/535.19 '
        })

        -- Should redirect directly to success url
        luaunit.assertEquals(response.code, 302)
        luaunit.assertEquals(response.headers['Location'], 'http://yeah.com')
        luaunit.assertEquals(clients.get('127.0.0.1'), {
            ip = '127.0.0.1',
            handler = 'android'
        })
    end

    function Test_handlers_android:test_run_browser( ... )
        config.set('client_handlers', { android = android.browser })
        config.set('captive_static_root_url', '/static')
        config.set('captive_dynamic_root_url', '/freedomportal')

        -- Should first answer 302 to trigger CNA to open
        response = helpers.http_get('/generate_204', {
            HTTP_USER_AGENT = 'Mozilla/5.0 (Linux; Android 4.0.4; Galaxy Nexus Build/IMM76B) AppleWebKit/535.19 (KHTML, like Gecko) Chrome/18.0.1025.133 Mobile Safari/535.19 '
        })
        luaunit.assertEquals(response.code, 302)
        luaunit.assertEquals(response.headers['Location'], '/static/android/connected.html')
        luaunit.assertEquals(clients.get('127.0.0.1'), {
            ip = '127.0.0.1',
            handler = 'android'
        })

        -- Should send request from web page to mark client as connected
        response = helpers.http_get('/freedomportal/connected', {})
        luaunit.assertEquals(response.code, 200)
        luaunit.assertEquals(clients.get('127.0.0.1'), {
            ip = '127.0.0.1',
            handler = 'android',
            status = 'connected',
        })

        -- Subsequent /generate_204 requests should be answered by 204 to close CNA
        response = helpers.http_get('/generate_204', {})
        luaunit.assertEquals(response.code, 204)
        luaunit.assertEquals(clients.get('127.0.0.1'), {
            ip = '127.0.0.1',
            handler = 'android',
            status = 'connected',
        })
    end
