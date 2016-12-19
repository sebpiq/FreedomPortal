var assert = require('assert')
var util = require('util')
var path = require('path')
var _ = require('underscore')
var request = require('supertest')
var express = require('express')
var async = require('async')

var CaptivePortal = require('../../../src/CaptivePortal')
var Client = require('../../../src/Client')
var ios = require('../../../src/client-handlers/ios')

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