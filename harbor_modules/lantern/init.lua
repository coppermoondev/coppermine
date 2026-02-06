-- Lantern - Debug Toolbar for HoneyMoon
-- A development debugging tool inspired by Laravel Debugbar, Symfony Profiler
--
-- Usage:
--   local lantern = require("lantern")
--
--   -- Setup with app (automatically adds middleware)
--   lantern.setup(app, {
--       enabled = true,      -- Enable/disable (default: true in dev)
--       vein = veinEngine,   -- Vein engine for template metrics
--   })
--
--   -- Or use as middleware manually
--   app:use(lantern.middleware({ ... }))
--
--   -- Access collector in routes for custom logging
--   app:get("/example", function(req, res)
--       req.lantern:log("info", "Processing request")
--       req.lantern:recordQuery("SELECT * FROM users", nil, 5.2)
--       res:send("OK")
--   end)
--
-- Freight ORM Integration:
--   local db = freight.open("sqlite", { database = "app.db" })
--
--   -- Wrap database for automatic query tracking
--   lantern.freight(db)
--
--   -- Add middleware to connect queries to each request
--   app:use(lantern.freightMiddleware(db))
--
--   -- Now all Freight queries are automatically logged to the debug panel!
--
-- Keyboard shortcut: Ctrl+Shift+L to toggle panel
--
-- @module lantern
-- @author CopperMoon Team
-- @license MIT

local lantern = {}

--------------------------------------------------------------------------------
-- Version
--------------------------------------------------------------------------------

lantern._VERSION = "0.1.0"
lantern._DESCRIPTION = "Debug toolbar for HoneyMoon - inspect requests, responses, templates, and performance"

--------------------------------------------------------------------------------
-- Core Modules
--------------------------------------------------------------------------------

local collector = require("lantern.lib.collector")
local panel = require("lantern.lib.panel")

-- Freight integration is loaded lazily when needed
local _freight_integration = nil
local function getFreightIntegration()
    if not _freight_integration then
        _freight_integration = require("lantern.lib.freight")
    end
    return _freight_integration
end

--------------------------------------------------------------------------------
-- Default Options
--------------------------------------------------------------------------------

local defaultOptions = {
    -- Enable/disable the debugbar
    enabled = true,

    -- Only inject into HTML responses
    htmlOnly = true,

    -- Vein engine reference (for template metrics)
    vein = nil,

    -- Path prefix to ignore (e.g., "/api" to skip API routes)
    ignorePaths = {},

    -- Custom condition to enable (function(req) -> boolean)
    condition = nil,
}

--------------------------------------------------------------------------------
-- Middleware Factory
--------------------------------------------------------------------------------

--- Create the Lantern middleware
---@param options table? Middleware options
---@return function Middleware function
function lantern.middleware(options)
    options = options or {}

    -- Merge with defaults
    for k, v in pairs(defaultOptions) do
        if options[k] == nil then
            options[k] = v
        end
    end

    return function(req, res, next)
        -- Check if enabled
        if not options.enabled then
            return next()
        end

        -- Check custom condition
        if options.condition and not options.condition(req) then
            return next()
        end

        -- Check ignored paths
        for _, ignorePath in ipairs(options.ignorePaths) do
            if req.path:sub(1, #ignorePath) == ignorePath then
                return next()
            end
        end

        -- Create collector for this request
        local coll = collector.new()
        coll:collectRequest(req)

        -- Attach to request for user access
        req.lantern = coll

        -- Store original send method to intercept response
        local originalSend = res.send

        -- Track if this is an HTML response that should get the panel
        local isHtmlResponse = false
        local veinEngine = options.vein

        -- Try to get vein engine from app
        if not veinEngine and req.app and req.app.views and req.app.views.engine then
            veinEngine = req.app.views.engine
        end

        -- Wrap res:send to intercept the final response
        res.send = function(self, body)
            local finalBody = body

            -- Safety wrapper - if anything fails, still send the original response
            local ok, err = pcall(function()
                -- Check content type - only inject into HTML responses
                local contentType = self._headers and self._headers["Content-Type"]
                local shouldInject = contentType and contentType:find("text/html")

                -- If it's HTML, inject the panel
                if shouldInject and body and type(body) == "string" then
                    -- Collect vein metrics before finalizing
                    if veinEngine then
                        pcall(function() coll:collectVeinMetrics(veinEngine) end)
                    end

                    -- Finalize collection
                    coll:collectResponse(self, self._status)
                    coll:finalize()

                    -- Export and inject
                    local exported = coll:export()
                    finalBody = panel.inject(body, exported)
                end
            end)

            -- Log errors but don't break the response
            if not ok then
                print("[Lantern] Warning: " .. tostring(err))
            end

            -- Always call original send with (possibly modified) body
            return originalSend(self, finalBody)
        end

        -- Execute the rest of the middleware chain
        next()
    end
end

--------------------------------------------------------------------------------
-- Setup Helper
--------------------------------------------------------------------------------

--- Setup Lantern with a HoneyMoon app
---@param app table HoneyMoon application
---@param options table? Options
---@return table Lantern module for chaining
function lantern.setup(app, options)
    options = options or {}

    -- Auto-detect development environment
    if options.enabled == nil then
        local env = os_ext and os_ext.env("NODE_ENV") or "development"
        options.enabled = (env ~= "production")
    end

    -- Try to get Vein engine from app
    if not options.vein and app.views and app.views.engine then
        options.vein = app.views.engine

        -- Enable metrics on Vein engine if not already enabled
        if options.vein and options.vein.enableMetrics then
            options.vein:enableMetrics()
        end
    end

    -- Add middleware (should be early in the chain to wrap send)
    app:use(lantern.middleware(options))

    return lantern
end

--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------

--- Create a standalone collector (for manual use)
---@return Collector
function lantern.createCollector()
    return collector.new()
end

--- Generate panel HTML from collected data
---@param data table Collected data from collector:export()
---@return string HTML
function lantern.generatePanel(data)
    return panel.generate(data)
end

--- Inject panel into HTML
---@param html string Original HTML
---@param data table Collected data
---@return string Modified HTML
function lantern.injectPanel(html, data)
    return panel.inject(html, data)
end

--------------------------------------------------------------------------------
-- Logging Helpers (for route handlers)
--------------------------------------------------------------------------------

--- Get the current request's collector
---@param req table HoneyMoon request
---@return Collector?
function lantern.get(req)
    return req.lantern
end

--- Log a message to the current request's collector
---@param req table HoneyMoon request
---@param level string Log level
---@param message string Message
---@param context table? Additional context
function lantern.log(req, level, message, context)
    if req.lantern then
        req.lantern:log(level, message, context)
    end
end

--- Record a database query
---@param req table HoneyMoon request
---@param query string SQL query
---@param params table? Parameters
---@param duration number Duration in ms
---@param rowCount number? Number of rows
function lantern.recordQuery(req, query, params, duration, rowCount)
    if req.lantern then
        req.lantern:recordQuery(query, params, duration, rowCount)
    end
end

--- Add a timeline event
---@param req table HoneyMoon request
---@param id string Event ID
---@param label string Event label
---@param data table? Additional data
function lantern.addEvent(req, id, label, data)
    if req.lantern then
        req.lantern:addTimelineEvent(id, label, data)
    end
end

--------------------------------------------------------------------------------
-- Freight ORM Integration
--------------------------------------------------------------------------------

--- Setup Freight database logging
--- This wraps the database methods to automatically track queries
---
--- Usage:
---   local db = freight.open("sqlite", { database = "app.db" })
---   lantern.freight(db)  -- Now all queries are tracked
---
---   -- Then add the middleware to connect queries to requests
---   app:use(lantern.freightMiddleware(db))
---
---@param db table Freight database instance
---@param options table? Options
---@return table Logger instance
function lantern.freight(db, options)
    return getFreightIntegration().setup(db, options)
end

--- Create Freight middleware that connects query logging to request collector
--- This middleware connects the global Freight logger to the per-request collector
---
--- Usage:
---   -- After lantern.setup() and lantern.freight(db)
---   app:use(lantern.freightMiddleware(db))
---
---@param db table Freight database instance
---@return function Middleware
function lantern.freightMiddleware(db)
    return getFreightIntegration().middleware(db)
end

--- Get Freight global stats
--- Returns cumulative statistics for all queries since startup
---@return table { totalQueries, totalDuration, queryTypes }
function lantern.getFreightStats()
    return getFreightIntegration().getStats()
end

--- Reset Freight global stats
function lantern.resetFreightStats()
    return getFreightIntegration().resetStats()
end

--------------------------------------------------------------------------------
-- Export submodules
--------------------------------------------------------------------------------

lantern.collector = collector
lantern.panel = panel

-- Lazy accessor for freight integration
setmetatable(lantern, {
    __index = function(t, k)
        if k == "freightIntegration" then
            return getFreightIntegration()
        end
        return rawget(t, k)
    end
})

return lantern
