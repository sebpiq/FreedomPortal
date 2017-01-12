package.path = package.path .. ';../freedomportal/?.lua'

local clients = require('freedomportal.clients')
local utils = require('freedomportal.utils')

local posix = require('posix')
local iwinfo = require('iwinfo')

local INTERVAL = 1
local INTERFACE = 'wlan0'
local ARP_FILEPATH = '/proc/net/arp'

while true do
    clients.refresh(function()
        -- Table {MAC -> infos} containing only currently connected clients
        local connected_clients_table = iwinfo[iwinfo.type(INTERFACE)].assoclist(INTERFACE)
        -- Table {MAC -> IP} 
        local mac_ip_table = utils.arp_parse(ARP_FILEPATH)

        for mac, infos in pairs(connected_clients_table) do
            if type(mac_ip_table[mac]) == 'string' then
                connected_clients_table[mac] = mac_ip_table[mac]
            else
                print('warning : couldnt find an IP mapping for MAC address ' .. mac)
            end
        end
        return connected_clients_table
    end)
    posix.sleep(1)
end