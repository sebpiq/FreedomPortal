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

-- Safely writes the string contents to the clients file
local function _write_clients_file(contents)
    local fd = _acquire_file_lock(posix.O_WRONLY, posix.F_WRLCK)
    posix.write(fd, contents)
    _release_file_lock(fd)
end

-- Safely reads the client file and returns its contents as a string
local function _read_clients_file()
    local fd = _acquire_file_lock(posix.O_RDONLY, posix.F_RDLCK)
    local contents = ''
    local string_read = nil
    repeat
        string_read = posix.read(fd, 256)
        contents = contents .. string_read
    until string_read:len() < 256
    _release_file_lock(fd)
    return contents
end

-- Saves the clients table to the clients file
local function save(clients_table)
    local clients_serialized = ''
    for mac, infos_table in pairs(clients_table) do
        clients_serialized = clients_serialized .. 'mac ' .. mac .. ' '
        for key, value in pairs(infos_table) do
            clients_serialized = clients_serialized .. key .. ' ' .. value .. ' '
        end
        clients_serialized = clients_serialized .. '\n'
    end
    _write_clients_file(clients_serialized)
end

-- Gets the client table from the clients file
local function get()
    local clients_serialized = _read_clients_file(CLIENTS_FILE_PATH)
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

return {
    _write_clients_file = _write_clients_file,
    _read_clients_file = _read_clients_file,
    save = save,
    get = get,
    CLIENTS_FILE_PATH = CLIENTS_FILE_PATH,
}