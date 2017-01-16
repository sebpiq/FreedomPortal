local luaunit = require('luaunit')
local ios = require('freedomportal.handlers.ios')
local clients = require('freedomportal.clients.init')
local config = require('freedomportal.config')

Test_handlers_ios = {}

    function Test_handlers_ios:setUp()
        helpers.setUp()
        
        config.set('redirect_success', '/yeah')
        config.set('clients_storage', helpers.dummy_clients_storage)
        config.set('get_connected_clients', function()
            return {
                ['11:11:11:11:11:11'] = '127.0.0.1'
            }
        end)
    end

    function Test_handlers_ios:test_run_cna()
        config.set('client_handlers', { ios = ios.cna })

        -- Should answer NO SUCCESS to trigger CNA to open if CaptiveNetworkSupport request
        response = helpers.http_get('/bla', { 
            HTTP_USER_AGENT = 'CaptiveNetworkSupport/1.0 wispr'
        })
        luaunit.assertEquals(response.code, 200)
        luaunit.assertEquals(response.body, 'NO SUCCESS')
        luaunit.assertEquals(clients.get('127.0.0.1'), {
            ip = '127.0.0.1',
            handler = 'ios'
        })

        -- Should redirect to success page if other request
        response = helpers.http_get('/bla', {})
        luaunit.assertEquals(response.code, 302)
        luaunit.assertEquals(response.headers['Location'], '/yeah')
        luaunit.assertEquals(clients.get('127.0.0.1'), {
            ip = '127.0.0.1',
            handler = 'ios'
        })
    end

    function Test_handlers_ios:test_run_browser()
        config.set('client_handlers', { ios = ios.browser })
        config.set('captive_static_root_url', '/static')
        config.set('captive_dynamic_root_url', '/freedomportal')

        -- Should answer NO SUCCESS to trigger CNA to open if CaptiveNetworkSupport request
        response = helpers.http_get('/bla', { 
            HTTP_USER_AGENT = 'CaptiveNetworkSupport/1.0 wispr'
        })
        luaunit.assertEquals(response.code, 200)
        luaunit.assertEquals(response.body, 'NO SUCCESS')
        luaunit.assertEquals(clients.get('127.0.0.1'), {
            ip = '127.0.0.1',
            handler = 'ios'
        })

        -- Should redirect to connecting page if other request
        response = helpers.http_get('/bla', {})
        luaunit.assertEquals(response.code, 302)
        luaunit.assertEquals(response.headers['Location'], '/static/ios/connecting.html')
        luaunit.assertEquals(clients.get('127.0.0.1'), {
            ip = '127.0.0.1',
            handler = 'ios'
        })

        -- connecting.html page shouldmark client status as connecting
        response = helpers.http_get('/freedomportal/connecting', {})
        luaunit.assertEquals(response.code, 200)
        luaunit.assertEquals(clients.get('127.0.0.1'), {
            ip = '127.0.0.1',
            handler = 'ios',
            status = 'connecting'
        })

        -- and then redirect to /freedomportal/connected which will mark client status as connected
        response = helpers.http_get('/freedomportal/connected', {})
        luaunit.assertEquals(response.code, 302)
        luaunit.assertEquals(response.headers['Location'], '/static/ios/connected.html')
        luaunit.assertEquals(clients.get('127.0.0.1'), {
            ip = '127.0.0.1',
            handler = 'ios',
            status = 'connected'
        })

        -- At this stage CaptiveNetworkSupport request should be answered with SUCCESS
        response = helpers.http_get('/bla', { 
            HTTP_USER_AGENT = 'CaptiveNetworkSupport/1.0 wispr'
        })
        luaunit.assertEquals(response.code, 200)
        luaunit.assertEquals(response.headers['Content-type'], 'text/html')
        luaunit.assertEquals(response.body, ios.SUCCESS_PAGE)

        -- And finally requests will be answered with the success page
        response = helpers.http_get('/bla', {})
        luaunit.assertEquals(response.code, 302)
        luaunit.assertEquals(response.headers['Location'], '/yeah')
    end
