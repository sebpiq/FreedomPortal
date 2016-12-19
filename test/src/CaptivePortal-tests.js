var assert = require('assert')
var util = require('util')
var _ = require('underscore')
var request = require('supertest')
var express = require('express')

var CaptivePortal = require('../../src/CaptivePortal')
var Client = require('../../src/Client')

describe('CaptivePortal', function() {

  describe('handler', function() {

    var _testHandler = function(onCaptivePortal, done) {
      var app = express()
      
      // Create a fake client
      var client = new Client('11:11:11:11:11:11', '127.0.0.1')
      
      // Create a captive portal with fake client handlers 
      var captivePortal = new CaptivePortal([
        {
          recognizes: function(req) { return (req.path === '/bla') },
          run: function(client, req, res, next) { res.end('blabla') }
        },
        {
          recognizes: function(req) { return (req.path === '/blo') },
          run: function(client, req, res, next) { res.end('bloblo') }
        }
      ])

      captivePortal.on('error', function(err) { done(err) })
      app.use(captivePortal.handler)
      onCaptivePortal(captivePortal, client)

      request(app)
        .get('/blo')
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          assert.equal(res.text, 'bloblo')
          // Test that client got the right handler assigned
          client.handler(null, { 
            end: function(val) { 
              assert.equal(val, 'bloblo')
              done() 
            } 
          }, null)
        })
    }

    it('should assign a known client a handler on first request', function(done) {
      _testHandler(function(captivePortal, client) {
        captivePortal.clients[client.mac] = client
      }, done)
    })

    it('should refresh clients if client not known when receiving a first request', function(done) {
      var called = false
      _testHandler(function(captivePortal, client) {
          captivePortal.refresh = function(refreshDone) {
            called = true
            this.clients[client.mac] = client
            refreshDone()
          }
        }, function(err) {
          if (err) return done(err)
          assert.equal(called, true)
          done()
        }
      )
    })

  })

  describe('forget client', function() {

    it('should forget the client when client emits "forget"', function() {
      var captivePortal = new CaptivePortal()
      var client1 = new Client('AA:BB:CC:DD:EE:FF', '1.2.3.4')
      var client2 = new Client('11:BB:CC:DD:EE:FF', '6.6.6.6')
      captivePortal._addClient(client1)
      captivePortal._addClient(client2)

      assert.deepEqual(
        _.keys(captivePortal.clients), ['AA:BB:CC:DD:EE:FF', '11:BB:CC:DD:EE:FF'])

      captivePortal.clients['AA:BB:CC:DD:EE:FF'].emit('forget')
      assert.deepEqual(_.keys(captivePortal.clients), ['11:BB:CC:DD:EE:FF'])
    })

  })

  describe('_getClientByIp', function() {

    it('should find and return the client with given ip', function() {
      var captivePortal = new CaptivePortal()
      var client1 = new Client('AA:BB:CC:DD:EE:FF', '1.2.3.4')
      var client2 = new Client('11:BB:CC:DD:EE:FF', '6.6.6.6')
      captivePortal._addClient(client1)
      captivePortal._addClient(client2)
      assert.equal(captivePortal._getClientByIp('1.2.3.4'), client1)
      assert.equal(captivePortal._getClientByIp('6.6.6.6'), client2)
      assert.equal(captivePortal._getClientByIp('7.8.9.0'), null)
    })

  })

  describe('_updateClients', function() {

    it('should handle connection/disconnections', function() {
      var captivePortal = new CaptivePortal()
      var received = []
      captivePortal.on('connection', function(client) { received.push([ 'c', client.mac ]) })
      captivePortal.on('disconnection', function(client) { received.push([ 'd', client.mac ]) })
      assert.deepEqual(captivePortal.clients, {})

      // New connection
      captivePortal._updateClients(['11:22:33:44:55:66'], {
        'AA:BB:CC:DD:EE:FF': '2.2.2.2', 
        '11:22:33:44:55:66': '1.1.1.1'
      })
      assert.deepEqual(received, [['c', '11:22:33:44:55:66']])
      assert.deepEqual(_.keys(captivePortal.clients), ['11:22:33:44:55:66'])
      assert.deepEqual(captivePortal.clients['11:22:33:44:55:66'].ip, '1.1.1.1')

      // Another new connection
      captivePortal._updateClients(['AA:BB:CC:DD:EE:FF', '11:22:33:44:55:66'], {
        'AA:BB:CC:DD:EE:FF': '2.2.2.2', 
        '11:22:33:44:55:66': '1.1.1.1'
      })
      assert.deepEqual(received, [['c', '11:22:33:44:55:66'], ['c', 'AA:BB:CC:DD:EE:FF']])
      assert.deepEqual(_.keys(captivePortal.clients), ['11:22:33:44:55:66', 'AA:BB:CC:DD:EE:FF'])
      assert.deepEqual(captivePortal.clients['11:22:33:44:55:66'].ip, '1.1.1.1')
      assert.deepEqual(captivePortal.clients['AA:BB:CC:DD:EE:FF'].ip, '2.2.2.2')

      // Disconnection
      captivePortal._updateClients(['AA:BB:CC:DD:EE:FF'], {
        'AA:BB:CC:DD:EE:FF': '2.2.2.2', 
        '11:22:33:44:55:66': '1.1.1.1'
      })
      assert.deepEqual(received, [
        ['c', '11:22:33:44:55:66'], ['c', 'AA:BB:CC:DD:EE:FF'], ['d', '11:22:33:44:55:66']])
      assert.deepEqual(_.keys(captivePortal.clients), ['AA:BB:CC:DD:EE:FF'])
      assert.deepEqual(captivePortal.clients['AA:BB:CC:DD:EE:FF'].ip, '2.2.2.2')  
    })
    
  })

})