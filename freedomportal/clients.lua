-- TODO : decouple clients data storage (_serielize, _deserialize, _posix_read_all, _replace_file, ...)
-- from high level clients operations (refresh, get, set_fields)
local posix = require('posix')
local utils = require('freedomportal.utils')

local CLIENTS_FILE_PATH = '/tmp/freedomportal_clients.txt'

-- Acquire the lock to safely read / write in the clients file
local function _acquire_file_lock(open_mode, lock_mode)
    local fd = posix.open(CLIENTS_FILE_PATH, open_mode) -- | posix.O_SYNC

    -- Set lock on file
    local lock = {
        l_type = lock_mode;
        l_whence = posix.SEEK_SET;  -- Relative to beginning of file
        l_start = 0;                -- Start from 1st byte
        l_len = 0;                  -- Lock whole file
    }

    -- Try unlocking the file, and wait if it is locked
    local unlocked = posix.fcntl(fd, posix.F_SETLKW, lock)
    if unlocked == -1 then
        error('file couldn\'t be unlocked for some reason')
    end

    return fd
end

-- Release the lock to safely read / write in the clients file
local function _release_file_lock(fd)
    local lock = {
        l_type = posix.F_UNLCK;     -- Exclusive lock
        l_whence = posix.SEEK_SET;  -- Relative to beginning of file
        l_start = 0;            -- Start from 1st byte
        l_len = 0;              -- Lock whole file
    }
    posix.fcntl(fd, posix.F_SETLK, lock)
end

local function _posix_read_all(fd)
    local contents = ''
    local string_read = nil
    repeat
        string_read = posix.read(fd, 256)
        contents = contents .. string_read
    until string_read:len() < 256
    return contents
end

local function _read_file()
    local fd = _acquire_file_lock(posix.O_RDONLY, posix.F_RDLCK)
    local contents = _posix_read_all(fd)
    _release_file_lock(fd)
    return contents
end

local function _replace_file(get_new_contents)
    local flags = utils.bitwise_or(posix.O_RDWR, posix.O_SYNC)
    local fd = _acquire_file_lock(flags, posix.F_WRLCK)
    posix.lseek(fd, 0, posix.SEEK_SET)
    local contents_old = _posix_read_all(fd)
    local contents_new = get_new_contents(contents_old)

    -- with posix on OpenWrt, it doesn't seem like we can truncate a file, 
    -- so we can free space from a file that became smaller.
    -- Instead, we just replace the extra space by whitespace characters...
    while string.len(contents_new) < string.len(contents_old) do
        contents_new = contents_new .. ' ' 
    end
    posix.lseek(fd, 0, posix.SEEK_SET)
    posix.write(fd, contents_new)
    posix.close(fd)
    _release_file_lock(fd)
end

local function _serialize(clients_table)
    local clients_serialized = ''
    for mac, infos_table in pairs(clients_table) do
        clients_serialized = clients_serialized .. 'mac ' .. mac .. ' '
        for key, value in pairs(infos_table) do
            clients_serialized = clients_serialized .. key .. ' ' .. value .. ' '
        end
        clients_serialized = clients_serialized .. '\n'
    end
    return clients_serialized
end

local function _deserialize(clients_serialized)
    local clients_table = {}

    for line in string.gmatch(clients_serialized, '([^\n]*)\n') do
        local infos_table = {}
        for key, value in string.gmatch(line, '(%S+)%s(%S+)%s') do
            infos_table[key] = value
        end
        if not infos_table.mac or not infos_table.ip then error('invalid client infos : ' .. line) end
        clients_table[infos_table.mac] = infos_table
        infos_table.mac = nil
    end
    return clients_table
end

-- Returns the client table of all currently connected clients
local function get_all()
    return _deserialize(_read_file())
end

-- Returns the infos for client `ip`
local function get(ip)
    return utils.search_collection(get_all(), 'ip', ip) 
end

-- Refreshes the file of connected clients in an atomic way. 
-- `get_connected_clients` is a function that must return a table of 
-- currently connected clients: `{ mac = ip }`
local function refresh(get_connected_clients)
    local clients_table
    _replace_file(function(clients_serialized)
        local connected_clients_table = get_connected_clients()
        clients_table = _deserialize(clients_serialized)

        -- We add all connected clients to clients_table if they are not there yet 
        for mac, ip in pairs(connected_clients_table) do
            if not clients_table[mac] then
                clients_table[mac] = { ip = ip, }
            end
        end

        -- We remove all clients from clients_table that are not connected
        for mac, infos in pairs(clients_table) do
            if not connected_clients_table[mac] then
                clients_table[mac] = nil
            end
        end        

        return _serialize(clients_table)
    end)
    return clients_table
end

-- Sets infos of client `ip` in an atomic way.
-- All keys and values of `fields_table` must be strings.
local function set_fields(ip, fields_table)
    for key, value in pairs(fields_table) do
        if type(key) ~= 'string' then error('keys must be strings, invalid : ' .. key) end
        if type(value) ~= 'string' then error('values must be strings, invalid : ' .. value) end
    end

    local client_infos
    _replace_file(function(clients_serialized)
        local clients_table = _deserialize(clients_serialized)

        -- Search client by IP
        client_infos = utils.search_collection(clients_table, 'ip', ip)

        -- If client found we set key, value and save the file
        -- even if client is not found we must re-write the whole table, 
        -- because of flags used to open it.
        if client_infos then
            for key, value in pairs(fields_table) do
                client_infos[key] = value
            end
        else
            print('WARN : client with ip ' .. ip .. ' could not be found')
        end
        return _serialize(clients_table)
    end)

    return client_infos
end

return {
    _posix_read_all = _posix_read_all,
    _read_file = _read_file,
    _replace_file = _replace_file,
    _deserialize = _deserialize,
    _serialize = _serialize,
    refresh = refresh,
    get_all = get_all,
    get = get,
    set_fields = set_fields,
    CLIENTS_FILE_PATH = CLIENTS_FILE_PATH,
}