"use strict";
var util = require('util')
var path = require('path')

var pageDir = path.join(__dirname, '..', '..', 'pages')


var _BaseHandler = function _BaseHandler() {}

_BaseHandler.prototype.isConnectivityCheck = function(req) {
  return req.url === '/generate_204'
}

_BaseHandler.prototype.recognizes = function(req) {
  return req.get('User-Agent') && req.get('User-Agent').search('Android|android') !== -1
}


// Android client that opens all pages in CNA
var AndroidCnaHandler = exports.AndroidCnaHandler = function AndroidCnaHandler() { 
  _BaseHandler.apply(this, arguments) 
}
util.inherits(AndroidCnaHandler, _BaseHandler)

AndroidCnaHandler.prototype.run = function(client, req, res, next) { next() }


// Android client only dislay a message in CNA and a button to close itself
var AndroidBrowserHandler = exports.AndroidBrowserHandler = function AndroidBrowserHandler(options) { 
  _BaseHandler.apply(this, arguments)
  this.options = options || {}
  this.options.connectedPagePath = this.options.connectedPagePath 
    || path.join(pageDir, 'android', 'connected.html')
  this.fakeConnectivity = false
}
util.inherits(AndroidBrowserHandler, _BaseHandler)

AndroidBrowserHandler.prototype.run = function(client, req, res, next) {
  client.status = client.status || 'not-connected'

  // requests testing the connectivity of the network :
  // - when first connecting to the network, any other HTTP response than 204 will trigger the CNA to open
  //   and display the responded page.
  // - when CNA is open if HTTP 204 is sent the CNA will close
  if (this.isConnectivityCheck(req)) {
    if (client.status === 'not-connected')
      res.sendFile(this.options.connectedPagePath)
    else
      res.status(204).end()
  
  // On "connected.html", when the user clicks on the link, subsequent connectivity 
  // checks will be answered with 204, which will close the CNA.
  } else if (client.status === 'not-connected') {
    if (req.path === '/node-captive-portal/connected') {
      client.status = 'connected'
      res.end()
    } else next()
  
  } else next()
}