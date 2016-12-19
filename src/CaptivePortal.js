"use strict";
var fs = require('fs')
var EventEmitter = require('events').EventEmitter
var util = require('util')
var exec = require('child_process').exec
var _ = require('underscore')
var utils = require('./utils')
var Client = require('./Client')

var CaptivePortal = module.exports = function CaptivePortal(clientHandlers, options) {
  EventEmitter.apply(this)
  this.clientHandlers = clientHandlers
  this.options = options || {}
  this.options.interval = this.options.interval || 3000
  this.options.interface = this.options.interface || 'wlan0'
  this.clients = {}
  this.handler = this.handler.bind(this)
}
util.inherits(CaptivePortal, EventEmitter)

CaptivePortal.prototype.start = function(done) {
  var self = this
  var _refresh = this.refresh.bind(this, function(err) {
    if (err) self.emit('error', err)
  })
  this._interval = setInterval(_refresh, this.options.interval)
  _refresh()
  done()
}

CaptivePortal.prototype.stop = function() {
  clearInterval(this._interval)
}

CaptivePortal.prototype.handler = function(req, res, next) {
  var self = this
  var client = this._getClientByIp(req.connection.remoteAddress)

  // Once the client is created, we try to assign it a suitable handler
  var _onceClient = function() {
    if (!client.handler) {
      self.clientHandlers.some(function(clientHandler) {
        if (clientHandler.recognizes(req)) {
          client.handler = clientHandler.run.bind(clientHandler, client)
          return true
        } else return false
      })
    }

    if (client.handler) 
      client.handler(req, res, next)
    else next()
  }

  // If the client is not known, but still we receive a request from it, 
  // then we refresh the clients.
  if (!client) {
    this.refresh(function(err) {
      if (err) 
        self._returnError(err, res)
      else {
        client = self._getClientByIp(req.connection.remoteAddress)
        if (client)
          _onceClient()
        // This should actually never happen
        else 
          self._returnError(new Error('client with received ip could not be found'), res)
      }
    })

  // If the client is known we simply call the handler
  } else _onceClient()
}

CaptivePortal.prototype.refresh = function(done) {
  var self = this
  // List associations IPv4 <-> MAC
  fs.readFile('/proc/net/arp', function(err, arpContent) {
    if (err) return done(err)
    // List connected clients (MAC addresses)
    exec('iwinfo ' + self.options.interface + ' assoclist', function(err, iwinfoResult, stderr) {
      if (err || stderr) return done(err || new Error(stderr))
      self._updateClients(utils.iwinfoParse(iwinfoResult), utils.arpParse(arpContent.toString('utf8')))
      done()
    })
  })
}

CaptivePortal.prototype._updateClients = function(macList, macIpMapping) {
  var self = this

  // Detect disconnections  
  Object.keys(this.clients).forEach(function(mac) {
    if (macList.indexOf(mac) === -1)
      self._forgetClient(mac)
  })

  // Detect new connections
  macList.forEach(function(mac) {
    if (!self.clients.hasOwnProperty(mac)) {
      if (!macIpMapping[mac])
        return console.warn(mac + ' doesn\'t have an ip address')
      self._addClient(new Client(mac, macIpMapping[mac]))
    }
  })
}

CaptivePortal.prototype._addClient = function(client) {
  this.clients[client.mac] = client
  client.once('forget', this._forgetClient.bind(this, client.mac))
  this.emit('connection', client)
}

CaptivePortal.prototype._forgetClient = function(mac) {
  var client = this.clients[mac]
  if (!client) return
  delete this.clients[mac]
  client.removeAllListeners()
  this.emit('disconnection', client)
}

CaptivePortal.prototype._getClientByIp = function(ip) {
  ip = utils.getIPv4Address(ip)
  return _.chain(this.clients)
    .values()
    .find(function(client) { return client.ip === ip })
    .value()
}

CaptivePortal.prototype._returnError = function(err, res) {
  res.status(500).end()
  this.emit('error', err)
}
