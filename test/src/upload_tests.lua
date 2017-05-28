local luaunit = require('luaunit')
local upload = require('src.upload')
local connector = require('wsapi.mock')

function run(wsapi_env)
    return upload.handler({ root_path = '/tmp' }, wsapi_env)
end
local app = connector.make_handler(run)

function random_string(len)
    local str = ''
    local chars = 'abcdefghijklmnopqrstuvwxyz'
    local char_ind
    while str:len() < len do
        char_ind = math.random(0, chars:len())
        str = str .. (chars):sub(char_ind, char_ind)
    end
    return str
end


Test_upload = {}

    function Test_upload:test_handler_several_blocks()
        local content_to_upload = random_string(10000)
        local response, request = app:post('/upload-test-lua.txt', content_to_upload, { ['Content-Type'] = 'text/plain' })

        luaunit.assertEquals(response.code, 201)
        local uploaded_content = io.open('/tmp/upload-test-lua.txt', 'r'):read('*all')
        luaunit.assertEquals(content_to_upload, uploaded_content)
    end
