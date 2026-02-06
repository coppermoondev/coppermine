-- HoneyMoon Session Module
-- Session management and stores

local utils = require("honeymoon.lib.utils")

local session = {}

--------------------------------------------------------------------------------
-- Memory Store
--------------------------------------------------------------------------------

---@class MemoryStore
---@field _sessions table Session data
---@field _expiry table Session expiry times
local MemoryStore = {}
MemoryStore.__index = MemoryStore

--- Create a new in-memory session store
---@return MemoryStore
function session.MemoryStore()
    local self = setmetatable({}, MemoryStore)
    self._sessions = {}
    self._expiry = {}
    self._cleanup_interval = 60  -- seconds
    self._last_cleanup = os.time()
    return self
end

--- Get session data
---@param id string Session ID
---@return table|nil
function MemoryStore:get(id)
    -- Periodic cleanup
    self:_cleanup()

    -- Check expiry
    if self._expiry[id] and self._expiry[id] < os.time() then
        self:destroy(id)
        return nil
    end

    return self._sessions[id]
end

--- Set session data
---@param id string Session ID
---@param data table Session data
---@param ttl number|nil Time to live in seconds
function MemoryStore:set(id, data, ttl)
    self._sessions[id] = data
    if ttl then
        self._expiry[id] = os.time() + ttl
    end
end

--- Destroy a session
---@param id string Session ID
function MemoryStore:destroy(id)
    self._sessions[id] = nil
    self._expiry[id] = nil
end

--- Touch session (refresh expiry)
---@param id string Session ID
---@param ttl number Time to live in seconds
function MemoryStore:touch(id, ttl)
    if self._sessions[id] and ttl then
        self._expiry[id] = os.time() + ttl
    end
end

--- Check if session exists
---@param id string Session ID
---@return boolean
function MemoryStore:exists(id)
    return self._sessions[id] ~= nil and
           (not self._expiry[id] or self._expiry[id] >= os.time())
end

--- Get all session IDs
---@return table
function MemoryStore:all()
    self:_cleanup()
    return utils.keys(self._sessions)
end

--- Get session count
---@return number
function MemoryStore:length()
    return #self:all()
end

--- Clear all sessions
function MemoryStore:clear()
    self._sessions = {}
    self._expiry = {}
end

--- Clean up expired sessions
function MemoryStore:_cleanup()
    local now = os.time()
    if now - self._last_cleanup < self._cleanup_interval then
        return
    end

    self._last_cleanup = now
    local to_remove = {}

    for id, expiry in pairs(self._expiry) do
        if expiry < now then
            table.insert(to_remove, id)
        end
    end

    for _, id in ipairs(to_remove) do
        self:destroy(id)
    end
end

--------------------------------------------------------------------------------
-- Session Object (attached to request)
--------------------------------------------------------------------------------

---@class Session
---@field _id string Session ID
---@field _store MemoryStore Session store
---@field _data table Session data
---@field _ttl number Time to live
---@field _response Response Response object for cookie management
local Session = {}
Session.__index = Session

--- Create session wrapper
function session.Session(id, store, ttl, res, cookie_name, cookie_options)
    local self = setmetatable({}, Session)
    self._id = id
    self._store = store
    self._data = store:get(id) or {}
    self._ttl = ttl
    self._response = res
    self._cookie_name = cookie_name
    self._cookie_options = cookie_options
    self._modified = false
    self._regenerated = false
    return self
end

--- Get session value
function Session:__index(key)
    -- Check for methods first
    if Session[key] then
        return Session[key]
    end
    -- Check internal fields
    if key:sub(1, 1) == "_" then
        return rawget(self, key)
    end
    -- Return session data
    return self._data[key]
end

--- Set session value
function Session:__newindex(key, value)
    if key:sub(1, 1) == "_" then
        rawset(self, key, value)
    else
        self._data[key] = value
        self._modified = true
    end
end

--- Get all session data
---@return table
function Session:all()
    return utils.deep_copy(self._data)
end

--- Check if key exists
---@param key string
---@return boolean
function Session:has(key)
    return self._data[key] ~= nil
end

--- Get value with default
---@param key string
---@param default any
---@return any
function Session:get(key, default)
    local value = self._data[key]
    if value == nil then
        return default
    end
    return value
end

--- Set value
---@param key string
---@param value any
function Session:set(key, value)
    self._data[key] = value
    self._modified = true
end

--- Remove value
---@param key string
function Session:forget(key)
    self._data[key] = nil
    self._modified = true
end

--- Flash data (available only for next request)
---@param key string
---@param value any
function Session:flash(key, value)
    self._data._flash = self._data._flash or {}
    self._data._flash[key] = value
    self._modified = true
end

--- Get flash data
---@param key string
---@return any
function Session:getFlash(key)
    if self._data._flash then
        return self._data._flash[key]
    end
    return nil
end

--- Clear flash data (called after reading)
function Session:clearFlash()
    self._data._flash = nil
    self._modified = true
end

--- Save session
function Session:save()
    self._store:set(self._id, self._data, self._ttl)
end

--- Destroy session
function Session:destroy()
    self._store:destroy(self._id)
    self._response:clearCookie(self._cookie_name, self._cookie_options)
    self._data = {}
end

--- Regenerate session ID
---@param keepData boolean|nil Keep existing data
function Session:regenerate(keepData)
    local old_data = keepData and utils.deep_copy(self._data) or {}

    -- Destroy old session
    self._store:destroy(self._id)

    -- Generate new ID
    local new_id = session.generate_id()
    self._id = new_id
    self._data = old_data
    self._regenerated = true

    -- Set new cookie
    self._response:cookie(self._cookie_name, new_id, self._cookie_options)

    -- Save with new ID
    self:save()

    return new_id
end

--- Get session ID
---@return string
function Session:getId()
    return self._id
end

--------------------------------------------------------------------------------
-- Session ID Generation
--------------------------------------------------------------------------------

--- Generate a secure session ID
---@return string
function session.generate_id()
    -- Try to use crypto module if available
    if crypto and crypto.uuid then
        return crypto.uuid()
    end
    -- Fallback to random string
    return utils.random_string(32)
end

--------------------------------------------------------------------------------
-- Global Default Store
--------------------------------------------------------------------------------

session._defaultStore = nil

--- Get or create default session store
---@return MemoryStore
function session.getDefaultStore()
    if not session._defaultStore then
        session._defaultStore = session.MemoryStore()
    end
    return session._defaultStore
end

return session
