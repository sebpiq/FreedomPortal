local iwinfo = require('iwinfo')
local utils = require('freedomportal.utils')

local INTERVAL = 1
local INTERFACE = 'wlan0'
local ARP_FILEPATH = '/proc/net/arp'

local function arp_parse(file_path)
    local clients_table = {}
    for line in io.lines(file_path, 'r') do
        local result_ip = utils.find_IPv4(line)
        local result_mac = nil
        if result_ip then
          result_mac = utils.find_MAC(line)
          if result_mac then clients_table[result_mac] = result_ip end
        end
    end
    return clients_table
end

local function get_connected_clients()
    local clients_table = {}
    -- Table {MAC -> infos} containing only currently connected clients
    local connected_clients_table = iwinfo[iwinfo.type(INTERFACE)].assoclist(INTERFACE)
    -- Table {MAC -> IP} 
    local mac_ip_table = arp_parse(ARP_FILEPATH)

    for mac, infos in pairs(connected_clients_table) do
        if type(mac_ip_table[mac]) == 'string' then
            clients_table[mac] = mac_ip_table[mac]
        else
            print('warning : couldnt find an IP mapping for MAC address ' .. mac)
        end
    end
    return clients_table
end

return {
    arp_parse = arp_parse,
    get_connected_clients = get_connected_clients,
}