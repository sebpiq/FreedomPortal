"use strict";
var util = require('util')
var EventEmitter = require('events').EventEmitter


var Client = module.exports = function Client(mac, ip) {
  EventEmitter.apply(this)
  this.mac = mac
  this.ip = ip
  this.handler = null
}
util.inherits(Client, EventEmitter)