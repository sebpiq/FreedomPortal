"use strict";
var util = require('util')
var path = require('path')

var pageDir = path.join(__dirname, '..', '..', 'pages')


// Base client for iOS devices
var _BaseHandler = function _BaseHandler() {}

_BaseHandler.prototype.isCaptiveNetworkSupport = function(req) {
  return req.get('User-Agent') && req.get('User-Agent').search('CaptiveNetworkSupport') !== -1
}

_BaseHandler.prototype.recognizes = function(req) {
  return this.isCaptiveNetworkSupport(req)
}


// iOS client that opens all pages in CNA
var IosCnaHandler = exports.IosCnaHandler = function IosCnaHandler() { 
  _BaseHandler.apply(this, arguments) 
}
util.inherits(IosCnaHandler, _BaseHandler)

IosCnaHandler.prototype.run = function(client, req, res, next) {
  if (this.isCaptiveNetworkSupport(req)) {
    return res.end('NO SUCCESS')
  } else next()
}


// iOS client that opens a page in CNA with a link to continue in 
// a full Safari window
var IosBrowserHandler = exports.IosBrowserHandler = function IosBrowserHandler(options) { 
  _BaseHandler.apply(this, arguments)
  this.options = options || {}
  this.options.connectedPagePath = this.options.connectedPagePath 
    || path.join(pageDir, 'ios', 'connected.html')
  this.options.connectingPagePath = this.options.connectingPagePath
    || path.join(pageDir, 'ios', 'connecting.html')
}
util.inherits(IosBrowserHandler, _BaseHandler)

IosBrowserHandler.prototype.run = function(client, req, res, next) {
  client.status = client.status || 'not-connected'

  // requests testing the connectivity of the network :
  // - when first connecting to the network, any other page than "success.html" will trigger the CNA to open.
  // - when CNA is open if "success.html" is sent the CNA will be marked as connected.
  if (this.isCaptiveNetworkSupport(req)) {
    if (client.status === 'not-connected')
      res.end('NO SUCCESS')
    else
      res.sendFile(path.join(pageDir, 'ios', 'success.html'))

  // Other requests start the connection process.
  // 1. we first return the "connecting.html" page
  // 2. "connecting.html" sends a request to "/node-captive-portal/connecting", which will
  //    change status from "not-connected" to "connecting" and cause next CaptiveNetworkSupport
  //    request to be answered with "success.html" page.
  // 3. navigates to "connected.html"
  } else if (client.status === 'not-connected') {
    if (req.path === '/node-captive-portal/connecting') {
      client.status = 'connecting'
      res.status(200).end()
    } else res.sendFile(this.options.connectingPagePath)

  // 4. we return the "connected.html" page. At this stage the CNA should be marked as "connected".
  //    The page displays a link which allows to redirect the user to a full browser.
  } else if (client.status === 'connecting') {
    if (req.path === '/node-captive-portal/connected') {
      client.status = 'connected'
      res.sendFile(this.options.connectedPagePath)
    } else next()

  // 5. when client is connected, we just pass all the requests without handling them
  } else if (client.status === 'connected') next()
}