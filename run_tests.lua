local luaunit = require('luaunit')
local clients_tests = require('test.clients_tests')
local utils_tests = require('test.utils_tests')
local handlers_main_tests = require('test.handlers.main_tests')

os.exit(luaunit.LuaUnit.run())