-- HoneyMoon Rate Limit Middleware
-- Request rate limiting with sliding window

local utils = require("honeymoon.lib.utils")
local errors = require("honeymoon.lib.errors")

local ratelimit = {}

--------------------------------------------------------------------------------
-- Rate Limit Store
--------------------------------------------------------------------------------

---@class RateLimitStore
---@field _requests table Request timestamps by key
local RateLimitStore = {}
RateLimitStore.__index = RateLimitStore

--- Create a new rate limit store
---@return RateLimitStore
function ratelimit.Store()
    local self = setmetatable({}, RateLimitStore)
    self._requests = {}
    self._cleanup_counter = 0
    return self
end

--- Record a request hit
---@param key string Request key
---@param window_ms number Window size in milliseconds
---@return number Current request count
function RateLimitStore:hit(key, window_ms)
    local now = time.now_ms()
    local window_start = now - window_ms

    -- Initialize if needed
    if not self._requests[key] then
        self._requests[key] = {}
    end

    -- Clean old entries
    local new_list = {}
    for _, timestamp in ipairs(self._requests[key]) do
        if timestamp > window_start then
            table.insert(new_list, timestamp)
        end
    end
    self._requests[key] = new_list

    -- Add current request
    table.insert(self._requests[key], now)

    -- Periodic cleanup
    self._cleanup_counter = self._cleanup_counter + 1
    if self._cleanup_counter >= 1000 then
        self:_cleanup(window_ms)
        self._cleanup_counter = 0
    end

    return #self._requests[key]
end

--- Get current count for a key
---@param key string Request key
---@param window_ms number Window size in milliseconds
---@return number
function RateLimitStore:count(key, window_ms)
    if not self._requests[key] then
        return 0
    end

    local now = time.now_ms()
    local window_start = now - window_ms
    local count = 0

    for _, timestamp in ipairs(self._requests[key]) do
        if timestamp > window_start then
            count = count + 1
        end
    end

    return count
end

--- Reset rate limit for a key
---@param key string Request key
function RateLimitStore:reset(key)
    self._requests[key] = nil
end

--- Clean up old entries
---@param window_ms number Window size for cleanup
function RateLimitStore:_cleanup(window_ms)
    local now = time.now_ms()
    local window_start = now - window_ms

    for key, timestamps in pairs(self._requests) do
        local new_list = {}
        for _, timestamp in ipairs(timestamps) do
            if timestamp > window_start then
                table.insert(new_list, timestamp)
            end
        end
        if #new_list == 0 then
            self._requests[key] = nil
        else
            self._requests[key] = new_list
        end
    end
end

--------------------------------------------------------------------------------
-- Global Store
--------------------------------------------------------------------------------

local _globalStore = nil

--- Get global rate limit store
---@return RateLimitStore
function ratelimit.getStore()
    if not _globalStore then
        _globalStore = ratelimit.Store()
    end
    return _globalStore
end

--------------------------------------------------------------------------------
-- Rate Limit Middleware
--------------------------------------------------------------------------------

--- Default options
local defaults = {
    windowMs = 60000,       -- 1 minute
    max = 100,              -- 100 requests per window
    message = "Too many requests, please try again later",
    statusCode = 429,
    headers = true,         -- Send rate limit headers
    skipSuccessfulRequests = false,
    skipFailedRequests = false,
    legacyHeaders = false,  -- Include X-RateLimit-* headers
    standardHeaders = true, -- Include RateLimit-* headers (draft spec)
}

--- Create rate limit middleware
---@param options table|nil Rate limit options
---@return function Middleware function
function ratelimit.create(options)
    options = options or {}

    -- Merge with defaults
    local config = {}
    for k, v in pairs(defaults) do
        config[k] = options[k] ~= nil and options[k] or v
    end

    -- Use provided store or global
    local store = options.store or ratelimit.getStore()

    -- Key generator function
    local key_generator = options.keyGenerator or function(req)
        return req.ip
    end

    -- Skip function
    local skip = options.skip or function(req)
        return false
    end

    -- Handler for rate limit exceeded
    local handler = options.handler or function(req, res, next, opt)
        if req:accepts("html") then
            return res:errorPage(opt.statusCode, opt.message)
        else
            return res:status(opt.statusCode):json({
                error = "Too Many Requests",
                message = opt.message,
                retryAfter = math.ceil(opt.windowMs / 1000)
            })
        end
    end

    return function(req, res, next)
        -- Check if should skip
        if skip(req) then
            return next()
        end

        -- Get request key
        local key = key_generator(req)
        local count = store:hit(key, config.windowMs)
        local remaining = math.max(0, config.max - count)
        local reset_time = math.floor((time.now_ms() + config.windowMs) / 1000)

        -- Set headers
        if config.headers then
            if config.legacyHeaders then
                res:set("X-RateLimit-Limit", tostring(config.max))
                res:set("X-RateLimit-Remaining", tostring(remaining))
                res:set("X-RateLimit-Reset", tostring(reset_time))
            end

            if config.standardHeaders then
                -- Draft-7 standard headers
                res:set("RateLimit-Limit", tostring(config.max))
                res:set("RateLimit-Remaining", tostring(remaining))
                res:set("RateLimit-Reset", tostring(math.ceil(config.windowMs / 1000)))
            end
        end

        -- Check if rate limited
        if count > config.max then
            res:set("Retry-After", tostring(math.ceil(config.windowMs / 1000)))
            return handler(req, res, next, config)
        end

        -- Wrap response to track success/failure for skip options
        if config.skipSuccessfulRequests or config.skipFailedRequests then
            local original_send = res.send
            res.send = function(self, body)
                local status = self._status
                local should_skip = (config.skipSuccessfulRequests and status < 400)
                    or (config.skipFailedRequests and status >= 400)

                if should_skip then
                    -- Undo the hit
                    store:reset(key)
                end

                return original_send(self, body)
            end
        end

        next()
    end
end

--- Create sliding window rate limiter
---@param max number Maximum requests
---@param window_seconds number Window in seconds
---@return function
function ratelimit.sliding(max, window_seconds)
    return ratelimit.create({
        windowMs = window_seconds * 1000,
        max = max
    })
end

--- Create rate limiter with custom key
---@param options table Options including key function
---@return function
function ratelimit.byKey(key_fn, options)
    options = options or {}
    options.keyGenerator = key_fn
    return ratelimit.create(options)
end

--- Rate limit by user ID
---@param options table|nil Additional options
---@return function
function ratelimit.byUser(options)
    options = options or {}
    options.keyGenerator = function(req)
        if req.user and req.user.id then
            return "user:" .. tostring(req.user.id)
        end
        return "ip:" .. req.ip
    end
    return ratelimit.create(options)
end

--- Rate limit by API key
---@param header_name string|nil Header containing API key
---@param options table|nil Additional options
---@return function
function ratelimit.byApiKey(header_name, options)
    header_name = header_name or "x-api-key"
    options = options or {}
    options.keyGenerator = function(req)
        local api_key = req:get(header_name)
        if api_key then
            return "apikey:" .. api_key
        end
        return "ip:" .. req.ip
    end
    return ratelimit.create(options)
end

return ratelimit
