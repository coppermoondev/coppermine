-- Ember - Logger Class
-- Core logger with level filtering, transport fanout, child loggers, context merging

local levels = require("ember.lib.levels")
local entry_mod = require("ember.lib.entry")

local Logger = {}
Logger.__index = Logger

--------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------

--- Create a new Logger instance
---@param options table|nil
---@return Logger
function Logger.new(options)
    options = options or {}

    local self = setmetatable({}, Logger)
    self._level = levels.resolve(options.level or "info")
    self._name = options.name or nil
    self._context = options.context or {}
    self._transports = options.transports or {}
    self._formatter = options.formatter or nil
    self._parent = nil

    return self
end

--------------------------------------------------------------------------------
-- Core Dispatch
--------------------------------------------------------------------------------

--- Log a message at a given level
---@param level string|number  Level name or number
---@param message string       Log message
---@param context table|nil    Additional context for this call
function Logger:log(level, message, context)
    local levelNum = levels.resolve(level)
    local levelName = levels.toName(levelNum)
    if levelName == "unknown" then
        levelName = type(level) == "string" and level:lower() or "unknown"
    end

    -- Fast path: check logger-level gate
    if levelNum < self._level then
        return
    end

    -- Merge context: self._context + call-site context
    local mergedContext
    if context and next(context) then
        mergedContext = {}
        for k, v in pairs(self._context) do
            mergedContext[k] = v
        end
        for k, v in pairs(context) do
            mergedContext[k] = v
        end
    else
        mergedContext = self._context
    end

    -- Create entry
    local e = entry_mod.create(levelName, levelNum, message, mergedContext, self._name)

    -- Fan out to transports
    for i = 1, #self._transports do
        local t = self._transports[i]

        -- Transport-level filtering
        local tLevel = t.levelNumber or self._level
        if levelNum >= tLevel then
            -- Format: transport formatter > logger default > minimal fallback
            local fmt = t.formatter or self._formatter
            local formatted
            if fmt then
                formatted = fmt.format(e)
            else
                formatted = string.format("[%s] %s", e.level:upper(), e.message)
            end

            -- Write (pcall to prevent one transport from killing others)
            local ok, err = pcall(t.write, e, formatted)
            if not ok then
                print(string.format("[ember] Transport '%s' error: %s", t.name, tostring(err)))
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Convenience Methods
--------------------------------------------------------------------------------

function Logger:trace(message, context)
    self:log("trace", message, context)
end

function Logger:debug(message, context)
    self:log("debug", message, context)
end

function Logger:info(message, context)
    self:log("info", message, context)
end

function Logger:warn(message, context)
    self:log("warn", message, context)
end

function Logger:error(message, context)
    self:log("error", message, context)
end

function Logger:fatal(message, context)
    self:log("fatal", message, context)
end

--------------------------------------------------------------------------------
-- Child Loggers
--------------------------------------------------------------------------------

--- Create a child logger with additional context
--- Child shares transports by reference (Pino pattern)
---@param context table  Context to merge with parent
---@return Logger
function Logger:child(context)
    local child = setmetatable({}, Logger)

    -- Merge parent context with child context
    local mergedContext = {}
    for k, v in pairs(self._context) do
        mergedContext[k] = v
    end
    if context then
        for k, v in pairs(context) do
            mergedContext[k] = v
        end
    end

    child._level = self._level
    child._name = self._name
    child._context = mergedContext
    child._transports = self._transports  -- shared reference
    child._formatter = self._formatter
    child._parent = self

    return child
end

--------------------------------------------------------------------------------
-- Level Management
--------------------------------------------------------------------------------

--- Set the minimum log level
---@param level string|number
function Logger:setLevel(level)
    self._level = levels.resolve(level)
end

--- Get the current level name
---@return string
function Logger:getLevel()
    return levels.toName(self._level)
end

--- Check if a level would produce output
---@param level string|number
---@return boolean
function Logger:isLevelEnabled(level)
    return levels.resolve(level) >= self._level
end

--------------------------------------------------------------------------------
-- Transport Management
--------------------------------------------------------------------------------

--- Add a transport
---@param t table Transport
function Logger:addTransport(t)
    self._transports[#self._transports + 1] = t
end

--- Remove a transport by name
---@param name string
---@return boolean removed
function Logger:removeTransport(name)
    for i = #self._transports, 1, -1 do
        if self._transports[i].name == name then
            table.remove(self._transports, i)
            return true
        end
    end
    return false
end

--- Get all transports
---@return table[]
function Logger:getTransports()
    return self._transports
end

--- Close all transports
function Logger:close()
    for _, t in ipairs(self._transports) do
        if t.close then
            pcall(t.close)
        end
    end
end

return Logger
