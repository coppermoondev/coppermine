-- HoneyMoon Application Module
-- Core application class

local utils = require("honeymoon.lib.utils")
local errors = require("honeymoon.lib.errors")
local request_mod = require("honeymoon.lib.request")
local response_mod = require("honeymoon.lib.response")
local router_mod = require("honeymoon.lib.router")
local view_mod = require("honeymoon.lib.view")

local application = {}

--------------------------------------------------------------------------------
-- Application Class
--------------------------------------------------------------------------------

---@class Application
---@field _routes table Route definitions
---@field _middleware table Middleware stack
---@field _error_handlers table Error handlers
---@field _settings table Application settings
---@field _VERSION string Framework version
local Application = {}
Application.__index = Application

--- Create a new application
---@return Application
function application.new()
    local self = setmetatable({}, Application)

    self._routes = {}
    self._middleware = {}
    self._error_handlers = {}
    self._VERSION = "0.2.0"

    -- Default settings
    self._settings = {
        port = 3000,
        host = "127.0.0.1",
        env = (os_ext and os_ext.env("NODE_ENV")) or "development",
        trust_proxy = false,
        json_spaces = 0,
        etag = true,
        query_parser = "extended",
        views = "./views",
    }

    -- View engine
    self.views = view_mod.new(self)

    return self
end

--------------------------------------------------------------------------------
-- Settings
--------------------------------------------------------------------------------

--- Set a setting value
---@param key string Setting name
---@param value any Setting value
---@return Application
function Application:set(key, value)
    self._settings[key] = value
    return self
end

--- Get a setting value
---@param key string Setting name
---@return any
function Application:get_setting(key)
    return self._settings[key]
end

--- Enable a boolean setting
---@param key string Setting name
---@return Application
function Application:enable(key)
    self._settings[key] = true
    return self
end

--- Disable a boolean setting
---@param key string Setting name
---@return Application
function Application:disable(key)
    self._settings[key] = false
    return self
end

--- Check if setting is enabled
---@param key string Setting name
---@return boolean
function Application:enabled(key)
    return self._settings[key] == true
end

--- Check if setting is disabled
---@param key string Setting name
---@return boolean
function Application:disabled(key)
    return not self._settings[key]
end

--------------------------------------------------------------------------------
-- Routing
--------------------------------------------------------------------------------

--- Add a route
---@param method string HTTP method
---@param path string Route path
---@param ... function Handler(s)
---@return Application
function Application:route(method, path, ...)
    local handlers = {...}
    local pattern, param_names = router_mod.compile_pattern(path)
    local has_wildcard = path:find("%*") ~= nil

    table.insert(self._routes, {
        method = method:upper(),
        path = path,
        pattern = pattern,
        param_names = param_names,
        has_wildcard = has_wildcard,
        handlers = handlers
    })

    return self
end

--- HTTP method shortcuts
function Application:get(path, ...) return self:route("GET", path, ...) end
function Application:post(path, ...) return self:route("POST", path, ...) end
function Application:put(path, ...) return self:route("PUT", path, ...) end
function Application:delete(path, ...) return self:route("DELETE", path, ...) end
function Application:patch(path, ...) return self:route("PATCH", path, ...) end
function Application:options(path, ...) return self:route("OPTIONS", path, ...) end
function Application:head(path, ...) return self:route("HEAD", path, ...) end

--- Handle all HTTP methods
---@param path string Route path
---@param ... function Handler(s)
---@return Application
function Application:all(path, ...)
    return self:route("ALL", path, ...)
end

--------------------------------------------------------------------------------
-- Middleware
--------------------------------------------------------------------------------

--- Add middleware
---@param path_or_fn string|function Path or middleware function
---@param fn function|nil Middleware function (if path provided)
---@return Application
function Application:use(path_or_fn, fn)
    local path, handler
    if type(path_or_fn) == "function" then
        path = "*"  -- Global middleware
        handler = path_or_fn
    else
        path = path_or_fn
        handler = fn
    end

    table.insert(self._middleware, {
        path = path,
        handler = handler
    })

    return self
end

--------------------------------------------------------------------------------
-- Router Mounting
--------------------------------------------------------------------------------

--- Create a new router
---@return Router
function Application:router()
    return router_mod.new()
end

--- Mount a router at a path
---@param base_path string Base path
---@param router Router Router instance
---@return Application
function Application:mount(base_path, router)
    -- Normalize base path
    if base_path:sub(-1) == "/" and #base_path > 1 then
        base_path = base_path:sub(1, -2)
    end

    -- Mount router middleware
    for _, mw in ipairs(router:getMiddleware()) do
        local mw_path = mw.path
        if mw_path then
            mw_path = base_path .. mw_path
        else
            mw_path = base_path
        end
        self:use(mw_path, mw.handler)
    end

    -- Mount router routes
    for _, route in ipairs(router:getRoutes()) do
        local full_path = base_path .. route.path
        -- Clean up double slashes and trailing slash
        full_path = full_path:gsub("//+", "/")
        if full_path:sub(-1) == "/" and #full_path > 1 then
            full_path = full_path:sub(1, -2)
        end

        local pattern, param_names = router_mod.compile_pattern(full_path)
        table.insert(self._routes, {
            method = route.method,
            path = full_path,
            pattern = pattern,
            param_names = param_names,
            has_wildcard = route.has_wildcard,
            handlers = route.handlers
        })
    end

    return self
end

--------------------------------------------------------------------------------
-- Error Handling
--------------------------------------------------------------------------------

--- Add error handler
---@param fn function Error handler function(err, req, res, stack)
---@return Application
function Application:error(fn)
    table.insert(self._error_handlers, fn)
    return self
end

--- Handle an error
---@param err any Error object
---@param req Request Request object
---@param res Response Response object
function Application:_handleError(err, req, res)
    local err_str = tostring(err)
    local stack = debug and debug.traceback and debug.traceback(err_str, 2) or err_str

    -- Handle ValidationError specially
    if errors.is_validation_error(err) then
        if not res:sent() then
            return res:status(422):json(errors.json_validation_error(err.errors))
        end
        return
    end

    -- Handle HttpError
    if errors.is_http_error(err) then
        if not res:sent() then
            if req:accepts("html") then
                return res:errorPage(err.status, err.message, stack)
            else
                return res:status(err.status):json(errors.json_error(err.status, err.message, err.code))
            end
        end
        return
    end

    -- Run custom error handlers
    for _, handler in ipairs(self._error_handlers) do
        local ok = pcall(handler, err, req, res, stack)
        if ok and res:sent() then
            return
        end
    end

    -- Default error handling
    local is_production = self._settings.env == "production"

    if not is_production then
        print("[HoneyMoon Error]", err_str)
        print(stack)
    end

    if not res:sent() then
        if req:accepts("html") then
            res:errorPage(500, err_str, stack)
        else
            res:status(500):json(errors.json_error(
                500,
                is_production and "Internal Server Error" or err_str,
                "INTERNAL_ERROR"
            ))
        end
    end
end

--------------------------------------------------------------------------------
-- Request Handling
--------------------------------------------------------------------------------

--- Handle an incoming request
---@param ctx table Raw request context
---@param method string HTTP method
function Application:_handleRequest(ctx, method)
    local path = ctx.path

    -- Normalize trailing slashes: /blog/foo/ -> /blog/foo
    if #path > 1 and path:sub(-1) == "/" then
        path = path:sub(1, -2)
        ctx.path = path
    end

    local req = request_mod.new(ctx, self)
    local res = response_mod.new(ctx, self)

    local function run_handlers()
        -- Run middleware
        local middleware_index = 1
        local function next_middleware(err)
            if err then
                return self:_handleError(err, req, res)
            end

            while middleware_index <= #self._middleware do
                local mw = self._middleware[middleware_index]
                middleware_index = middleware_index + 1

                -- Check if middleware path matches
                local matches = false
                if mw.path == "*" then
                    matches = true
                elseif path:sub(1, #mw.path) == mw.path then
                    matches = true
                end

                if matches then
                    -- Set baseUrl for the middleware (allows static files to strip prefix)
                    local oldBaseUrl = req.baseUrl
                    if mw.path ~= "*" then
                        req.baseUrl = mw.path
                    end

                    local ok, mw_err = pcall(mw.handler, req, res, next_middleware)

                    -- Restore baseUrl
                    req.baseUrl = oldBaseUrl

                    if not ok then
                        return self:_handleError(mw_err, req, res)
                    end
                    if res:sent() then
                        return
                    end
                    -- Middleware called next(), continue in next iteration
                    return
                end
            end

            -- All middleware done, find matching route
            for _, route in ipairs(self._routes) do
                local params = router_mod.match_route(route, path, method)
                if params then
                    req.params = params

                    -- Run route handlers
                    local handler_index = 1
                    local function next_handler(handler_err)
                        if handler_err then
                            return self:_handleError(handler_err, req, res)
                        end

                        if handler_index <= #route.handlers then
                            local handler = route.handlers[handler_index]
                            handler_index = handler_index + 1

                            local ok, h_err = pcall(handler, req, res, next_handler)
                            if not ok then
                                return self:_handleError(h_err, req, res)
                            end
                        end
                    end

                    next_handler()
                    return
                end
            end

            -- No route matched - 404
            if req:accepts("html") then
                res:errorPage(404, "The requested resource was not found")
            else
                res:status(404):json({
                    error = "Not Found",
                    message = "The requested resource was not found",
                    path = path
                })
            end
        end

        next_middleware()
    end

    local ok, err = pcall(run_handlers)
    if not ok then
        self:_handleError(err, req, res)
    end
end

--------------------------------------------------------------------------------
-- Server
--------------------------------------------------------------------------------

--- Start listening for requests
---@param port number|nil Port number
---@param callback function|nil Callback when server starts
function Application:listen(port, callback)
    port = port or self._settings.port

    local server = http.server.new()

    -- Register handlers for all methods
    server:get("*", function(ctx) return self:_handleRequest(ctx, "GET") end)
    server:post("*", function(ctx) return self:_handleRequest(ctx, "POST") end)
    server:put("*", function(ctx) return self:_handleRequest(ctx, "PUT") end)
    server:delete("*", function(ctx) return self:_handleRequest(ctx, "DELETE") end)

    -- Additional methods if supported
    if server.patch then
        server:patch("*", function(ctx) return self:_handleRequest(ctx, "PATCH") end)
    end
    if server.options then
        server:options("*", function(ctx) return self:_handleRequest(ctx, "OPTIONS") end)
    end
    if server.head then
        server:head("*", function(ctx) return self:_handleRequest(ctx, "HEAD") end)
    end

    if callback then
        callback(port)
    else
        print(string.format(
            "HoneyMoon v%s listening on http://%s:%d",
            self._VERSION,
            self._settings.host,
            port
        ))
    end

    server:listen(port)
end

return application
