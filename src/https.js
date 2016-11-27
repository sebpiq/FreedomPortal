var https = require('https')
var fs = require('fs')
var path = require('path')
var express = require('express')

// Start an HTTPS server with self-signed certificates
// This server simply redirects to our http server. Options are :
//  - redirectUrl : required. The url to redirect to. 
exports.createServer = function(options, done) {
  var httpsApp = express()
  var httpsServer = https.Server({
    key: fs.readFileSync(path.join(__dirname, '../certs/server.key'), 'utf8'),
    cert: fs.readFileSync(path.join(__dirname, '../certs/server.crt'), 'utf8'),
    passphrase: 'blabla',
    requestCert: true
  }, httpsApp)
  httpsApp.get('*', function(req, res) { res.redirect(options.redirectUrl) })
  httpsServer.listen(443, done)
}