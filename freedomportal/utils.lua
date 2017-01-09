
-- A very naive function for finding the first matching IPv4 address in the 
-- string passed as argument. Returns nil if nothing was found
local function find_IPv4(str)
    if not str then return false end
    local a, b, c, d = str:match('(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)')
    local a_num = tonumber(a)
    local b_num = tonumber(b)
    local c_num = tonumber(c)
    local d_num = tonumber(d)
    if not a_num or not b_num or not c_num or not d_num then return nil end
    if a_num < 0 or 255 < a_num then return nil end
    if b_num < 0 or 255 < b_num then return nil end
    if c_num < 0 or 255 < c_num then return nil end
    if d_num < 0 or 255 < d_num then return nil end
    return a .. '.' .. b .. '.' .. c .. '.' .. d
end

-- A very naive function for finding the first matching MAC address in the 
-- string passed as argument. Returns nil if nothing was found
local function find_MAC(str)
    if not str then return false end

    local a, b, c, d, e, f = str:match('(%w%w):(%w%w):(%w%w):(%w%w):(%w%w):(%w%w)')
    if not a or not b or not c or not d or not e or not f then return nil end
    return a:upper() .. ':' .. b:upper() .. ':' .. c:upper() .. ':' 
        .. d:upper() .. ':' .. e:upper() .. ':' .. f:upper()
end


local function arp_parse(file_path)
    local clients_table = {}
    for line in io.lines(file_path, 'r') do
        local result_ip = find_IPv4(line)
        local result_mac = nil
        if result_ip then
          result_mac = find_MAC(line)
          if result_mac then clients_table[result_mac] = result_ip end
        end
    end
    return clients_table
end

return {
    find_IPv4 = find_IPv4,
    find_MAC = find_MAC,
    arp_parse = arp_parse,
}