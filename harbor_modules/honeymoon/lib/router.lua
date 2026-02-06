-- HoneyMoon Router Module
-- Route handling and pattern matching

local utils = require("honeymoon.lib.utils")

local router = {}

--------------------------------------------------------------------------------
-- Route Pattern Compilation
--------------------------------------------------------------------------------

--- Compile a route pattern into a regex pattern
---@param path string Route path
---@return string pattern, table param_names
function router.compile_pattern(path)
    local param_names = {}

    -- Escape special regex characters (except : and *)
    local pattern = path:gsub("([%.%+%-%?%[%]%^%$%(%)%%])", "%%%1")

    -- Replace :param with capture groups
    pattern = pattern:gsub(":([%w_]+)", function(param)
        table.insert(param_names, param)
        return "([^/]+)"
    end)

    -- Replace * with wildcard (capture rest of path)
    pattern = pattern:gsub("%*", "(.*)")

    -- Anchor pattern
    pattern = "^" .. pattern .. "$"

    return pattern, param_names
end

--- Match a route against a path
---@param route table Route definition
---@param path string Request path
---@param method string HTTP method
---@return table|nil Params if matched, nil otherwise
function router.match_route(route, path, method)
    -- Check method
    if route.method ~= "ALL" and route.method ~= method then
        return nil
    end

    -- Match pattern
    local captures = {path:match(route.pattern)}

    -- No match
    if #captures == 0 then
        -- Check for parameterless exact match
        if #route.param_names == 0 then
            if path:match(route.pattern) then
                return {}
            end
        end
        return nil
    end

    -- Build params table
    local params = {}
    for i, name in ipairs(route.param_names) do
        params[name] = captures[i]
    end

    -- Handle wildcard capture
    if route.has_wildcard and captures[#captures] then
        params["*"] = captures[#captures]
        params["wildcard"] = captures[#captures]
    end

    return params
end

--------------------------------------------------------------------------------
-- Router Class
--------------------------------------------------------------------------------

---@class Router
---@field _routes table Route definitions
---@field _middleware table Middleware stack
---@field _prefix string Route prefix
local Router = {}
Router.__index = Router

--- Create a new router
---@return Router
function router.new()
    local self = setmetatable({}, Router)
    self._routes = {}
    self._middleware = {}
    self._prefix = ""
    return self
end

--- Add a route
---@param method string HTTP method
---@param path string Route path
---@param ... function Handler(s)
---@return Router
function Router:route(method, path, ...)
    local handlers = {...}
    local pattern, param_names = router.compile_pattern(path)
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
function Router:get(path, ...) return self:route("GET", path, ...) end
function Router:post(path, ...) return self:route("POST", path, ...) end
function Router:put(path, ...) return self:route("PUT", path, ...) end
function Router:delete(path, ...) return self:route("DELETE", path, ...) end
function Router:patch(path, ...) return self:route("PATCH", path, ...) end
function Router:options(path, ...) return self:route("OPTIONS", path, ...) end
function Router:head(path, ...) return self:route("HEAD", path, ...) end

--- Handle all HTTP methods
---@param path string Route path
---@param ... function Handler(s)
---@return Router
function Router:all(path, ...)
    return self:route("ALL", path, ...)
end

--- Add middleware
---@param path_or_fn string|function Path or middleware function
---@param fn function|nil Middleware function (if path provided)
---@return Router
function Router:use(path_or_fn, fn)
    local path, handler
    if type(path_or_fn) == "function" then
        path = nil  -- Global middleware
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

--- Get all routes
---@return table
function Router:getRoutes()
    return self._routes
end

--- Get all middleware
---@return table
function Router:getMiddleware()
    return self._middleware
end

--------------------------------------------------------------------------------
-- Route Builder (for chained route definition)
--------------------------------------------------------------------------------

---@class RouteBuilder
local RouteBuilder = {}
RouteBuilder.__index = RouteBuilder

--- Create a route builder for a path
---@param router_instance Router
---@param path string
---@return RouteBuilder
function router.route_builder(router_instance, path)
    local self = setmetatable({}, RouteBuilder)
    self._router = router_instance
    self._path = path
    return self
end

function RouteBuilder:get(...) self._router:get(self._path, ...) return self end
function RouteBuilder:post(...) self._router:post(self._path, ...) return self end
function RouteBuilder:put(...) self._router:put(self._path, ...) return self end
function RouteBuilder:delete(...) self._router:delete(self._path, ...) return self end
function RouteBuilder:patch(...) self._router:patch(self._path, ...) return self end
function RouteBuilder:options(...) self._router:options(self._path, ...) return self end
function RouteBuilder:head(...) self._router:head(self._path, ...) return self end
function RouteBuilder:all(...) self._router:all(self._path, ...) return self end

--- Define multiple methods on a route path
---@param path string Route path
---@return RouteBuilder
function Router:routePath(path)
    return router.route_builder(self, path)
end

return router
