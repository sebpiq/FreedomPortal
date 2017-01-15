package.path = package.path .. ';./freedomportal/?.lua'

helpers = require('test.helpers')

local luaunit = require('luaunit')
local clients_tests = require('test.clients_tests')
local utils_tests = require('test.utils_tests')
local handlers_main_tests = require('test.handlers.main_tests')
local handlers_android_tests = require('test.handlers.android_tests')


os.exit(luaunit.LuaUnit.run())