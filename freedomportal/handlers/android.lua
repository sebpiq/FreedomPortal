local config = require('freedomportal.config')

local function recognizes(wsapi_env)
    return wsapi_env.HTTP_USER_AGENT and wsapi_env.HTTP_USER_AGENT:match('Android')
end

-- Android client that opens all pages in CNA
local function run_cna(client_infos, wsapi_env)
    return { code = 'PASS' }
end

-- Android client only dislay a message in CNA and a button to close itself
local function run_browser(client_infos, wsapi_env)

    -- requests testing the connectivity of the network :
    -- * when first connecting to the network, any other HTTP response than 204 will trigger 
    --      the CNA to open and display the responded page.
    -- * when CNA is open if HTTP 204 is sent the CNA will close
    if wsapi_env.PATH_INFO == '/generate_204' then
        if client_infos.status == nil then
            local location = config.get('captive_static_root_url') .. '/android/connected.html'
            return { code = 302, headers = { Location = location } }
        else
            return { code = 204 }
        end
      
    -- On "connected.html", when the user clicks on the link, subsequent connectivity 
    -- checks will be answered with 204, which will close the CNA.
    elseif client_infos.status == nil then
        if wsapi_env.PATH_INFO == config.get('captive_dynamic_root_url') .. '/connected' then
            return { code = 200, client_infos = { status = 'connected' } }
        else -- TODO : Does this ever happen?
            return { code = 200 }
        end

    else 
        return { code = 'PASS' }
    end
end

return {
    cna = { run = run_cna, recognizes = recognizes },
    browser = { run = run_browser, recognizes = recognizes },
}