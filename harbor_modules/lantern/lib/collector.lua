-- Lantern Collector
-- Gathers debug information for requests
--
-- @module lantern.lib.collector

local collector = {}

--------------------------------------------------------------------------------
-- Collector Class
--------------------------------------------------------------------------------

local Collector = {}
Collector.__index = Collector

--- Create a new collector for a request
---@return Collector
function collector.new()
    local self = setmetatable({}, Collector)

    -- Timing
    self.startTime = os.clock()
    self.startTimestamp = os.time()
    self.endTime = nil

    -- Request data
    self.request = {
        method = nil,
        path = nil,
        fullUrl = nil,
        headers = {},
        query = {},
        params = {},
        body = nil,
        bodySize = 0,
        ip = nil,
        cookies = {},
    }

    -- Response data
    self.response = {
        status = nil,
        statusText = nil,
        headers = {},
        bodySize = 0,
        contentType = nil,
    }

    -- Template/Vein data
    self.templates = {
        renders = {},
        totalTime = 0,
        cacheHits = 0,
        cacheMisses = 0,
        errors = {},
    }

    -- Logs
    self.logs = {}

    -- Queries (for database debugging)
    self.queries = {}
    self.totalQueryTime = 0

    -- Custom data (user can add their own)
    self.custom = {}

    -- Middleware stack
    self.middlewares = {}

    -- Memory tracking
    self.memoryStart = collectgarbage("count")
    self.memoryEnd = nil
    self.memoryPeak = self.memoryStart

    -- Timeline events
    self.timeline = {}

    return self
end

--------------------------------------------------------------------------------
-- Request Collection
--------------------------------------------------------------------------------

--- Collect request data
---@param req table HoneyMoon request object
function Collector:collectRequest(req)
    self.request.method = req.method
    self.request.path = req.path
    self.request.fullUrl = req:originalUrl()
    self.request.headers = self:_copyTable(req.headers)
    self.request.query = self:_copyTable(req.query)
    self.request.params = self:_copyTable(req.params)
    self.request.body = req.body
    self.request.bodySize = req.body and #req.body or 0
    self.request.ip = req.ip
    self.request.protocol = req.protocol
    self.request.hostname = req.hostname
    self.request.secure = req.secure
    self.request.xhr = req.xhr

    -- Try to parse cookies
    if req.cookies then
        local ok, cookies = pcall(function() return req:cookies() end)
        if ok then
            self.request.cookies = self:_copyTable(cookies)
        end
    end

    -- Try to parse body
    if req.body and #req.body > 0 then
        local contentType = req.headers["content-type"] or ""
        if contentType:find("application/json") then
            local ok, parsed = pcall(json.decode, req.body)
            if ok then
                self.request.parsedBody = parsed
                self.request.bodyType = "json"
            end
        elseif contentType:find("application/x-www-form-urlencoded") then
            self.request.bodyType = "form"
        else
            self.request.bodyType = "raw"
        end
    end

    self:addTimelineEvent("request_received", "Request received")
end

--------------------------------------------------------------------------------
-- Response Collection
--------------------------------------------------------------------------------

--- Collect response data
---@param res table HoneyMoon response object
---@param statusCode number HTTP status code
function Collector:collectResponse(res, statusCode)
    self.response.status = statusCode or res._status or 200
    self.response.statusText = self:_getStatusText(self.response.status)
    self.response.headers = self:_copyTable(res._headers or {})
    self.response.contentType = res._headers and res._headers["content-type"]

    -- Body size (approximate)
    if res._body then
        self.response.bodySize = #tostring(res._body)
    end

    self:addTimelineEvent("response_sent", "Response sent")
end

--------------------------------------------------------------------------------
-- Template/Vein Collection
--------------------------------------------------------------------------------

--- Collect Vein metrics from engine
---@param veinEngine table Vein engine instance
function Collector:collectVeinMetrics(veinEngine)
    if not veinEngine then return end

    -- Check if metrics are enabled
    local metrics = veinEngine:getMetrics()
    if not metrics then return end

    local exported = metrics:export()
    if not exported then return end

    -- Summary
    if exported.summary then
        self.templates.totalRenders = exported.summary.renders.total
        self.templates.totalTime = exported.summary.renders.totalTime
        self.templates.avgTime = exported.summary.renders.avgTime
        self.templates.cacheHits = exported.summary.cache.hits
        self.templates.cacheMisses = exported.summary.cache.misses
        self.templates.cacheHitRate = exported.summary.cache.hitRate
    end

    -- Individual renders
    if exported.renders then
        for name, stats in pairs(exported.renders) do
            table.insert(self.templates.renders, {
                name = name,
                count = stats.count,
                totalTime = stats.totalTime,
                avgTime = stats.avgTime,
                minTime = stats.minTime,
                maxTime = stats.maxTime,
            })
        end
        -- Sort by total time descending
        table.sort(self.templates.renders, function(a, b)
            return (a.totalTime or 0) > (b.totalTime or 0)
        end)
    end

    -- Errors
    if exported.errors then
        self.templates.errors = exported.errors
    end

    -- Includes
    if exported.includes then
        self.templates.includes = exported.includes
    end

    -- Filter usage
    if exported.filterUsage then
        self.templates.filterUsage = exported.filterUsage
    end

    self:addTimelineEvent("vein_collected", "Vein metrics collected")
end

--------------------------------------------------------------------------------
-- Logging
--------------------------------------------------------------------------------

--- Add a log entry
---@param level string Log level (debug, info, warning, error)
---@param message string Log message
---@param context table? Additional context
function Collector:log(level, message, context)
    table.insert(self.logs, {
        level = level,
        message = message,
        context = context,
        time = os.clock() - self.startTime,
        timestamp = os.time(),
    })
end

--- Shorthand log methods
function Collector:debug(message, context)
    self:log("debug", message, context)
end

function Collector:info(message, context)
    self:log("info", message, context)
end

function Collector:warning(message, context)
    self:log("warning", message, context)
end

function Collector:error(message, context)
    self:log("error", message, context)
end

--------------------------------------------------------------------------------
-- Query Tracking
--------------------------------------------------------------------------------

--- Record a database query
---@param query string SQL query
---@param params table? Query parameters
---@param duration number Execution time in ms
---@param rowCount number? Number of rows affected/returned
---@param queryType string? Query type (SELECT, INSERT, UPDATE, DELETE)
---@param results table? Query results (for SELECT queries)
---@param lastInsertId number? Last insert ID (for INSERT queries)
function Collector:recordQuery(query, params, duration, rowCount, queryType, results, lastInsertId)
    -- Auto-detect query type if not provided
    if not queryType then
        local sql_upper = query:upper():match("^%s*(%w+)")
        if sql_upper then
            queryType = sql_upper
        else
            queryType = "UNKNOWN"
        end
    end

    table.insert(self.queries, {
        query = query,
        params = params,
        duration = duration or 0,
        rowCount = rowCount,
        type = queryType,
        time = os.clock() - self.startTime,
        index = #self.queries + 1,
        results = results,         -- Query results for inspection
        lastInsertId = lastInsertId, -- Last insert ID for INSERT queries
    })
    self.totalQueryTime = self.totalQueryTime + (duration or 0)
end

--- Get query statistics
---@return table
function Collector:getQueryStats()
    local stats = {
        total = #self.queries,
        totalTime = self.totalQueryTime,
        byType = {},
        slowest = nil,
        slowestTime = 0,
    }

    for _, q in ipairs(self.queries) do
        local qtype = q.type or "UNKNOWN"
        stats.byType[qtype] = (stats.byType[qtype] or 0) + 1

        if q.duration and q.duration > stats.slowestTime then
            stats.slowestTime = q.duration
            stats.slowest = q
        end
    end

    return stats
end

--------------------------------------------------------------------------------
-- Middleware Tracking
--------------------------------------------------------------------------------

--- Record middleware execution
---@param name string Middleware name
---@param duration number Execution time in ms
function Collector:recordMiddleware(name, duration)
    table.insert(self.middlewares, {
        name = name,
        duration = duration,
        time = os.clock() - self.startTime,
    })
end

--------------------------------------------------------------------------------
-- Timeline
--------------------------------------------------------------------------------

--- Add a timeline event
---@param id string Event identifier
---@param label string Event label
---@param data table? Additional data
function Collector:addTimelineEvent(id, label, data)
    table.insert(self.timeline, {
        id = id,
        label = label,
        time = os.clock() - self.startTime,
        timestamp = os.time(),
        data = data,
    })
end

--------------------------------------------------------------------------------
-- Custom Data
--------------------------------------------------------------------------------

--- Add custom data to the collector
---@param key string Data key
---@param value any Data value
function Collector:set(key, value)
    self.custom[key] = value
end

--- Get custom data
---@param key string Data key
---@return any
function Collector:get(key)
    return self.custom[key]
end

--------------------------------------------------------------------------------
-- Memory Tracking
--------------------------------------------------------------------------------

--- Update memory tracking
function Collector:updateMemory()
    local current = collectgarbage("count")
    if current > self.memoryPeak then
        self.memoryPeak = current
    end
end

--------------------------------------------------------------------------------
-- Finalization
--------------------------------------------------------------------------------

--- Finalize collection (call at end of request)
function Collector:finalize()
    self.endTime = os.clock()
    self.memoryEnd = collectgarbage("count")
    self:addTimelineEvent("request_complete", "Request complete")
end

--- Get total request duration in milliseconds
---@return number
function Collector:getDuration()
    local endTime = self.endTime or os.clock()
    return (endTime - self.startTime) * 1000
end

--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

--- Export all collected data
---@return table
function Collector:export()
    return {
        -- Timing
        duration = self:getDuration(),
        startTimestamp = self.startTimestamp,

        -- Request/Response
        request = self.request,
        response = self.response,

        -- Templates
        templates = self.templates,

        -- Logs
        logs = self.logs,
        logCounts = self:_countLogLevels(),

        -- Queries
        queries = self.queries,
        queryCount = #self.queries,
        totalQueryTime = self.totalQueryTime,
        queryStats = self:getQueryStats(),

        -- Middleware
        middlewares = self.middlewares,

        -- Memory
        memory = {
            start = self.memoryStart,
            ["end"] = self.memoryEnd or collectgarbage("count"),
            peak = self.memoryPeak,
            delta = (self.memoryEnd or collectgarbage("count")) - self.memoryStart,
        },

        -- Timeline
        timeline = self.timeline,

        -- Custom
        custom = self.custom,

        -- Meta
        luaVersion = _VERSION,
        timestamp = os.time(),
    }
end

--------------------------------------------------------------------------------
-- Utility Methods
--------------------------------------------------------------------------------

function Collector:_copyTable(tbl)
    if type(tbl) ~= "table" then return {} end
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = self:_copyTable(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function Collector:_countLogLevels()
    local counts = { debug = 0, info = 0, warning = 0, error = 0 }
    for _, log in ipairs(self.logs) do
        if counts[log.level] then
            counts[log.level] = counts[log.level] + 1
        end
    end
    return counts
end

function Collector:_getStatusText(code)
    local statusTexts = {
        [200] = "OK",
        [201] = "Created",
        [204] = "No Content",
        [301] = "Moved Permanently",
        [302] = "Found",
        [304] = "Not Modified",
        [400] = "Bad Request",
        [401] = "Unauthorized",
        [403] = "Forbidden",
        [404] = "Not Found",
        [405] = "Method Not Allowed",
        [422] = "Unprocessable Entity",
        [429] = "Too Many Requests",
        [500] = "Internal Server Error",
        [502] = "Bad Gateway",
        [503] = "Service Unavailable",
    }
    return statusTexts[code] or "Unknown"
end

return collector
