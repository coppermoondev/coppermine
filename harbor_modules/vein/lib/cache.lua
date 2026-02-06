-- Vein Template Cache
-- Simple LRU cache for compiled templates
--
-- @module vein.lib.cache

local cache = {}

--------------------------------------------------------------------------------
-- Cache Class
--------------------------------------------------------------------------------

local Cache = {}
Cache.__index = Cache

--- Create a new cache
---@param limit number? Maximum entries (default 100)
---@return Cache
function cache.new(limit)
    local self = setmetatable({}, Cache)

    self.limit = limit or 100
    self.entries = {}
    self.order = {}  -- For LRU tracking
    self.count = 0

    return self
end

--- Get a cached value
---@param key string Cache key
---@return any? Value or nil
function Cache:get(key)
    local entry = self.entries[key]

    if entry then
        -- Move to end of order (most recently used)
        self:_touch(key)
        return entry.value
    end

    return nil
end

--- Set a cached value
---@param key string Cache key
---@param value any Value to cache
function Cache:set(key, value)
    -- Check if key already exists
    if self.entries[key] then
        self.entries[key].value = value
        self:_touch(key)
        return
    end

    -- Evict if at limit
    while self.count >= self.limit do
        self:_evict()
    end

    -- Add new entry
    self.entries[key] = { value = value }
    table.insert(self.order, key)
    self.count = self.count + 1
end

--- Check if key exists
---@param key string Cache key
---@return boolean
function Cache:has(key)
    return self.entries[key] ~= nil
end

--- Remove a key
---@param key string Cache key
function Cache:remove(key)
    if self.entries[key] then
        self.entries[key] = nil
        self.count = self.count - 1

        -- Remove from order
        for i, k in ipairs(self.order) do
            if k == key then
                table.remove(self.order, i)
                break
            end
        end
    end
end

--- Clear all entries
function Cache:clear()
    self.entries = {}
    self.order = {}
    self.count = 0
end

--- Get cache stats
---@return table Stats
function Cache:stats()
    return {
        count = self.count,
        limit = self.limit,
        keys = self:keys()
    }
end

--- Get all keys
---@return table Array of keys
function Cache:keys()
    local keys = {}
    for key in pairs(self.entries) do
        table.insert(keys, key)
    end
    return keys
end

--- Move key to end of order (touch for LRU)
---@param key string Cache key
function Cache:_touch(key)
    -- Remove from current position
    for i, k in ipairs(self.order) do
        if k == key then
            table.remove(self.order, i)
            break
        end
    end
    -- Add to end
    table.insert(self.order, key)
end

--- Evict least recently used entry
function Cache:_evict()
    if self.count == 0 then
        return
    end

    -- Get oldest key
    local key = table.remove(self.order, 1)

    if key and self.entries[key] then
        self.entries[key] = nil
        self.count = self.count - 1
    end
end

return cache
