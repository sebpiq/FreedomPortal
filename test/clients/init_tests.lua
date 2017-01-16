local luaunit = require('luaunit')
local posix = require('posix')
local config = require('freedomportal.config')
local clients = require('freedomportal.clients.init')

dummy_get_connected_clients = {
    clients_table = {},
    run = function() return dummy_get_connected_clients.clients_table end
}

Test_clients = {}

    function Test_clients:setUp()
        helpers.setUp()
        config.set('clients_storage', helpers.dummy_clients_storage)
        config.set('get_connected_clients', dummy_get_connected_clients.run)
        dummy_get_connected_clients.clients_table = {}
    end

    function Test_clients:test_get()
        helpers.dummy_clients_storage.clients = {
            ['11:22:33:44:55:66'] = {
                ip = '1.1.1.1',
            },
            ['AA:BB:CC:DD:EE:FF'] = {
                ip = '2.2.2.2',
                some_attr = 'blo',
            },
        }

        luaunit.assertEquals(clients.get('2.2.2.2'), {
            ip = '2.2.2.2',
            some_attr = 'blo'
        })
    end

    function Test_clients:test_refresh()
        local expected = nil

        -- New connection, should create entry in client storage
        dummy_get_connected_clients.clients_table = { ['11:22:33:44:55:66'] = '1.1.1.1' }
        
        expected = {
            ['11:22:33:44:55:66'] = {
                ip = '1.1.1.1',
            },
        }
        luaunit.assertEquals(clients.refresh(), expected)
        luaunit.assertEquals(clients.get_all(), expected)

        -- Another new connection, should not modify entries of clients previously connected 
        helpers.dummy_clients_storage.clients['11:22:33:44:55:66']['some_attr'] = 'bla'
        dummy_get_connected_clients.clients_table = {
            ['AA:BB:CC:DD:EE:FF'] = '2.2.2.2', 
            ['11:22:33:44:55:66'] = '1.1.1.1',
        }

        expected = {
            ['11:22:33:44:55:66'] = {
                ip = '1.1.1.1',
                some_attr = 'bla',
            },
            ['AA:BB:CC:DD:EE:FF'] = {
                ip = '2.2.2.2',
            },
        }
        luaunit.assertEquals(clients.refresh(), expected)
        luaunit.assertEquals(clients.get_all(), expected)

        -- Disconnection, should not modify entries of clients still connected
        helpers.dummy_clients_storage.clients['AA:BB:CC:DD:EE:FF']['other_attr'] = 'blo'
        dummy_get_connected_clients.clients_table = { ['AA:BB:CC:DD:EE:FF'] = '2.2.2.2' }
        
        expected = {
            ['AA:BB:CC:DD:EE:FF'] = {
                ip = '2.2.2.2',
                other_attr = 'blo',
            },
        }
        luaunit.assertEquals(clients.refresh(), expected)
        luaunit.assertEquals(clients.get_all(), expected)
    end

    function Test_clients:test_set_fields()
        local expected = nil

        -- Initialize clients
        dummy_get_connected_clients.clients_table = {
            ['AA:BB:CC:DD:EE:FF'] = '2.2.2.2', 
            ['11:22:33:44:55:66'] = '1.1.1.1',
        }
        clients.refresh()

        -- Set attributes
        expected = {
            ip = '2.2.2.2',
            bla = '12345',
            blo = '67890',
        }
        luaunit.assertEquals(clients.set_fields('2.2.2.2', {bla = '12345', blo = '67890'}), expected)
        luaunit.assertEquals(clients.get_all(), {
            ['11:22:33:44:55:66'] = {
                ip = '1.1.1.1',
            },
            ['AA:BB:CC:DD:EE:FF'] = expected,
        })

        expected = {
            ip = '1.1.1.1',
            yyy = 'blo',
        }
        luaunit.assertEquals(clients.set_fields('1.1.1.1', {yyy = 'blo'}), expected)
        luaunit.assertEquals(clients.get_all(), {
            ['11:22:33:44:55:66'] = expected,
            ['AA:BB:CC:DD:EE:FF'] = {
                ip = '2.2.2.2',
                bla = '12345',
                blo = '67890',
            },
        })

        expected = {
            ip = '2.2.2.2',
            bla = 'uuu',
            blo = '67890',
        }
        luaunit.assertEquals(clients.set_fields('2.2.2.2', {bla = 'uuu'}), expected)
        luaunit.assertEquals(clients.get_all(), {
            ['11:22:33:44:55:66'] = {
                ip = '1.1.1.1',
                yyy = 'blo',
            },
            ['AA:BB:CC:DD:EE:FF'] = expected,
        })
    end

    function Test_clients:test_set_noop_if_ip_not_found()
        -- Initialize clients
        dummy_get_connected_clients.clients_table = {
            ['AA:BB:CC:DD:EE:FF'] = '2.2.2.2', 
            ['11:22:33:44:55:66'] = '1.1.1.1',
        }
        clients.refresh()

        -- Set attributes
        clients.set_fields('3.3.3.3', {bla = '12345'})
        luaunit.assertEquals(clients.get_all(), {
            ['11:22:33:44:55:66'] = {
                ip = '1.1.1.1',
            },
            ['AA:BB:CC:DD:EE:FF'] = {
                ip = '2.2.2.2',
            },
        })
    end