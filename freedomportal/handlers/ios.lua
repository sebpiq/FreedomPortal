local config = require('freedomportal.config')

-- CaptiveNetworkSupport requests test the connectivity of the network :
--      * when first connecting to the network, any other response than SUCCESS_PAGE 
--          will trigger the CNA to open.
--      * when CNA is open if SUCCESS_PAGE is sent the CNA will be marked as connected.
--
local SUCCESS_PAGE = '<html><head><title>Success</title></head><body>Success</body></html>'

local function is_captive_network_support(wsapi_env) 
    return wsapi_env.HTTP_USER_AGENT and wsapi_env.HTTP_USER_AGENT:match('CaptiveNetworkSupport')
end

local function recognizes(wsapi_env)
    return is_captive_network_support(wsapi_env)
end

local function run_cna(client_infos, wsapi_env)
    if is_captive_network_support(wsapi_env) then
        return { code = 200, body = 'NO SUCCESS' }
    else 
        return { code = 'PASS' }
    end
end

-- This hanler implements the following connection process : 
--      (1) First CaptiveNetworkSupport request triggers the CNA to open
--      (2) CNA is redirected to "connecting.html"
--      (3) "connecting.html" will refresh, hitting "/connecting" which will update
--          the client status to "connecting"
--      (4) Because of the refreshes, the CNA will send more CaptiveNetworkSupport requests, 
--          which will be answered with SUCCESS_PAGE, causing the CNA to be marked as connected.
--          At the same time, client status is updated to "connected"
--      (5) Next time "/connecting" is hit, it will redirect to "connected.html"
--      (6) The CNA being now marked as connected, any link to an external web page on the 
--          "connected.html" page will open in a browser window.
--
local function run_browser(client_infos, wsapi_env)

    if is_captive_network_support(wsapi_env) then
        if client_infos.status == nil then -- (1)
            return { code = 200, body = 'NO SUCCESS' }
        else -- (4)
            local updated_client_infos = nil
            if client_infos.status ~= 'connected' then
                updated_client_infos = { status = 'connected' }
            end
            return { 
                code = 200, headers = { ['Content-type'] = 'text/html' }, 
                body = SUCCESS_PAGE, client_infos = updated_client_infos 
            }
        end

    elseif wsapi_env.PATH_INFO == config.get('captive_dynamic_root_url') .. '/connecting' then
        local updated_client_infos = nil
        local location = nil

        if client_infos.status == nil or client_infos.status == 'connecting' then -- (3)
            location = config.get('captive_static_root_url') .. '/ios/connecting.html'
            if client_infos.status == nil then
                updated_client_infos = { status = 'connecting' }
            end
        elseif client_infos.status == 'connected' then -- (5)
            location = config.get('captive_static_root_url') .. '/ios/connected.html'
        else
            error('wrong client status ' .. client_infos.status)
        end

        return { code = 302, headers = { Location = location }, client_infos = updated_client_infos }

    else 
        if client_infos.status == 'connected' then 
            return { code = 'PASS' }
        else -- (2)
            local location = config.get('captive_static_root_url') .. '/ios/connecting.html'
            return { code = 302, headers = { Location = location } }
        end
    end
end

return {
    SUCCESS_PAGE = SUCCESS_PAGE,
    cna = { run = run_cna, recognizes = recognizes },
    browser = { run = run_browser, recognizes = recognizes },
}