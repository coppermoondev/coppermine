-- HoneyMoon Auth Middleware
-- Authentication middleware (Basic, Bearer, API Key)

local utils = require("honeymoon.lib.utils")

local auth = {}

--------------------------------------------------------------------------------
-- Basic Authentication
--------------------------------------------------------------------------------

--- Create Basic Auth middleware
---@param options table Auth options
---@return function Middleware function
function auth.basic(options)
    options = options or {}

    local users = options.users or {}           -- { username = "password", ... }
    local realm = options.realm or "Restricted"
    local validate = options.validate           -- function(username, password) -> bool|user
    local unauthorized_message = options.message or "Authentication required"

    return function(req, res, next)
        local auth_header = req:get("authorization")

        -- No auth header
        if not auth_header or not auth_header:find("^Basic ") then
            res:set("WWW-Authenticate", 'Basic realm="' .. realm .. '"')
            return res:status(401):send(unauthorized_message)
        end

        -- Decode credentials
        local encoded = auth_header:sub(7)  -- Remove "Basic "
        local decoded = utils.base64_decode(encoded)
        local username, password = decoded:match("^([^:]+):(.*)$")

        if not username then
            res:set("WWW-Authenticate", 'Basic realm="' .. realm .. '"')
            return res:status(401):send("Invalid credentials format")
        end

        -- Validate credentials
        local is_valid = false
        local user_data = nil

        if validate then
            -- Custom validation function
            local result = validate(username, password, req)
            if result == true then
                is_valid = true
                user_data = { username = username }
            elseif type(result) == "table" then
                is_valid = true
                user_data = result
            end
        elseif users[username] then
            -- Simple users table validation
            if users[username] == password then
                is_valid = true
                user_data = { username = username }
            end
        end

        if not is_valid then
            res:set("WWW-Authenticate", 'Basic realm="' .. realm .. '"')
            return res:status(401):send("Invalid credentials")
        end

        -- Set user on request
        req.user = user_data
        next()
    end
end

--------------------------------------------------------------------------------
-- Bearer Token Authentication
--------------------------------------------------------------------------------

--- Create Bearer Auth middleware
---@param options table Auth options
---@return function Middleware function
function auth.bearer(options)
    options = options or {}

    local validate = options.validate           -- function(token) -> user|nil
    local error_message = options.message or "Invalid or expired token"

    return function(req, res, next)
        local auth_header = req:get("authorization")

        -- No auth header
        if not auth_header or not auth_header:find("^Bearer ") then
            return res:status(401):json({
                error = "Unauthorized",
                message = "Bearer token required"
            })
        end

        -- Extract token
        local token = auth_header:sub(8)  -- Remove "Bearer "

        if not token or #token == 0 then
            return res:status(401):json({
                error = "Unauthorized",
                message = "Token is empty"
            })
        end

        -- Validate token
        if validate then
            local user = validate(token, req)
            if user then
                req.user = user
                return next()
            end
        end

        return res:status(401):json({
            error = "Unauthorized",
            message = error_message
        })
    end
end

--------------------------------------------------------------------------------
-- API Key Authentication
--------------------------------------------------------------------------------

--- Create API Key Auth middleware
---@param options table Auth options
---@return function Middleware function
function auth.apiKey(options)
    options = options or {}

    local header_name = options.header or "x-api-key"
    local query_name = options.query or "api_key"
    local keys = options.keys or {}             -- { "key1" = user_data, ... } or { "key1", "key2" }
    local validate = options.validate           -- function(key) -> user|nil

    return function(req, res, next)
        -- Try header first, then query
        local api_key = req:get(header_name) or req.query[query_name]

        if not api_key then
            return res:status(401):json({
                error = "Unauthorized",
                message = "API key required"
            })
        end

        -- Validate key
        local user = nil

        if validate then
            user = validate(api_key, req)
        elseif type(keys) == "table" then
            -- Check if keys is array or map
            if keys[1] then
                -- Array of valid keys
                for _, valid_key in ipairs(keys) do
                    if valid_key == api_key then
                        user = { apiKey = api_key }
                        break
                    end
                end
            else
                -- Map of key -> user data
                user = keys[api_key]
            end
        end

        if not user then
            return res:status(401):json({
                error = "Unauthorized",
                message = "Invalid API key"
            })
        end

        req.user = user
        next()
    end
end

--------------------------------------------------------------------------------
-- JWT Authentication (Placeholder)
--------------------------------------------------------------------------------

--- Create JWT Auth middleware
---@param options table Auth options
---@return function Middleware function
function auth.jwt(options)
    options = options or {}

    local secret = options.secret
    local validate = options.validate or function(payload)
        return payload
    end

    -- Note: Full JWT implementation requires crypto support
    -- This is a placeholder that expects a validate function

    return function(req, res, next)
        local auth_header = req:get("authorization")

        if not auth_header or not auth_header:find("^Bearer ") then
            return res:status(401):json({
                error = "Unauthorized",
                message = "JWT token required"
            })
        end

        local token = auth_header:sub(8)

        -- Simple JWT structure check (header.payload.signature)
        local parts = {}
        for part in token:gmatch("[^.]+") do
            table.insert(parts, part)
        end

        if #parts ~= 3 then
            return res:status(401):json({
                error = "Unauthorized",
                message = "Invalid JWT format"
            })
        end

        -- Decode payload (middle part)
        local ok, payload_json = pcall(utils.base64_decode, parts[2])
        if not ok then
            return res:status(401):json({
                error = "Unauthorized",
                message = "Invalid JWT payload"
            })
        end

        local ok2, payload = pcall(json.decode, payload_json)
        if not ok2 then
            return res:status(401):json({
                error = "Unauthorized",
                message = "Invalid JWT payload JSON"
            })
        end

        -- Check expiration
        if payload.exp and payload.exp < os.time() then
            return res:status(401):json({
                error = "Unauthorized",
                message = "Token has expired"
            })
        end

        -- Validate payload
        local user = validate(payload, req)
        if not user then
            return res:status(401):json({
                error = "Unauthorized",
                message = "Token validation failed"
            })
        end

        req.user = user
        next()
    end
end

--------------------------------------------------------------------------------
-- Combined Auth (try multiple methods)
--------------------------------------------------------------------------------

--- Create combined auth middleware
---@param methods table Array of auth middleware functions
---@return function
function auth.any(methods)
    return function(req, res, next)
        local last_error = nil

        for _, method in ipairs(methods) do
            local success = false
            local captured_next = function()
                success = true
            end

            -- Try this auth method
            method(req, res, captured_next)

            if success and req.user then
                return next()
            end
        end

        -- All methods failed
        return res:status(401):json({
            error = "Unauthorized",
            message = "Authentication required"
        })
    end
end

--------------------------------------------------------------------------------
-- Authorization Helpers
--------------------------------------------------------------------------------

--- Require authenticated user
---@param options table|nil Options
---@return function
function auth.required(options)
    options = options or {}
    local message = options.message or "Authentication required"

    return function(req, res, next)
        if not req.user then
            return res:status(401):json({
                error = "Unauthorized",
                message = message
            })
        end
        next()
    end
end

--- Require specific role(s)
---@param roles string|table Required role(s)
---@return function
function auth.roles(roles)
    if type(roles) == "string" then
        roles = { roles }
    end

    return function(req, res, next)
        if not req.user then
            return res:status(401):json({
                error = "Unauthorized",
                message = "Authentication required"
            })
        end

        local user_role = req.user.role or req.user.roles

        -- Check if user has required role
        local has_role = false

        if type(user_role) == "string" then
            for _, role in ipairs(roles) do
                if user_role == role then
                    has_role = true
                    break
                end
            end
        elseif type(user_role) == "table" then
            for _, required in ipairs(roles) do
                for _, user_r in ipairs(user_role) do
                    if user_r == required then
                        has_role = true
                        break
                    end
                end
                if has_role then break end
            end
        end

        if not has_role then
            return res:status(403):json({
                error = "Forbidden",
                message = "Insufficient permissions"
            })
        end

        next()
    end
end

--- Require custom permission check
---@param check function Check function(req) -> bool
---@param message string|nil Error message
---@return function
function auth.can(check, message)
    message = message or "Access denied"

    return function(req, res, next)
        if not check(req) then
            return res:status(403):json({
                error = "Forbidden",
                message = message
            })
        end
        next()
    end
end

return auth
