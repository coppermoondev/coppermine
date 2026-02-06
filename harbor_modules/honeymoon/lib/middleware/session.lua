-- HoneyMoon Session Middleware
-- Session management middleware

local utils = require("honeymoon.lib.utils")
local session_lib = require("honeymoon.lib.session")

local middleware = {}

--- Default options
local defaults = {
    name = "honeymoon.sid",
    secret = nil,           -- Will be generated if not provided
    ttl = 86400,            -- 24 hours
    rolling = false,        -- Refresh session on each request
    resave = false,         -- Save session even if not modified
    saveUninitialized = false,  -- Save new empty sessions
    cookie = {
        path = "/",
        httpOnly = true,
        secure = false,
        sameSite = "Lax",
        maxAge = nil,       -- Use ttl if not specified
    }
}

--- Create session middleware
---@param options table|nil Session options
---@return function Middleware function
function middleware.create(options)
    options = options or {}

    -- Merge with defaults
    local config = {}
    for k, v in pairs(defaults) do
        if k == "cookie" then
            config.cookie = {}
            for ck, cv in pairs(defaults.cookie) do
                config.cookie[ck] = (options.cookie and options.cookie[ck] ~= nil)
                    and options.cookie[ck] or cv
            end
        else
            config[k] = options[k] ~= nil and options[k] or v
        end
    end

    -- Generate secret if not provided
    if not config.secret then
        config.secret = utils.random_string(32)
    end

    -- Use ttl for maxAge if not specified
    if config.cookie.maxAge == nil then
        config.cookie.maxAge = config.ttl
    end

    -- Get or create session store
    local store = options.store or session_lib.getDefaultStore()

    return function(req, res, next)
        -- Get session ID from cookie
        local session_id = req:cookie(config.name)
        local is_new_session = false

        -- Validate existing session
        if session_id and not store:exists(session_id) then
            session_id = nil
        end

        -- Create new session if needed
        if not session_id then
            session_id = session_lib.generate_id()
            is_new_session = true
        end

        -- Cookie options for this session
        local cookie_options = {
            path = config.cookie.path,
            httpOnly = config.cookie.httpOnly,
            secure = config.cookie.secure or req.secure,
            sameSite = config.cookie.sameSite,
            maxAge = config.cookie.maxAge,
        }

        -- Create session wrapper
        local session = session_lib.Session(
            session_id,
            store,
            config.ttl,
            res,
            config.name,
            cookie_options
        )

        -- Attach to request
        req.session = session
        req.sessionID = session_id

        -- Set cookie for new sessions
        if is_new_session then
            res:cookie(config.name, session_id, cookie_options)
        elseif config.rolling then
            -- Rolling session: refresh cookie on each request
            res:cookie(config.name, session_id, cookie_options)
            store:touch(session_id, config.ttl)
        end

        -- Wrap response.send to save session
        local original_send = res.send

        res.send = function(self, body)
            -- Save session if modified or resave is true
            if session._modified or config.resave then
                -- Don't save uninitialized sessions unless configured
                if not is_new_session or config.saveUninitialized or session._modified then
                    session:save()
                end
            end

            -- If session was regenerated, the new cookie is already set
            -- in the regenerate() method

            return original_send(self, body)
        end

        next()
    end
end

--- Create flash message helpers
---@return function Middleware function
function middleware.flash()
    return function(req, res, next)
        if not req.session then
            return next()
        end

        -- Read flash messages
        local flash_data = req.session:get("_flash") or {}

        -- Provide flash helper on request
        req.flash = function(key, value)
            if value ~= nil then
                -- Set flash message
                local current = req.session:get("_flash") or {}
                current[key] = current[key] or {}
                if type(current[key]) == "string" then
                    current[key] = { current[key] }
                end
                table.insert(current[key], value)
                req.session:set("_flash", current)
            else
                -- Get flash message
                local messages = flash_data[key]
                flash_data[key] = nil  -- Clear after reading
                return messages
            end
        end

        -- Make flash data available in response locals
        res.locals.flash = flash_data

        -- Clear flash data after reading
        local original_send = res.send
        res.send = function(self, body)
            -- Remove read flash messages
            req.session:set("_flash", nil)
            return original_send(self, body)
        end

        next()
    end
end

return middleware
