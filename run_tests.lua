package.path = package.path .. ';./src/?.lua'

local luaunit = require('luaunit')
local upload_tests = require('test.src.upload_tests')
local ls_tests = require('test.src.ls_tests')

os.exit(luaunit.LuaUnit.run())
