-- Ember - Log Level Definitions
-- Single source of truth for level names, numeric values, and ordering

local levels = {}

--------------------------------------------------------------------------------
-- Level Values
--------------------------------------------------------------------------------

levels.values = {
    trace = 10,
    debug = 20,
    info  = 30,
    warn  = 40,
    error = 50,
    fatal = 60,
}

levels.names = {
    [10] = "trace",
    [20] = "debug",
    [30] = "info",
    [40] = "warn",
    [50] = "error",
    [60] = "fatal",
}

levels.ordered = { "trace", "debug", "info", "warn", "error", "fatal" }

--------------------------------------------------------------------------------
-- Resolve
--------------------------------------------------------------------------------

--- Resolve a level string or number to its numeric value
---@param level string|number|nil
---@return number
function levels.resolve(level)
    if level == nil then
        return 30 -- default: info
    end

    if type(level) == "number" then
        return level
    end

    if type(level) == "string" then
        local lower = level:lower()
        local val = levels.values[lower]
        if val then
            return val
        end
        -- Alias: "warning" -> warn
        if lower == "warning" then
            return levels.values.warn
        end
    end

    return 30 -- fallback: info
end

--- Resolve a numeric level to its name
---@param levelNum number
---@return string
function levels.toName(levelNum)
    return levels.names[levelNum] or "unknown"
end

--- Check if a message level passes the threshold
---@param msgLevel number
---@param minLevel number
---@return boolean
function levels.shouldLog(msgLevel, minLevel)
    return msgLevel >= minLevel
end

--- Check if a level value is valid
---@param level string|number
---@return boolean
function levels.isValid(level)
    if type(level) == "number" then
        return levels.names[level] ~= nil
    end
    if type(level) == "string" then
        return levels.values[level:lower()] ~= nil
    end
    return false
end

return levels
