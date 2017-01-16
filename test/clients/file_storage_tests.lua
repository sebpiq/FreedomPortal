local luaunit = require('luaunit')
local posix = require('posix')
local config = require('freedomportal.config')
local clients_file_storage = require('freedomportal.clients.file_storage')

-- Utility function to make random strings
local function make_string(l)
    if l < 1 then return nil end
    local s = ""
    for i = 1, l do
        s = s .. string.char(math.random(32, 126))
    end
    return s
end

Test_clients_file_storage = {}

    function Test_clients_file_storage:setUp()
        config.set('clients_storage', clients_file_storage)
    end

    function Test_clients_file_storage:test_read_write_clients_file_concurrent()
        helpers.file_write(config.get('clients_file_path'), 'mac po ip pu \n')

        local read_process1 = assert(io.popen('lua test/samples/read_clients_file.lua', 'r'))
        local write_process = assert(io.popen('lua test/samples/write_clients_file.lua', 'r'))
        local read_process2 = assert(io.popen('lua test/samples/read_clients_file.lua', 'r'))
        local output1 = read_process1:read('*all')
        local output2 = read_process2:read('*all')
        read_process1:close()
        read_process2:close()
        write_process:close()
        luaunit.assertTrue(output1 == 'mac ba ip bi \n\n' or output1 == 'mac po ip pu \n\n')
        luaunit.assertTrue(output2 == 'mac ba ip bi \n\n' or output2 == 'mac po ip pu \n\n')
    end

    function Test_clients_file_storage:test_posix_read_all_long_file()
        -- Writing long string to the file
        local long_string = make_string(2000)
        helpers.file_write('/tmp/test_read_file_long_file', long_string)
        
        -- using our function to read the string
        local fd = posix.open('/tmp/test_read_file_long_file', posix.O_RDONLY)
        luaunit.assertEquals(clients_file_storage._posix_read_all(fd), long_string)
    end

    function Test_clients_file_storage:test_serialize()
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
        local expected = [[
mac AA:BB:CC:DD:EE:FF status bla ip 77.99.88.66 
mac 11:22:33:44:55:66 some_attr blo ip 1.2.3.4 
]]
        luaunit.assertEquals(clients_file_storage._serialize(clients_table), expected)
    end

    function Test_clients_file_storage:test_deserialize()
        local clients_serialized = [[
mac AA:BB:CC:DD:EE:FF status bla ip 77.99.88.66 
mac 11:22:33:44:55:66 some_attr blo ip 1.2.3.4 
]]
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
        luaunit.assertEquals(clients_file_storage._deserialize(clients_serialized), expected)
    end

    function Test_clients_file_storage:test_replace_all()
        local clients_serialized = [[
mac AA:BB:CC:DD:EE:FF status bla ip 77.99.88.66 
]]
        helpers.file_write(config.get('clients_file_path'), clients_serialized)

        clients_file_storage.replace_all(function(clients_table)
            luaunit.assertEquals(clients_table, {
                ['AA:BB:CC:DD:EE:FF'] = { 
                    ip = '77.99.88.66',
                    status = 'bla',
                }
            })
            return {
                ['AA:BB:CC:DD:EE:FF'] = { 
                    ip = '77.99.88.66',
                    status = 'bli',
                },
                ['11:22:33:44:55:66'] = {
                    ip = '1.2.3.4',
                    some_attr = 'blo'
                },
            }
        end)
        luaunit.assertEquals(helpers.file_read(config.get('clients_file_path')), [[
mac AA:BB:CC:DD:EE:FF status bli ip 77.99.88.66 
mac 11:22:33:44:55:66 some_attr blo ip 1.2.3.4 
]])
        
        -- Try with new contents shorter, all extra chars replaced by whitespace
        clients_file_storage.replace_all(function(clients_table)
            return {
                ['11:BB:22:DD:33:FF'] = { ip = '77.99.88.66' }
            }
        end)
        luaunit.assertEquals(helpers.file_read(config.get('clients_file_path')), [[
mac 11:BB:22:DD:33:FF ip 77.99.88.66 
                                                           ]])
    end

    function Test_clients_file_storage:test_get_all()
        helpers.file_write(config.get('clients_file_path'), [[
mac AA:BB:CC:DD:EE:FF status bla ip 77.99.88.66 
mac 11:22:33:44:55:66 some_attr blo ip 1.2.3.4 
]])
        luaunit.assertEquals(clients_file_storage.get_all(), {
            ['AA:BB:CC:DD:EE:FF'] = { 
                ip = '77.99.88.66',
                status = 'bla',
            },
            ['11:22:33:44:55:66'] = {
                ip = '1.2.3.4',
                some_attr = 'blo'
            }, 
        })
    end