-- HoneyMoon Security Middleware
-- Security headers and protections (Helmet-like)

local security = {}

--------------------------------------------------------------------------------
-- Helmet (All-in-one Security Headers)
--------------------------------------------------------------------------------

--- Create helmet middleware with all security headers
---@param options table|nil Security options
---@return function Middleware function
function security.helmet(options)
    options = options or {}

    return function(req, res, next)
        -- X-Content-Type-Options
        if options.noSniff ~= false then
            res:set("X-Content-Type-Options", "nosniff")
        end

        -- X-Frame-Options
        if options.frameguard ~= false then
            local frame_option = options.frameguard
            if frame_option == true or frame_option == nil then
                frame_option = "SAMEORIGIN"
            end
            res:set("X-Frame-Options", frame_option)
        end

        -- X-XSS-Protection
        if options.xssFilter ~= false then
            res:set("X-XSS-Protection", "1; mode=block")
        end

        -- X-Download-Options (IE8+)
        if options.ieNoOpen ~= false then
            res:set("X-Download-Options", "noopen")
        end

        -- X-DNS-Prefetch-Control
        if options.dnsPrefetch ~= nil then
            res:set("X-DNS-Prefetch-Control", options.dnsPrefetch and "on" or "off")
        end

        -- Strict-Transport-Security (HSTS)
        if options.hsts then
            local hsts_opts = type(options.hsts) == "table" and options.hsts or {}
            local max_age = hsts_opts.maxAge or 31536000  -- 1 year
            local hsts_value = "max-age=" .. max_age

            if hsts_opts.includeSubDomains then
                hsts_value = hsts_value .. "; includeSubDomains"
            end
            if hsts_opts.preload then
                hsts_value = hsts_value .. "; preload"
            end

            res:set("Strict-Transport-Security", hsts_value)
        end

        -- Content-Security-Policy
        if options.contentSecurityPolicy then
            local csp = options.contentSecurityPolicy
            if type(csp) == "table" then
                csp = security._build_csp(csp)
            end
            res:set("Content-Security-Policy", csp)
        end

        -- Referrer-Policy
        if options.referrerPolicy then
            res:set("Referrer-Policy", options.referrerPolicy)
        end

        -- Permissions-Policy (formerly Feature-Policy)
        if options.permissionsPolicy then
            local pp = options.permissionsPolicy
            if type(pp) == "table" then
                pp = security._build_permissions_policy(pp)
            end
            res:set("Permissions-Policy", pp)
        end

        -- X-Permitted-Cross-Domain-Policies
        if options.crossDomain then
            res:set("X-Permitted-Cross-Domain-Policies", options.crossDomain)
        end

        -- Remove X-Powered-By
        if options.hidePoweredBy ~= false then
            res:remove("X-Powered-By")
        end

        next()
    end
end

--- Build CSP string from table
---@param directives table CSP directives
---@return string
function security._build_csp(directives)
    local parts = {}
    for directive, value in pairs(directives) do
        if type(value) == "table" then
            value = table.concat(value, " ")
        end
        table.insert(parts, directive .. " " .. value)
    end
    return table.concat(parts, "; ")
end

--- Build Permissions-Policy string from table
---@param features table Features configuration
---@return string
function security._build_permissions_policy(features)
    local parts = {}
    for feature, value in pairs(features) do
        if type(value) == "table" then
            value = "(" .. table.concat(value, " ") .. ")"
        elseif value == true then
            value = "*"
        elseif value == false then
            value = "()"
        end
        table.insert(parts, feature .. "=" .. value)
    end
    return table.concat(parts, ", ")
end

--------------------------------------------------------------------------------
-- Individual Security Middleware
--------------------------------------------------------------------------------

--- X-Content-Type-Options: nosniff
---@return function
function security.noSniff()
    return function(req, res, next)
        res:set("X-Content-Type-Options", "nosniff")
        next()
    end
end

--- X-Frame-Options
---@param option string|nil "DENY", "SAMEORIGIN", or "ALLOW-FROM uri"
---@return function
function security.frameguard(option)
    option = option or "SAMEORIGIN"
    return function(req, res, next)
        res:set("X-Frame-Options", option)
        next()
    end
end

--- X-XSS-Protection
---@return function
function security.xssFilter()
    return function(req, res, next)
        res:set("X-XSS-Protection", "1; mode=block")
        next()
    end
end

--- Strict-Transport-Security (HSTS)
---@param options table|nil HSTS options
---@return function
function security.hsts(options)
    options = options or {}
    local max_age = options.maxAge or 31536000
    local value = "max-age=" .. max_age

    if options.includeSubDomains then
        value = value .. "; includeSubDomains"
    end
    if options.preload then
        value = value .. "; preload"
    end

    return function(req, res, next)
        -- Only set HSTS on HTTPS
        if req.secure then
            res:set("Strict-Transport-Security", value)
        end
        next()
    end
end

--- Content-Security-Policy
---@param directives table|string CSP directives
---@return function
function security.csp(directives)
    local csp_value = type(directives) == "table"
        and security._build_csp(directives)
        or directives

    return function(req, res, next)
        res:set("Content-Security-Policy", csp_value)
        next()
    end
end

--- Content-Security-Policy-Report-Only
---@param directives table|string CSP directives
---@return function
function security.cspReportOnly(directives)
    local csp_value = type(directives) == "table"
        and security._build_csp(directives)
        or directives

    return function(req, res, next)
        res:set("Content-Security-Policy-Report-Only", csp_value)
        next()
    end
end

--- Referrer-Policy
---@param policy string Referrer policy
---@return function
function security.referrerPolicy(policy)
    policy = policy or "strict-origin-when-cross-origin"
    return function(req, res, next)
        res:set("Referrer-Policy", policy)
        next()
    end
end

--- Permissions-Policy
---@param features table Features configuration
---@return function
function security.permissionsPolicy(features)
    local value = security._build_permissions_policy(features)
    return function(req, res, next)
        res:set("Permissions-Policy", value)
        next()
    end
end

--- Hide X-Powered-By header
---@return function
function security.hidePoweredBy()
    return function(req, res, next)
        res:remove("X-Powered-By")
        next()
    end
end

--------------------------------------------------------------------------------
-- CSRF Protection
--------------------------------------------------------------------------------

--- Create CSRF protection middleware
---@param options table|nil CSRF options
---@return function
function security.csrf(options)
    options = options or {}
    local cookie_name = options.cookie or "_csrf"
    local header_name = options.header or "x-csrf-token"
    local field_name = options.field or "_csrf"
    local secret = options.secret

    return function(req, res, next)
        -- Generate token if not exists
        local token = req:cookie(cookie_name)
        if not token then
            token = require("honeymoon.lib.utils").random_string(32)
            res:cookie(cookie_name, token, {
                httpOnly = true,
                sameSite = "Strict"
            })
        end

        -- Make token available
        req.csrfToken = function()
            return token
        end
        res.locals.csrfToken = token

        -- Skip verification for safe methods
        if req.method == "GET" or req.method == "HEAD" or req.method == "OPTIONS" then
            return next()
        end

        -- Verify token
        local sent_token = req:get(header_name) or req:param(field_name)

        if not sent_token or sent_token ~= token then
            return res:status(403):json({
                error = "Forbidden",
                message = "Invalid CSRF token"
            })
        end

        next()
    end
end

--------------------------------------------------------------------------------
-- Request ID
--------------------------------------------------------------------------------

--- Add request ID middleware
---@param options table|nil Options
---@return function
function security.requestId(options)
    options = options or {}
    local header = options.header or "X-Request-ID"
    local generator = options.generator or function()
        if crypto and crypto.uuid then
            return crypto.uuid()
        end
        return require("honeymoon.lib.utils").random_string(32)
    end

    return function(req, res, next)
        local id = req:get(header:lower()) or generator()
        req.id = id
        res:set(header, id)
        next()
    end
end

return security
