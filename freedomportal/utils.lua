
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

-- Bitwise or. Needed because Lua 5.1 has not bitwise operations
-- http://stackoverflow.com/questions/5977654/lua-bitwise-logical-operations
local function bitwise_or(a,b)
    local p,c=1,0
    while a+b>0 do
        local ra,rb=a%2,b%2
        if ra+rb>0 then c=c+p end
        a,b,p=(a-ra)/2,(b-rb)/2,p*2
    end
    return c
end

-- Helper to find a client by its ip
local function search_collection(table, key, value)
    local found = nil
    for ind, elem in pairs(table) do
        if elem[key] == value then
            found = elem
            break
        end
    end
    return found
end

local function extend_table(base_table, other_table)
    for k, v in pairs(other_table) do base_table[k] = v end
    return base_table
end

local function have_same_keys(table1, table2)
    for k, v in pairs(table1) do 
        if not table2[k] then return false end
    end
    for k, v in pairs(table2) do 
        if not table1[k] then return false end
    end
    return true
end

return {
    find_IPv4 = find_IPv4,
    find_MAC = find_MAC,
    bitwise_or = bitwise_or,
    search_collection = search_collection,
    extend_table = extend_table,
    have_same_keys = have_same_keys,
}