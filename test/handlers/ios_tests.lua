local luaunit = require('luaunit')
local ios = require('freedomportal.handlers.ios')
local clients = require('freedomportal.clients')
local config = require('freedomportal.config')

Test_handlers_ios = {}

    function Test_handlers_ios:setUp()
        local clients_file = io.open(clients.CLIENTS_FILE_PATH, 'w')
        clients_file:write('')
        clients_file:close()
        
        config.set('redirect_success', '/yeah')
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
        luaunit.assertEquals(response.code, 302)        
        luaunit.assertEquals(response.headers['Location'], '/static/ios/success.html')

        -- And finally requests will be answered with the success page
        response = helpers.http_get('/bla', {})
        luaunit.assertEquals(response.code, 302)
        luaunit.assertEquals(response.headers['Location'], '/yeah')
    end

--[[

describe('client-handlers.ios', function() {

  describe('IosCnaHandler', function() {

    it('should handle requests as expected', function(done) {
      var app = express()
      var client = new Client('11:11:11:11:11:11', '127.0.0.1')      
      var captivePortal = new CaptivePortal([ new ios.IosCnaHandler() ])

      captivePortal.clients[client.mac] = client
      captivePortal.on('error', function(err) { done(err) })
      app.use(captivePortal.handler)
      app.get('/bla', function(req, res) { res.end('blabla') })

      async.series([
        function(next) {
          request(app)
            .get('/bla')
            .set('User-Agent', 'CaptiveNetworkSupport')
            .expect(200)
            .end(next)
        },
        function(next) {
          request(app)
            .get('/bla')
            .expect(200)
            .end(next)
        }
      ], function(err, responses) {
        if (err) return done(err)
        assert.equal(responses[0].text, 'NO SUCCESS')
        assert.equal(responses[1].text, 'blabla')
        done()
      })
    })

  })

  describe('IosBrowserHandler', function() {

    it('should handle requests as expected', function(done) {
      var app = express()
      var client = new Client('11:11:11:11:11:11', '127.0.0.1')      
      var captivePortal = new CaptivePortal([
        new ios.IosBrowserHandler({
          connectingPagePath: path.join(__dirname, 'pages', 'ios', 'connecting.html'),
          connectedPagePath: path.join(__dirname, 'pages', 'ios', 'connected.html')
        })
      ])

      captivePortal.clients[client.mac] = client
      captivePortal.on('error', function(err) { done(err) })
      app.use(captivePortal.handler)
      app.get('/bla', function(req, res) { res.end('blabla') })

      async.series([
        function(next) {
          request(app)
            .get('/bla')
            .set('User-Agent', 'CaptiveNetworkSupport')
            .expect(200)
            .end(function(err, res) {
              if (err) return next(err)
              assert.equal(client.status, 'not-connected')
              assert.equal(res.text, 'NO SUCCESS')
              next()
            })
        },
        function(next) {
          request(app)
            .get('/bla')
            .expect(200)
            .end(function(err, res) {
              if (err) return next(err)
              assert.equal(client.status, 'not-connected')
              assert.equal(res.text, 'CONNECTING')
              next()
            })
        },
        function(next) {
          request(app)
            .get('/node-captive-portal/connecting')
            .expect(200)
            .end(function(err, res) {
              if (err) return next(err)
              assert.equal(client.status, 'connecting')
              assert.equal(res.text, '')
              next()
            })
        },
        function(next) {
          request(app)
            .get('/node-captive-portal/connected')
            .expect(200)
            .end(function(err, res) {
              if (err) return next(err)
              assert.equal(client.status, 'connected')
              assert.equal(res.text, 'CONNECTED')
              next()
            })
        },
        function(next) {
          request(app)
            .get('/bla')
            .expect(200)
            .end(function(err, res) {
              if (err) return next(err)
              assert.equal(client.status, 'connected')
              assert.equal(res.text, 'blabla')
              next()
            })        
        }
      ], done)
    })

  })


})

]]