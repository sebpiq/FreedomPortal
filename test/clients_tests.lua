package.path = package.path .. ';../freedomportal/?.lua'

local luaunit = require('luaunit')
local clients = require('freedomportal.clients')

-- Utility function to make random strings
local function make_string(l)
    if l < 1 then return nil end
    local s = ""
    for i = 1, l do
        s = s .. string.char(math.random(32, 126))
    end
    return s
end

Test_clients = {}
    function Test_clients:setUp()
        local clients_file = io.open(clients.CLIENTS_FILE_PATH, 'w')
        clients_file:write('bloblo')
        clients_file:close()
    end

    function Test_clients:test_read_write_clients_file_concurrent()
        local read_process1 = assert(io.popen('lua test/read_clients_file.lua', 'r'))
        local write_process = assert(io.popen('lua test/write_clients_file.lua', 'r'))
        local read_process2 = assert(io.popen('lua test/read_clients_file.lua', 'r'))
        local output1 = read_process1:read('*all')
        local output2 = read_process2:read('*all')
        read_process1:close()
        read_process2:close()
        write_process:close()
        luaunit.assertTrue(output1 == 'blabla\n' or output1 == 'bloblo\n')
        luaunit.assertTrue(output2 == 'blabla\n' or output2 == 'bloblo\n')
    end

    function Test_clients:test_read_clients_file_long()
        -- Writing long string to the file
        local clients_file = io.open(clients.CLIENTS_FILE_PATH, 'w')
        local long_string = make_string(2000)
        clients_file:write(long_string)
        clients_file:close()
        
        -- using our function to read the string
        luaunit.assertEquals(clients._read_clients_file(), long_string)
    end

    function Test_clients:test_save()
        local clients_table = {
            ['AA:BB:CC:DD:EE:FF'] = { 
                ip = '77.99.88.66',
                status = 'bla',
            },
            ['11:22:33:44:55:66'] = {
                ip = '1.2.3.4',
                some_attr = 'blo'
            }, 
        }
        clients.save(clients_table)
        local file = io.open(clients.CLIENTS_FILE_PATH, 'r')

        local actual = file:read('*a')
        local expected = [[
mac AA:BB:CC:DD:EE:FF status bla ip 77.99.88.66 
mac 11:22:33:44:55:66 some_attr blo ip 1.2.3.4 
]]
        luaunit.assertEquals(actual, expected)
    end

    function Test_clients:test_get()
        local file = io.open(clients.CLIENTS_FILE_PATH, 'w')
        file:write([[
mac AA:BB:CC:DD:EE:FF status bla ip 77.99.88.66 
mac 11:22:33:44:55:66 some_attr blo ip 1.2.3.4 
]])
        file:close()
        
        local actual = clients.get()
        local expected = {
            ['AA:BB:CC:DD:EE:FF'] = { 
                ip = '77.99.88.66',
                status = 'bla',
            },
            ['11:22:33:44:55:66'] = {
                ip = '1.2.3.4',
                some_attr = 'blo'
            }, 
        }
        luaunit.assertEquals(actual, expected)
    end

os.exit(luaunit.LuaUnit.run())