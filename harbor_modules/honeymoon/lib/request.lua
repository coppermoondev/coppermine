-- HoneyMoon Request Module
-- HTTP request wrapper with helpers

local utils = require("honeymoon.lib.utils")
local errors = require("honeymoon.lib.errors")

local request = {}

--------------------------------------------------------------------------------
-- Request Class
--------------------------------------------------------------------------------

---@class Request
---@field method string HTTP method
---@field path string Request path
---@field headers table Request headers
---@field query table Query parameters
---@field params table Route parameters
---@field body string Raw request body
---@field app table Application instance
---@field ip string Client IP address
---@field protocol string HTTP protocol (http/https)
---@field hostname string Host header value
---@field secure boolean Whether request is HTTPS
---@field xhr boolean Whether request is XMLHttpRequest
---@field session table|nil Session data
---@field sessionID string|nil Session ID
---@field user table|nil Authenticated user
---@field id string|nil Request ID
local Request = {}
Request.__index = Request

--- Create a new request object from context
---@param ctx table Raw request context
---@param app table Application instance
---@return Request
function request.new(ctx, app)
    local self = setmetatable({}, Request)

    -- Basic properties
    self.method = ctx.method or "GET"
    self.path = ctx.path or "/"
    self.headers = ctx.headers or {}
    self.query = ctx.query or {}
    self.params = {}
    self.body = ctx.body or ""
    self.app = app

    -- Derived properties
    self.ip = self:_get_client_ip()
    self.protocol = self.headers["x-forwarded-proto"] or "http"
    self.hostname = self.headers["host"] or "localhost"
    self.secure = self.protocol == "https"
    self.xhr = (self.headers["x-requested-with"] or ""):lower() == "xmlhttprequest"

    -- Will be set by middleware
    self.session = nil
    self.sessionID = nil
    self.user = nil
    self.id = nil

    -- Internal caches
    self._parsed_body = nil
    self._parsed_cookies = nil

    return self
end

--------------------------------------------------------------------------------
-- IP Address
--------------------------------------------------------------------------------

--- Get client IP address (respecting proxy headers)
---@return string
function Request:_get_client_ip()
    -- Check X-Forwarded-For first (may contain multiple IPs)
    local forwarded = self.headers["x-forwarded-for"]
    if forwarded then
        -- Take the first IP in the chain
        local first_ip = forwarded:match("^([^,]+)")
        if first_ip then
            return utils.trim(first_ip)
        end
    end

    -- Check X-Real-IP
    local real_ip = self.headers["x-real-ip"]
    if real_ip then
        return real_ip
    end

    -- Fallback
    return "127.0.0.1"
end

--------------------------------------------------------------------------------
-- Header Access
--------------------------------------------------------------------------------

--- Get a header value (case-insensitive)
---@param name string Header name
---@return string|nil
function Request:get(name)
    return self.headers[name:lower()]
end

--- Check if request has a specific header
---@param name string Header name
---@return boolean
function Request:has(name)
    return self.headers[name:lower()] ~= nil
end

--------------------------------------------------------------------------------
-- Body Parsing
--------------------------------------------------------------------------------

--- Parse body as JSON
---@return table
function Request:json()
    if self._parsed_body ~= nil then
        return self._parsed_body
    end

    local content_type = self:get("content-type") or ""
    if content_type:find("application/json") then
        local ok, data = pcall(json.decode, self.body)
        self._parsed_body = ok and data or {}
    else
        self._parsed_body = {}
    end

    return self._parsed_body
end

--- Parse body as form data
---@return table
function Request:form()
    if self._parsed_body ~= nil then
        return self._parsed_body
    end

    local content_type = self:get("content-type") or ""
    if content_type:find("application/x-www-form-urlencoded") then
        self._parsed_body = {}
        for pair in self.body:gmatch("[^&]+") do
            local key, value = pair:match("([^=]+)=?(.*)")
            if key then
                self._parsed_body[utils.url_decode(key)] = utils.url_decode(value or "")
            end
        end
    else
        self._parsed_body = {}
    end

    return self._parsed_body
end

--------------------------------------------------------------------------------
-- Parameter Access
--------------------------------------------------------------------------------

--- Get a parameter from params, query, or body
---@param name string Parameter name
---@param default any Default value if not found
---@return any
function Request:param(name, default)
    -- Check route params first
    if self.params[name] ~= nil then
        return self.params[name]
    end

    -- Then query params
    if self.query[name] ~= nil then
        return self.query[name]
    end

    -- Then body (if parsed)
    if self._parsed_body and self._parsed_body[name] ~= nil then
        return self._parsed_body[name]
    end

    return default
end

--------------------------------------------------------------------------------
-- Content Negotiation
--------------------------------------------------------------------------------

--- Check if request accepts specific content type(s)
---@param types string|table Content type(s) to check
---@return string|nil The accepted type, or nil
function Request:accepts(types)
    local accept = self.headers["accept"] or "*/*"

    if type(types) == "string" then
        types = {types}
    end

    for _, t in ipairs(types) do
        -- Handle short forms
        local full_type = t
        if t == "json" then full_type = "application/json"
        elseif t == "html" then full_type = "text/html"
        elseif t == "text" then full_type = "text/plain"
        elseif t == "xml" then full_type = "application/xml"
        end

        if accept:find(full_type, 1, true) or accept == "*/*" then
            return t
        end
    end

    return nil
end

--- Check if request Content-Type matches
---@param types string|table Content type(s) to check
---@return string|nil The matching type, or nil
function Request:is(types)
    local content_type = self:get("content-type") or ""

    if type(types) == "string" then
        types = {types}
    end

    for _, t in ipairs(types) do
        local full_type = t
        if t == "json" then full_type = "application/json"
        elseif t == "html" then full_type = "text/html"
        elseif t == "form" then full_type = "application/x-www-form-urlencoded"
        elseif t == "multipart" then full_type = "multipart/form-data"
        end

        if content_type:find(full_type, 1, true) then
            return t
        end
    end

    return nil
end

--------------------------------------------------------------------------------
-- Cookies
--------------------------------------------------------------------------------

--- Get all cookies
---@return table
function Request:cookies()
    if self._parsed_cookies ~= nil then
        return self._parsed_cookies
    end

    self._parsed_cookies = {}
    local cookie_header = self.headers["cookie"] or ""

    for pair in cookie_header:gmatch("[^;]+") do
        local key, value = pair:match("^%s*([^=]+)%s*=%s*(.*)%s*$")
        if key then
            -- Remove surrounding quotes if present
            value = value:gsub('^"(.-)"$', '%1')
            self._parsed_cookies[utils.trim(key)] = utils.url_decode(value)
        end
    end

    return self._parsed_cookies
end

--- Get a single cookie value
---@param name string Cookie name
---@return string|nil
function Request:cookie(name)
    return self:cookies()[name]
end

--------------------------------------------------------------------------------
-- Validation
--------------------------------------------------------------------------------

--- Validate request body against schema
---@param schema Schema
---@return table Sanitized data
function Request:validate(schema)
    local data = self:json()
    local valid, sanitized, errs = schema:validate(data)

    if not valid then
        error(errors.ValidationError.new(errs))
    end

    return sanitized
end

--- Validate query parameters against schema
---@param schema Schema
---@return table Sanitized data
function Request:validateQuery(schema)
    local valid, sanitized, errs = schema:validate(self.query)

    if not valid then
        error(errors.ValidationError.new(errs))
    end

    return sanitized
end

--- Validate route parameters against schema
---@param schema Schema
---@return table Sanitized data
function Request:validateParams(schema)
    local valid, sanitized, errs = schema:validate(self.params)

    if not valid then
        error(errors.ValidationError.new(errs))
    end

    return sanitized
end

--------------------------------------------------------------------------------
-- Utility Methods
--------------------------------------------------------------------------------

--- Check if request is fresh (for caching)
---@return boolean
function Request:fresh()
    -- Simplified freshness check
    local if_none_match = self:get("if-none-match")
    local if_modified = self:get("if-modified-since")
    return if_none_match ~= nil or if_modified ~= nil
end

--- Check if request is stale
---@return boolean
function Request:stale()
    return not self:fresh()
end

--- Get the original URL
---@return string
function Request:originalUrl()
    local url = self.path
    if self.query and next(self.query) then
        local parts = {}
        for k, v in pairs(self.query) do
            table.insert(parts, utils.url_encode(k) .. "=" .. utils.url_encode(tostring(v)))
        end
        url = url .. "?" .. table.concat(parts, "&")
    end
    return url
end

--- Get request range header
---@param size number Total size
---@return table|nil
function Request:range(size)
    local range_header = self:get("range")
    if not range_header then
        return nil
    end

    local unit, ranges = range_header:match("^(%w+)=(.+)$")
    if unit ~= "bytes" then
        return nil
    end

    local result = {}
    for range in ranges:gmatch("[^,]+") do
        local start_str, end_str = range:match("^(%d*)%-(%d*)$")
        local start_pos = tonumber(start_str)
        local end_pos = tonumber(end_str)

        if start_pos then
            end_pos = end_pos or (size - 1)
        elseif end_str then
            -- Suffix range: -500 means last 500 bytes
            start_pos = size - tonumber(end_str)
            end_pos = size - 1
        else
            return nil
        end

        if start_pos >= 0 and end_pos < size and start_pos <= end_pos then
            table.insert(result, { start = start_pos, ["end"] = end_pos })
        end
    end

    return #result > 0 and result or nil
end

return request
