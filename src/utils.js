"use strict";

var arpParse = exports.arpParse = function(str) {
  var clients = {}
  str.split('\n').forEach(function(line) {
    var resultIp = line.match(exports.ipv4Regexp)
    var resultMac
    if (resultIp) {
      resultMac = line.match(exports.macRegexp)
      if (resultMac)
        clients[resultMac[2].toUpperCase()] = resultIp[0]
    }    
  })
  return clients
}

var iwinfoParse = exports.iwinfoParse = function(str) {
  var macList = []
  str.split('\n').forEach(function(line) {
    var result = line.match(exports.macRegexp)
    if (result) macList.push(result[2].toUpperCase())
  })
  return macList
}

// Takes `ip` which is either an IPv4 address or an IPv4-mapped IPv6 address
// and returns an IPv4 address.
var getIPv4Address = exports.getIPv4Address = function(ip) {
  var matched = ip.match(exports.ipv4Regexp)
  if (!matched) throw new Error('unvalid address ' + ip)
  return matched[0]
}

// ref : http://stackoverflow.com/questions/19673544/javascript-regular-expression-on-mac-address
var macRegexp = exports.macRegexp = /(\s|^)(([A-Fa-f0-9]{2}[:]){5}[A-Fa-f0-9]{2})(\s|$)/

var ipv4Regexp = exports.ipv4Regexp = require('ip-regex').v4()