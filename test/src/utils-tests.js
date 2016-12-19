var assert = require('assert')
var fs = require('fs')
var path = require('path')
var utils = require('../../src/utils')

describe('utils', function() {

  describe('arpParse', function() {
    
    it('should return a list of mappings IP -> MAC', function() {
      var arpSample = fs.readFileSync(path.join(__dirname, '..', 'samples', 'arp.txt')).toString('utf8')
      var results = utils.arpParse(arpSample)
      assert.deepEqual(results, {
        '84:85:06:6C:01:51': '192.168.8.117',
        'C4:85:08:B2:73:DE': '192.168.8.166' 
      })
    })
  })

  describe('iwinfoParse', function() {
    
    it('should return a list of MAC', function() {
      var iwinfoSample = fs.readFileSync(path.join(__dirname, '..', 'samples', 'iwinfo.txt')).toString('utf8')
      var results = utils.iwinfoParse(iwinfoSample)
      assert.deepEqual(results, ['C4:85:08:B2:73:DE', '84:85:06:6C:01:51'])
    })
  })

  describe('getIPv4Address', function() {

    it('should return identical address if already IPv4', function() {
      assert.equal(utils.getIPv4Address('192.168.8.1'), '192.168.8.1')
    })

    it('should get the IPv4 if IPv4-mapped IPv6 addresses', function() {
      assert.equal(utils.getIPv4Address('::ffff:192.168.8.166'), '192.168.8.166')
    })

  })

  describe('macRegexp', function() {

    it('should recognize valid mac addresses', function() {
      var matched
      matched = utils.macRegexp.exec('c4:85:08:b2:73:de')
      assert.equal(matched[2], 'c4:85:08:b2:73:de')
      matched = utils.macRegexp.exec('84:85:06:6C:01:51')
      assert.equal(matched[2], '84:85:06:6C:01:51')
      matched = utils.macRegexp.exec('c4:85:08:b2:73:de ')
      assert.equal(matched[2], 'c4:85:08:b2:73:de')
      matched = utils.macRegexp.exec(' c4:85:08:b2:73:de')
      assert.equal(matched[2], 'c4:85:08:b2:73:de')
    })

    it('should reject unvalid mac addresses', function() {
      var matched
      matched = utils.macRegexp.exec('4:85:08:b2:73:de')
      assert.equal(matched, null)
      matched = utils.macRegexp.exec('84:85A:06:6C:01:51')
      assert.equal(matched, null)
      matched = utils.macRegexp.exec('84:85:%6:6C:01:51')
      assert.equal(matched, null)
    })

  })

})