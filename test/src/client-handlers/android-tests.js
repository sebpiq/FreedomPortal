var assert = require('assert')
var util = require('util')
var path = require('path')
var _ = require('underscore')
var request = require('supertest')
var express = require('express')
var async = require('async')

var CaptivePortal = require('../../../src/CaptivePortal')
var Client = require('../../../src/Client')
var android = require('../../../src/client-handlers/android')

describe('client-handlers.android', function() {

  describe('AndroidCnaHandler', function() {

    it('should handle requests as expected', function(done) {
      var app = express()
      var client = new Client('11:11:11:11:11:11', '127.0.0.1')      
      var captivePortal = new CaptivePortal([ new android.AndroidCnaHandler() ])

      captivePortal.clients[client.mac] = client
      captivePortal.on('error', function(err) { done(err) })
      app.use(captivePortal.handler)
      app.get('/bla', function(req, res) { res.end('blabla') })

      request(app)
        .get('/bla')
        .expect(200)
        .end(function(err, res) {
          if (err) return done(err)
          assert.equal(res.text, 'blabla')
          done()
        })
    })

  })

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
