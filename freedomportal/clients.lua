local posix = require('posix')
local utils = require('freedomportal.utils')

local CLIENTS_FILE_PATH = 'file.txt'


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


local function _release_file_lock(fd)
    local lock = {
        l_type = posix.F_UNLCK;     -- Exclusive lock
        l_whence = posix.SEEK_SET;  -- Relative to beginning of file
        l_start = 0;            -- Start from 1st byte
        l_len = 0;              -- Lock whole file
    }
    posix.fcntl(fd, posix.F_SETLK, lock)
end

local function _write_clients_file(contents)
    local fd = _acquire_file_lock(posix.O_WRONLY, posix.F_WRLCK)
    posix.write(fd, contents)
    _release_file_lock(fd)
end

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

local function save(clients_table)
    local clients_serialized = ''
    for mac, ip in pairs(clients_table) do
        clients_serialized = clients_serialized .. mac .. ' ' .. ip .. '\n'
    end
    _write_clients_file(clients_serialized)
end

local function get()
    local contents = _read_clients_file(CLIENTS_FILE_PATH)
    local clients_table = {}

    for line in string.gmatch(contents, '([^\n]*)\n') do
        local mac, ip = line:match('^(%S+)%s(%S+)$')
        if not mac or not ip then error('could not parse line : ' .. line) end
        clients_table[mac] = ip
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