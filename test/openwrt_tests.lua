package.path = package.path .. ';../freedomportal/?.lua'

local luaunit = require('luaunit')
local openwrt = require('freedomportal.openwrt')

Test_openwrt = {}

    function Test_openwrt:test_arp_parse()
        local actual = openwrt.arp_parse('./test/samples/arp.txt')
        local expected = {
            ['84:85:06:6C:01:51'] = '192.168.8.117',
            ['C4:85:08:B2:73:DE'] = '192.168.8.166', 
        }
        luaunit.assertEquals(actual, expected)
    end

os.exit(luaunit.LuaUnit.run())