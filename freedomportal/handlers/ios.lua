local config = require('freedomportal.config')

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

local function run_browser(client_infos, wsapi_env)
    -- requests testing the connectivity of the network :
    -- * when first connecting to the network, any other page than "success.html" will trigger 
    --      the CNA to open.
    -- * when CNA is open if "success.html" is sent the CNA will be marked as connected.
    if is_captive_network_support(wsapi_env) then
        if client_infos.status == nil then
            return { code = 200, body = 'NO SUCCESS' }
        else
            return { code = 200, headers = { ['Content-type'] = 'text/html' }, body = SUCCESS_PAGE }
        end

    -- Other requests start the connection process.
    -- 1. we first return the "connecting.html" page
    -- 2. "connecting.html" sends a request to "/connecting", which will
    --      * change status from "nil" to "connecting" and cause next CaptiveNetworkSupport
    --          request to be answered with "success.html" page.
    --      * navigate to "/connected" which will also cause iOS to send a new 
    --          CaptiveNetworkSupport request.
    elseif client_infos.status == nil then
        if wsapi_env.PATH_INFO == config.get('captive_dynamic_root_url') .. '/connecting' then
            return { code = 200, client_infos = { status = 'connecting' } }
        else 
            local location = config.get('captive_static_root_url') .. '/ios/connecting.html'
            return { code = 302, headers = { Location = location } }
        end

    -- 3. A request is sent to "/connected" we return the "connected.html" page. 
    --      At this stage the iOS CNA should think that the connection is done.
    --      The page displays a link which allows to redirect the user to a full browser.
    elseif client_infos.status == 'connecting' then
        if wsapi_env.PATH_INFO == config.get('captive_dynamic_root_url') .. '/connected' then
            local location = config.get('captive_static_root_url') .. '/ios/connected.html'
            return { code = 302, client_infos = { status = 'connected' }, headers = { Location = location } }
        else -- TODO : Does this ever happen?
            return { code = 'PASS' }
        end

    -- 4. when client is connected, we just pass all the requests without handling them
    elseif client_infos.status == 'connected' then 
        return { code = 'PASS' }
    end
end

return {
    SUCCESS_PAGE = SUCCESS_PAGE,
    cna = { run = run_cna, recognizes = recognizes },
    browser = { run = run_browser, recognizes = recognizes },
}