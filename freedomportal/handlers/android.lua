local config = require('freedomportal.config')

local function is_connectivity_check(wsapi_env)
    return wsapi_env.PATH_INFO == '/generate_204'
end

local function recognizes(wsapi_env)
    return wsapi_env.HTTP_USER_AGENT and wsapi_env.HTTP_USER_AGENT:match('Android')
end

-- Android client that opens all pages in CNA
local function run_cna(client_infos, wsapi_env)
    return {}, 'success', nil, nil
end

-- Android client only dislay a message in CNA and a button to close itself
local function run_browser(client_infos, wsapi_env)

    -- requests testing the connectivity of the network :
    -- * when first connecting to the network, any other HTTP response than 204 will trigger the CNA to open
    --   and display the responded page.
    -- * when CNA is open if HTTP 204 is sent the CNA will close
    if is_connectivity_check(wsapi_env) then
        if client_infos.status == nil then
            local location = config.get('captive_static_root_url') .. '/android/connected.html'
            return {}, 302, { Location = location }, nil
        else
            return {}, 204, {}, nil
        end
      
    -- On "connected.html", when the user clicks on the link, subsequent connectivity 
    -- checks will be answered with 204, which will close the CNA.
    elseif client_infos.status == nil then
        if wsapi_env.PATH_INFO == config.get('captive_dynamic_root_url') .. '/connected' then
            return { status = 'connected' }, 200, {}, nil
        else -- TODO : Does this ever happen?
            return {}, 200, {}, nil
        end

    else 
        return {}, 'success', nil, nil
    end
end

return {
    cna = { run = run_cna, recognizes = recognizes },
    browser = { run = run_browser, recognizes = recognizes },
}