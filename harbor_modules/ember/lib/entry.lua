-- Ember - Log Entry
-- Creates the canonical log entry table that flows through the system

local entry = {}

--- Create a new log entry
---@param level string       Level name ("info", "warn", etc.)
---@param levelNumber number Numeric level (30, 40, etc.)
---@param message string     Log message
---@param context table      Merged context
---@param name string|nil    Logger name
---@return table LogEntry
function entry.create(level, levelNumber, message, context, name)
    return {
        level = level,
        levelNumber = levelNumber,
        message = message,
        timestamp = os.time(),
        context = context or {},
        name = name,
    }
end

return entry
