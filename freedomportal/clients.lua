local posix = require('posix')
local utils = require('freedomportal.utils')

local CLIENTS_FILE_PATH = 'file.txt'

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

local function _read_file_posix(fd)
    local contents = ''
    local string_read = nil
    repeat
        string_read = posix.read(fd, 256)
        contents = contents .. string_read
    until string_read:len() < 256
    return contents
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

-- Gets the client table from the clients file
local function get()
    local fd = _acquire_file_lock(posix.O_RDONLY, posix.F_RDLCK)
    local clients_serialized = _read_file_posix(fd)
    _release_file_lock(fd)
    return _deserialize(clients_serialized)
end

-- Refreshes the file of connected clients in an atomic way. 
-- get_connected_clients is a function that must return a table of 
-- currently connected clients: { mac = ip } 
local function refresh(get_connected_clients)
    
    local flags = utils.bitwise_or(utils.bitwise_or(posix.O_RDWR, posix.O_SYNC), posix.O_TRUNC)
    local fd = _acquire_file_lock(flags, posix.F_WRLCK)
    local clients_table = _deserialize(_read_file_posix(fd))
    local connected_clients_table = get_connected_clients()

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

    posix.write(fd, _serialize(clients_table))
    posix.close(fd)
    _release_file_lock(fd)
end

return {
    _read_file_posix = _read_file_posix,
    _deserialize = _deserialize,
    _serialize = _serialize,
    refresh = refresh,
    get = get,
    CLIENTS_FILE_PATH = CLIENTS_FILE_PATH,
}