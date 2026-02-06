-- HoneyMoon CORS Middleware
-- Cross-Origin Resource Sharing support

local cors = {}

--- Default CORS options
local defaults = {
    origin = "*",
    methods = "GET,HEAD,PUT,PATCH,POST,DELETE",
    allowedHeaders = nil,  -- Mirror request headers by default
    exposedHeaders = nil,
    credentials = false,
    maxAge = 86400,
    preflightContinue = false,
    optionsSuccessStatus = 204,
}

--- Check if origin is allowed
---@param origin string Request origin
---@param allowed string|table|function Allowed origins
---@return boolean, string|nil
local function is_origin_allowed(origin, allowed)
    if allowed == "*" then
        return true, "*"
    end

    if type(allowed) == "function" then
        local result = allowed(origin)
        if result == true then
            return true, origin
        elseif type(result) == "string" then
            return true, result
        end
        return false, nil
    end

    if type(allowed) == "string" then
        if allowed == origin then
            return true, origin
        end
        return false, nil
    end

    if type(allowed) == "table" then
        for _, o in ipairs(allowed) do
            if o == origin then
                return true, origin
            end
            -- Support pattern matching
            if o:sub(1, 1) == "/" and o:sub(-1) == "/" then
                local pattern = o:sub(2, -2)
                if origin:match(pattern) then
                    return true, origin
                end
            end
        end
        return false, nil
    end

    return false, nil
end

--- Create CORS middleware
---@param options table|nil CORS options
---@return function Middleware function
function cors.create(options)
    options = options or {}

    -- Merge with defaults
    local config = {}
    for k, v in pairs(defaults) do
        config[k] = options[k] ~= nil and options[k] or v
    end

    -- Handle legacy option names
    if options.headers then
        config.allowedHeaders = options.headers
    end

    return function(req, res, next)
        local request_origin = req:get("origin")

        -- No origin header = same-origin request
        if not request_origin then
            return next()
        end

        -- Check if origin is allowed
        local allowed, origin_value = is_origin_allowed(request_origin, config.origin)

        if not allowed then
            return next()
        end

        -- Set Access-Control-Allow-Origin
        res:set("Access-Control-Allow-Origin", origin_value)

        -- Vary header (important for caching)
        if origin_value ~= "*" then
            res:vary("Origin")
        end

        -- Handle credentials
        if config.credentials then
            res:set("Access-Control-Allow-Credentials", "true")
        end

        -- Handle exposed headers
        if config.exposedHeaders then
            local exposed = type(config.exposedHeaders) == "table"
                and table.concat(config.exposedHeaders, ",")
                or config.exposedHeaders
            res:set("Access-Control-Expose-Headers", exposed)
        end

        -- Handle preflight request
        if req.method == "OPTIONS" then
            -- Access-Control-Allow-Methods
            local methods = type(config.methods) == "table"
                and table.concat(config.methods, ",")
                or config.methods
            res:set("Access-Control-Allow-Methods", methods)

            -- Access-Control-Allow-Headers
            local allowed_headers = config.allowedHeaders
            if not allowed_headers then
                -- Mirror the request headers
                allowed_headers = req:get("access-control-request-headers")
                if allowed_headers then
                    res:vary("Access-Control-Request-Headers")
                end
            end
            if allowed_headers then
                local headers_str = type(allowed_headers) == "table"
                    and table.concat(allowed_headers, ",")
                    or allowed_headers
                res:set("Access-Control-Allow-Headers", headers_str)
            end

            -- Access-Control-Max-Age
            if config.maxAge then
                res:set("Access-Control-Max-Age", tostring(config.maxAge))
            end

            -- Handle preflight
            if config.preflightContinue then
                return next()
            else
                res:status(config.optionsSuccessStatus)
                return res:send("")
            end
        end

        next()
    end
end

--- Create simple CORS (allow all)
---@return function
function cors.allowAll()
    return cors.create({
        origin = "*",
        methods = "GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS",
        allowedHeaders = "*",
    })
end

--- Create CORS for specific origins
---@param origins table List of allowed origins
---@return function
function cors.origins(origins)
    return cors.create({
        origin = origins,
        credentials = true,
    })
end

return cors
