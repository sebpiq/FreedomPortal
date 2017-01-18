local posix = require('posix')
local utils = require('freedomportal.utils')
local config = require('freedomportal.config')

-- Acquire the lock to safely read / write in the clients file
local function _acquire_file_lock(open_mode, lock_mode)
    local fd = posix.open(config.get('clients_file_path'), open_mode)

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

-- Helper function to read all contents of a file.
local function _posix_read_all(fd)
    local contents = ''
    local string_read = nil
    repeat
        string_read = posix.read(fd, 256)
        contents = contents .. string_read
    until string_read:len() < 256
    return contents
end

-- Serializes `clients_table` to a string that can be stored in a file.
-- Format is as follow :
--     mac <MAC1> <key1> <val1> <key2> <val2> ...
--     mac <MAC2> <key1> <val1> <key2> <val2> ...
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

-- Deserializes `clients_serialized` to a table.
local function _deserialize(clients_serialized)
    local clients_table = {}

    for line in string.gmatch(clients_serialized, '([^\n]*)\n') do
        local infos_table = {}
        for key, value in string.gmatch(line, '(%S+)%s(%S+)%s') do
            infos_table[key] = value
        end
        if not infos_table.mac or not infos_table.ip then 
            error('invalid client infos : ' .. line) 
        end
        clients_table[infos_table.mac] = infos_table
        infos_table.mac = nil
    end
    return clients_table
end

-- Returns all the stored clients.
local function get_all()
    local fd = _acquire_file_lock(posix.O_RDONLY, posix.F_RDLCK)
    local contents = _posix_read_all(fd)
    _release_file_lock(fd)
    return _deserialize(contents)
end

-- Replaces all the stored clients. `get_clients` receives the table of 
-- previously stored clients, and returns the new clients table.
local function replace_all(get_clients)
    local flags = utils.bitwise_or(posix.O_RDWR, posix.O_SYNC)
    local fd = _acquire_file_lock(flags, posix.F_WRLCK)
    posix.lseek(fd, 0, posix.SEEK_SET)
    local contents_old = _posix_read_all(fd)
    local contents_new = get_clients(_deserialize(contents_old))

    if contents_new ~= nil then
        contents_new = _serialize(contents_new)
        -- with posix on OpenWrt, it doesn't seem like we can truncate a file, 
        -- so we can free space from a file that became smaller.
        -- Instead, we just replace the extra space by whitespace characters...
        while string.len(contents_new) < string.len(contents_old) do
            contents_new = contents_new .. ' ' 
        end
        posix.lseek(fd, 0, posix.SEEK_SET)
        posix.write(fd, contents_new)
    end

    posix.close(fd)
    _release_file_lock(fd)
end

return {
    _posix_read_all = _posix_read_all,
    _deserialize = _deserialize,
    _serialize = _serialize,
    get_all = get_all,
    replace_all = replace_all,
}