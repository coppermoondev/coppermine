-- Ember - Freight ORM Integration
-- Logs database queries through Ember with timing and slow query detection

local freight_integration = {}

--- Get current time in milliseconds
local function get_time_ms()
    if time and time.monotonic_ms then
        return time.monotonic_ms()
    end
    return os.clock() * 1000
end

--- Detect query type from SQL
---@param sql string
---@return string
local function detectQueryType(sql)
    local trimmed = sql:match("^%s*(%S+)") or ""
    local upper = trimmed:upper()
    if upper == "SELECT" then return "SELECT"
    elseif upper == "INSERT" then return "INSERT"
    elseif upper == "UPDATE" then return "UPDATE"
    elseif upper == "DELETE" then return "DELETE"
    elseif upper == "CREATE" then return "CREATE"
    elseif upper == "DROP" then return "DROP"
    elseif upper == "ALTER" then return "ALTER"
    else return "EXECUTE"
    end
end

--- Wrap a Freight database instance for query logging
---@param db table     Freight database instance
---@param logger table Ember logger
---@param options table|nil
---@return table db
function freight_integration.setup(db, logger, options)
    options = options or {}
    local queryLevel = options.level or "debug"
    local slowThreshold = options.slowThreshold or 100
    local includeParams = options.includeParams ~= false

    -- Store originals
    local original_query = db.query
    local original_query_row = db.query_row
    local original_execute = db.execute

    -- Wrap query (SELECT returning multiple rows)
    db.query = function(db_self, sql, ...)
        local params = { ... }
        local start = get_time_ms()
        local results = original_query(db_self, sql, ...)
        local duration = get_time_ms() - start

        local context = {
            sql = sql,
            duration = math.floor(duration * 100) / 100,
            rows = results and #results or 0,
            queryType = detectQueryType(sql),
        }
        if includeParams and #params > 0 then
            context.params = params
        end

        local level = (duration >= slowThreshold) and "warn" or queryLevel
        logger:log(level, "query", context)

        return results
    end

    -- Wrap query_row (SELECT returning single row)
    db.query_row = function(db_self, sql, ...)
        local params = { ... }
        local start = get_time_ms()
        local result = original_query_row(db_self, sql, ...)
        local duration = get_time_ms() - start

        local context = {
            sql = sql,
            duration = math.floor(duration * 100) / 100,
            rows = result and 1 or 0,
            queryType = detectQueryType(sql),
        }
        if includeParams and #params > 0 then
            context.params = params
        end

        local level = (duration >= slowThreshold) and "warn" or queryLevel
        logger:log(level, "query", context)

        return result
    end

    -- Wrap execute (INSERT, UPDATE, DELETE, etc.)
    db.execute = function(db_self, sql, ...)
        local params = { ... }
        local start = get_time_ms()
        local result = original_execute(db_self, sql, ...)
        local duration = get_time_ms() - start

        local context = {
            sql = sql,
            duration = math.floor(duration * 100) / 100,
            affected = result or 0,
            queryType = detectQueryType(sql),
        }
        if includeParams and #params > 0 then
            context.params = params
        end

        local level = (duration >= slowThreshold) and "warn" or queryLevel
        logger:log(level, "query", context)

        return result
    end

    -- Store originals for unwrap
    db._ember_originals = {
        query = original_query,
        query_row = original_query_row,
        execute = original_execute,
    }

    return db
end

--- Restore original database methods
---@param db table
function freight_integration.unwrap(db)
    if db._ember_originals then
        db.query = db._ember_originals.query
        db.query_row = db._ember_originals.query_row
        db.execute = db._ember_originals.execute
        db._ember_originals = nil
    end
end

return freight_integration
