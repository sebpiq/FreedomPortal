var path = require('path')
var express = require('express')
var cp = require('captive-portal')
var https = require('../src/https')
var config

if (process.argv.length !== 3) {
  console.error('usage : ' + path.basename(process.argv[1]) + ' <config.js>')
  process.exit(1)
}
config = require(process.argv[2])

// Select the web environment in which the user will navigate the captive portal
if (config.webEnv === 'cna')
  cp.CaptivePortal.clientClasses = [cp.CnaAndroidClient, cp.CnaIosClient]
else if (config.webEnv === 'full-browser')
  cp.CaptivePortal.clientClasses = [cp.SafariIosClient, cp.BrowserAndroidClient]
else
  console.error('invalid value "' + config.webEnv + '" for config.webEnv')

// Start http server with captive portal
var httpApp = express()
var captivePortal = new cp.CaptivePortal()
httpApp.use(captivePortal.handler)
httpApp.use('/', express.static(config.wwwDir))
httpApp.get('*', function(req, res) { res.redirect('/') })

// https redirection + starting everything
https.createServer({ redirectUrl: 'http://a.co/', certsDir: path.join(__dirname, '../certs') }, function() {
  httpApp.listen(80, function() {
    console.log('Captive portal server started in mode "' + config.webEnv + '" ')
    console.log('Serving contents of folder "' + config.wwwDir + '"')
  })
})
