package.path = package.path .. ';../freedomportal/?.lua'

local luaunit = require('luaunit')
local utils = require('freedomportal.utils')

Test_utils = {}

    function Test_utils:test_find_IPv4()
        luaunit.assertEquals(utils.find_IPv4('127.0.0.1'), '127.0.0.1')
        luaunit.assertEquals(utils.find_IPv4('255.255.255.255'), '255.255.255.255')
        luaunit.assertEquals(utils.find_IPv4('0.0.0.0'), '0.0.0.0')
        luaunit.assertEquals(utils.find_IPv4('iuyiuy 12.126.99.1'), '12.126.99.1')
        luaunit.assertEquals(utils.find_IPv4('12.126.99.1 nsknkjnkj n'), '12.126.99.1')
        
        luaunit.assertEquals(utils.find_IPv4(''), nil)
        luaunit.assertEquals(utils.find_IPv4('poi poi poi poi'), nil)
        luaunit.assertEquals(utils.find_IPv4('666.44.55.1'), nil)
        luaunit.assertEquals(utils.find_IPv4('666.44.55'), nil)
    end

    function Test_utils:test_find_MAC()
        luaunit.assertEquals(utils.find_MAC('11:22:33:44:55:66'), '11:22:33:44:55:66')
        luaunit.assertEquals(utils.find_MAC('aa:bb:cc:dd:ee:ff'), 'AA:BB:CC:DD:EE:FF')
        luaunit.assertEquals(utils.find_MAC('aa:22:CC:44:ee:66'), 'AA:22:CC:44:EE:66')
        luaunit.assertEquals(utils.find_MAC('ff fytf ytf aa:22:CC:44:ee:66 uuuu ii'), 'AA:22:CC:44:EE:66')

        luaunit.assertEquals(utils.find_MAC(''), nil)
        luaunit.assertEquals(utils.find_MAC('poi poi poi poi'), nil)
        luaunit.assertEquals(utils.find_MAC('11:22:33:44:55:'), nil)
        luaunit.assertEquals(utils.find_MAC('11:22:33:777:55:ee'), nil)
    end

    function Test_utils:test_arp_parse()
        local actual = utils.arp_parse('./test/samples/arp.txt')
        local expected = {
            ['84:85:06:6C:01:51'] = '192.168.8.117',
            ['C4:85:08:B2:73:DE'] = '192.168.8.166', 
        }
        luaunit.assertEquals(actual, expected)
    end

os.exit(luaunit.LuaUnit.run())