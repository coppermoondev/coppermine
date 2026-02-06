-- HoneyMoon Middleware Index
-- Re-exports all built-in middleware

local middleware = {}

-- Import all middleware modules
local logger = require("honeymoon.lib.middleware.logger")
local cors = require("honeymoon.lib.middleware.cors")
local bodyparser = require("honeymoon.lib.middleware.bodyparser")
local static = require("honeymoon.lib.middleware.static")
local ratelimit = require("honeymoon.lib.middleware.ratelimit")
local auth = require("honeymoon.lib.middleware.auth")
local session = require("honeymoon.lib.middleware.session")
local security = require("honeymoon.lib.middleware.security")

--------------------------------------------------------------------------------
-- Logger
--------------------------------------------------------------------------------

--- Request logging middleware
---@param options table|nil Logger options
---@return function
function middleware.logger(options)
    return logger.create(options)
end

--- Logger with predefined format
middleware.loggerFormat = logger.format
middleware.loggerFormats = logger.formats

--------------------------------------------------------------------------------
-- CORS
--------------------------------------------------------------------------------

--- CORS middleware
---@param options table|nil CORS options
---@return function
function middleware.cors(options)
    return cors.create(options)
end

--- Allow all origins
middleware.corsAllowAll = cors.allowAll

--- CORS for specific origins
middleware.corsOrigins = cors.origins

--------------------------------------------------------------------------------
-- Body Parsers
--------------------------------------------------------------------------------

--- JSON body parser
---@param options table|nil Parser options
---@return function
function middleware.json(options)
    return bodyparser.json(options)
end

--- URL-encoded body parser
---@param options table|nil Parser options
---@return function
function middleware.urlencoded(options)
    return bodyparser.urlencoded(options)
end

--- Raw body parser
---@param options table|nil Parser options
---@return function
function middleware.raw(options)
    return bodyparser.raw(options)
end

--- Text body parser
---@param options table|nil Parser options
---@return function
function middleware.text(options)
    return bodyparser.text(options)
end

--- Combined body parser (JSON + URL-encoded)
---@param options table|nil Parser options
---@return function
function middleware.bodyParser(options)
    return bodyparser.create(options)
end

--------------------------------------------------------------------------------
-- Static Files
--------------------------------------------------------------------------------

--- Static file serving
---@param root string Root directory
---@param options table|nil Static options
---@return function
function middleware.static(root, options)
    return static.create(root, options)
end

--- Directory listing
---@param root string Root directory
---@param options table|nil Options
---@return function
function middleware.directory(root, options)
    return static.directory(root, options)
end

--------------------------------------------------------------------------------
-- Rate Limiting
--------------------------------------------------------------------------------

--- Rate limiting middleware
---@param options table|nil Rate limit options
---@return function
function middleware.rateLimit(options)
    return ratelimit.create(options)
end

--- Rate limit by user
middleware.rateLimitByUser = ratelimit.byUser

--- Rate limit by API key
middleware.rateLimitByApiKey = ratelimit.byApiKey

--- Sliding window rate limiter
middleware.rateLimitSliding = ratelimit.sliding

--------------------------------------------------------------------------------
-- Authentication
--------------------------------------------------------------------------------

--- Basic authentication
---@param options table Auth options
---@return function
function middleware.basicAuth(options)
    return auth.basic(options)
end

--- Bearer token authentication
---@param options table Auth options
---@return function
function middleware.bearerAuth(options)
    return auth.bearer(options)
end

--- API key authentication
---@param options table Auth options
---@return function
function middleware.apiKeyAuth(options)
    return auth.apiKey(options)
end

--- JWT authentication
---@param options table Auth options
---@return function
function middleware.jwtAuth(options)
    return auth.jwt(options)
end

--- Require authenticated user
---@param options table|nil Options
---@return function
function middleware.requireAuth(options)
    return auth.required(options)
end

--- Require specific role(s)
---@param roles string|table Required roles
---@return function
function middleware.requireRoles(roles)
    return auth.roles(roles)
end

--- Custom permission check
---@param check function Check function
---@param message string|nil Error message
---@return function
function middleware.requirePermission(check, message)
    return auth.can(check, message)
end

--------------------------------------------------------------------------------
-- Sessions
--------------------------------------------------------------------------------

--- Session middleware
---@param options table|nil Session options
---@return function
function middleware.session(options)
    return session.create(options)
end

--- Flash messages middleware
---@return function
function middleware.flash()
    return session.flash()
end

--------------------------------------------------------------------------------
-- Security
--------------------------------------------------------------------------------

--- Helmet (all security headers)
---@param options table|nil Security options
---@return function
function middleware.helmet(options)
    return security.helmet(options)
end

--- X-Content-Type-Options: nosniff
middleware.noSniff = security.noSniff

--- X-Frame-Options
middleware.frameguard = security.frameguard

--- X-XSS-Protection
middleware.xssFilter = security.xssFilter

--- Strict-Transport-Security
middleware.hsts = security.hsts

--- Content-Security-Policy
middleware.csp = security.csp

--- Referrer-Policy
middleware.referrerPolicy = security.referrerPolicy

--- Permissions-Policy
middleware.permissionsPolicy = security.permissionsPolicy

--- Hide X-Powered-By
middleware.hidePoweredBy = security.hidePoweredBy

--- CSRF protection
---@param options table|nil CSRF options
---@return function
function middleware.csrf(options)
    return security.csrf(options)
end

--- Request ID middleware
---@param options table|nil Options
---@return function
function middleware.requestId(options)
    return security.requestId(options)
end

--------------------------------------------------------------------------------
-- Utility Middleware
--------------------------------------------------------------------------------

--- Timeout middleware (placeholder)
---@param ms number Timeout in milliseconds
---@param options table|nil Options
---@return function
function middleware.timeout(ms, options)
    options = options or {}
    return function(req, res, next)
        -- Note: True async timeout requires runtime support
        req._timeout = ms
        next()
    end
end

--- Compression middleware (placeholder)
---@param options table|nil Options
---@return function
function middleware.compression(options)
    return function(req, res, next)
        -- Note: Compression requires runtime gzip support
        next()
    end
end

--- Serve favicon
---@param path string|nil Path to favicon file
---@return function
function middleware.favicon(path)
    local icon_data = nil

    return function(req, res, next)
        if req.path ~= "/favicon.ico" then
            return next()
        end

        -- Cache favicon data
        if not icon_data and path then
            local ok, data = pcall(fs.read, path)
            if ok then
                icon_data = data
            end
        end

        if icon_data then
            res:set("Cache-Control", "public, max-age=86400")
            res:type("image/x-icon")
            return res:send(icon_data)
        end

        res:status(204):send("")
    end
end

--- Method override (for forms that only support GET/POST)
---@param options table|nil Options
---@return function
function middleware.methodOverride(options)
    options = options or {}
    local field_name = options.field or "_method"
    local header_name = options.header or "X-HTTP-Method-Override"

    return function(req, res, next)
        if req.method ~= "POST" then
            return next()
        end

        -- Check header
        local override = req:get(header_name)

        -- Check body field
        if not override and req._parsed_body then
            override = req._parsed_body[field_name]
        end

        -- Check query
        if not override then
            override = req.query[field_name]
        end

        if override then
            override = override:upper()
            if override == "PUT" or override == "DELETE" or override == "PATCH" then
                req.method = override
            end
        end

        next()
    end
end

--- Response time header
---@param options table|nil Options
---@return function
function middleware.responseTime(options)
    options = options or {}
    local header = options.header or "X-Response-Time"
    local suffix = options.suffix or "ms"

    return function(req, res, next)
        local start_time = time.monotonic_ms()

        local original_send = res.send
        res.send = function(self, body)
            local duration = time.monotonic_ms() - start_time
            self:set(header, string.format("%.3f%s", duration, suffix))
            return original_send(self, body)
        end

        next()
    end
end

return middleware
