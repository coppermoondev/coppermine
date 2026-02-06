-- Lantern Freight Integration
-- Automatic query logging for Freight ORM
--
-- @module lantern.lib.freight

local freight_integration = {}

--------------------------------------------------------------------------------
-- Query Logger
--------------------------------------------------------------------------------

---@class FreightLogger
---@field db table Original database instance
---@field _original_query function Original query method
---@field _original_query_row function Original query_row method
---@field _original_execute function Original execute method
---@field _listeners table Query listeners
local FreightLogger = {}
FreightLogger.__index = FreightLogger

--- Create a new Freight logger
---@param db table Freight database instance
---@param options table? Logger options
---@return FreightLogger
function FreightLogger.new(db, options)
    local self = setmetatable({}, FreightLogger)

    self.db = db
    self._listeners = {}
    self._enabled = true

    -- Options for result capture
    options = options or {}
    self._captureResults = options.captureResults ~= false  -- Default true
    self._maxResultRows = options.maxResultRows or 50       -- Limit rows to prevent memory issues
    self._maxColumnWidth = options.maxColumnWidth or 200    -- Truncate long values

    -- Store original methods
    self._original_query = db.query
    self._original_query_row = db.query_row
    self._original_execute = db.execute

    return self
end

--- Prepare results for storage (limit size, truncate values)
---@param results table Query results
---@return table Prepared results with metadata
function FreightLogger:_prepareResults(results)
    if not self._captureResults or not results then
        return nil
    end

    local prepared = {
        columns = {},
        rows = {},
        totalRows = 0,
        truncated = false,
    }

    -- Handle single row (from query_row)
    if results and type(results) == "table" and not results[1] then
        -- Single row result - wrap it
        results = { results }
    end

    if type(results) ~= "table" then
        return nil
    end

    prepared.totalRows = #results

    -- Extract columns from first row
    if results[1] and type(results[1]) == "table" then
        for key, _ in pairs(results[1]) do
            table.insert(prepared.columns, key)
        end
        table.sort(prepared.columns)  -- Consistent column order
    end

    -- Limit rows
    local maxRows = math.min(#results, self._maxResultRows)
    if #results > self._maxResultRows then
        prepared.truncated = true
    end

    -- Process rows
    for i = 1, maxRows do
        local row = results[i]
        local preparedRow = {}

        for _, col in ipairs(prepared.columns) do
            local value = row[col]

            -- Truncate long string values
            if type(value) == "string" and #value > self._maxColumnWidth then
                value = value:sub(1, self._maxColumnWidth) .. "..."
            elseif type(value) == "table" then
                -- Convert tables to JSON representation
                local ok, jsonStr = pcall(json.encode, value)
                value = ok and jsonStr or "[table]"
                if #value > self._maxColumnWidth then
                    value = value:sub(1, self._maxColumnWidth) .. "..."
                end
            end

            preparedRow[col] = value
        end

        table.insert(prepared.rows, preparedRow)
    end

    return prepared
end

--- Add a query listener
---@param listener function(query_info)
function FreightLogger:addListener(listener)
    table.insert(self._listeners, listener)
end

--- Remove a query listener
---@param listener function
function FreightLogger:removeListener(listener)
    for i, l in ipairs(self._listeners) do
        if l == listener then
            table.remove(self._listeners, i)
            return
        end
    end
end

--- Notify all listeners
---@param query_info table
function FreightLogger:_notify(query_info)
    if not self._enabled then return end

    for _, listener in ipairs(self._listeners) do
        local ok, err = pcall(listener, query_info)
        if not ok then
            print("[Lantern/Freight] Listener error: " .. tostring(err))
        end
    end
end

--- Enable/disable logging
---@param enabled boolean
function FreightLogger:setEnabled(enabled)
    self._enabled = enabled
end

--- Get high-resolution time in milliseconds
---@return number
local function get_time_ms()
    -- Use os.clock() for CPU time, multiply by 1000 for ms
    -- Note: In CopperMoon, time.now() might be available for better precision
    if time and time.now then
        return time.now() * 1000
    end
    return os.clock() * 1000
end

--- Wrap the database methods to intercept queries
function FreightLogger:wrap()
    local self_ref = self
    local db = self.db

    -- Wrap query (SELECT returning multiple rows)
    db.query = function(db_self, sql, ...)
        local params = {...}
        local start_time = get_time_ms()

        -- Execute original
        local results = self_ref._original_query(db_self, sql, ...)

        local duration = get_time_ms() - start_time
        local row_count = results and #results or 0

        -- Prepare results for debugging
        local preparedResults = self_ref:_prepareResults(results)

        -- Notify listeners
        self_ref:_notify({
            type = "SELECT",
            sql = sql,
            params = params,
            duration = duration,
            rowCount = row_count,
            timestamp = os.time(),
            results = preparedResults
        })

        return results
    end

    -- Wrap query_row (SELECT returning single row)
    db.query_row = function(db_self, sql, ...)
        local params = {...}
        local start_time = get_time_ms()

        -- Execute original
        local result = self_ref._original_query_row(db_self, sql, ...)

        local duration = get_time_ms() - start_time

        -- Prepare results for debugging
        local preparedResults = self_ref:_prepareResults(result)

        -- Notify listeners
        self_ref:_notify({
            type = "SELECT",
            sql = sql,
            params = params,
            duration = duration,
            rowCount = result and 1 or 0,
            timestamp = os.time(),
            results = preparedResults
        })

        return result
    end

    -- Wrap execute (INSERT/UPDATE/DELETE)
    db.execute = function(db_self, sql, ...)
        local params = {...}
        local start_time = get_time_ms()

        -- Execute original
        local result = self_ref._original_execute(db_self, sql, ...)

        local duration = get_time_ms() - start_time

        -- Determine query type
        local query_type = "EXECUTE"
        local sql_upper = sql:upper():match("^%s*(%w+)")
        if sql_upper then
            if sql_upper == "INSERT" then
                query_type = "INSERT"
            elseif sql_upper == "UPDATE" then
                query_type = "UPDATE"
            elseif sql_upper == "DELETE" then
                query_type = "DELETE"
            elseif sql_upper == "CREATE" then
                query_type = "CREATE"
            elseif sql_upper == "DROP" then
                query_type = "DROP"
            elseif sql_upper == "ALTER" then
                query_type = "ALTER"
            end
        end

        -- Get affected rows if available
        local affected_rows = nil
        if db_self.changes then
            local ok, changes = pcall(db_self.changes, db_self)
            if ok then
                affected_rows = changes
            end
        end

        -- Get last insert ID for INSERT queries
        local lastInsertId = nil
        if query_type == "INSERT" and db_self.last_insert_rowid then
            local ok, rowid = pcall(db_self.last_insert_rowid, db_self)
            if ok then
                lastInsertId = rowid
            end
        end

        -- Notify listeners
        self_ref:_notify({
            type = query_type,
            sql = sql,
            params = params,
            duration = duration,
            rowCount = affected_rows,
            timestamp = os.time(),
            lastInsertId = lastInsertId
        })

        return result
    end

    return self
end

--- Restore original database methods
function FreightLogger:unwrap()
    self.db.query = self._original_query
    self.db.query_row = self._original_query_row
    self.db.execute = self._original_execute
end

--------------------------------------------------------------------------------
-- Request-scoped Integration
--------------------------------------------------------------------------------

--- Create a Lantern listener that records queries to a collector
---@param collector table Lantern collector instance
---@return function Listener function
function freight_integration.createListener(collector)
    return function(query_info)
        if collector and collector.recordQuery then
            collector:recordQuery(
                query_info.sql,
                query_info.params,
                query_info.duration,
                query_info.rowCount,
                query_info.type,
                query_info.results,
                query_info.lastInsertId
            )
        end
    end
end

--------------------------------------------------------------------------------
-- Global Integration
--------------------------------------------------------------------------------

-- Global logger instance (for app-wide tracking)
local _global_logger = nil
local _global_stats = {
    totalQueries = 0,
    totalDuration = 0,
    queryTypes = {}
}

--- Setup Freight integration with a database
---@param db table Freight database instance
---@param options table? Options (captureResults, maxResultRows, maxColumnWidth)
---@return FreightLogger
function freight_integration.setup(db, options)
    options = options or {}

    local logger = FreightLogger.new(db, options)

    -- Add global stats listener
    logger:addListener(function(query_info)
        _global_stats.totalQueries = _global_stats.totalQueries + 1
        _global_stats.totalDuration = _global_stats.totalDuration + (query_info.duration or 0)

        local qtype = query_info.type or "UNKNOWN"
        _global_stats.queryTypes[qtype] = (_global_stats.queryTypes[qtype] or 0) + 1
    end)

    -- Wrap the database
    logger:wrap()

    -- Store as global
    _global_logger = logger

    -- Attach logger to database for easy access
    db._lantern_logger = logger

    return logger
end

--- Get the global logger
---@return FreightLogger?
function freight_integration.getLogger()
    return _global_logger
end

--- Get global stats
---@return table
function freight_integration.getStats()
    return _global_stats
end

--- Reset global stats
function freight_integration.resetStats()
    _global_stats.totalQueries = 0
    _global_stats.totalDuration = 0
    _global_stats.queryTypes = {}
end

--------------------------------------------------------------------------------
-- Middleware Integration
--------------------------------------------------------------------------------

--- Create middleware that connects Freight logging to Lantern collector
---@param db table Freight database instance
---@return function Middleware
function freight_integration.middleware(db)
    local logger = db._lantern_logger

    if not logger then
        -- Auto-setup if not already done
        logger = freight_integration.setup(db)
    end

    return function(req, res, next)
        -- Only attach listener if we have a lantern collector
        if req.lantern then
            local listener = freight_integration.createListener(req.lantern)
            logger:addListener(listener)

            -- Store original send
            local originalSend = res.send

            -- Cleanup listener when response is sent
            res.send = function(self, body)
                logger:removeListener(listener)
                return originalSend(self, body)
            end
        end

        next()
    end
end

--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

freight_integration.FreightLogger = FreightLogger

return freight_integration
