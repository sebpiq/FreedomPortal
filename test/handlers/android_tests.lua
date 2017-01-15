local luaunit = require('luaunit')
local android = require('freedomportal.handlers.android')
local clients = require('freedomportal.clients')
local config = require('freedomportal.config')

Test_handlers_android = {}

    function Test_handlers_android:setUp()
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

    function Test_handlers_android:test_run_cna()
        config.set('client_handlers', { android = android.cna })
        response = helpers.http_get('/blo', { 
            HTTP_USER_AGENT = 'Mozilla/5.0 (Linux; Android 4.0.4; Galaxy Nexus Build/IMM76B) AppleWebKit/535.19 (KHTML, like Gecko) Chrome/18.0.1025.133 Mobile Safari/535.19 '
        })

        -- Should redirect directly to success url
        luaunit.assertEquals(response.code, 302)
        luaunit.assertEquals(response.headers['Location'], '/yeah')
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


--[[

describe('client-handlers.android', function() {

  describe('AndroidBrowserHandler', function() {

    it('should handle requests as expected', function(done) {
      var app = express()
      var client = new Client('11:11:11:11:11:11', '127.0.0.1')      
      var captivePortal = new CaptivePortal([ 
        new android.AndroidBrowserHandler({
          connectedPagePath: path.join(__dirname, 'pages', 'android', 'connected.html')
        }) 
      ])

      captivePortal.clients[client.mac] = client
      captivePortal.on('error', function(err) { done(err) })
      app.use(captivePortal.handler)
      app.get('/bla', function(req, res) { res.end('blabla') })

      async.series([
        function(next) {
          request(app)
            .get('/generate_204')
            .set('User-Agent', 'Android')
            .expect(200)
            .end(function(err, res) {
              if (err) return next(err)
              assert.equal(client.status, 'not-connected')
              assert.equal(res.text, 'CONNECTED')
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
              assert.equal(res.text, '')
              next()
            })
        },
        function(next) {
          request(app)
            .get('/generate_204')
            .expect(204)
            .end(function(err, res) {
              if (err) return next(err)
              assert.equal(client.status, 'connected')
              assert.equal(res.text, '')
              next()
            })
        }
      ], done)
    })

  })


})

]]