-- Ember - Pretty Formatter
-- Colored human-readable output for development

local formatter_mod = require("ember.lib.formatter")

--------------------------------------------------------------------------------
-- ANSI Colors
--------------------------------------------------------------------------------

local C = {
    reset   = "\27[0m",
    dim     = "\27[2m",
    bold    = "\27[1m",
    red     = "\27[31m",
    green   = "\27[32m",
    yellow  = "\27[33m",
    blue    = "\27[34m",
    magenta = "\27[35m",
    cyan    = "\27[36m",
    white   = "\27[37m",
    gray    = "\27[90m",
    brightRed    = "\27[91m",
    brightYellow = "\27[93m",
}

local LEVEL_COLORS = {
    trace = C.gray,
    debug = C.cyan,
    info  = C.green,
    warn  = C.yellow,
    error = C.red,
    fatal = C.brightRed .. C.bold,
}

local LEVEL_LABELS = {
    trace = "TRC",
    debug = "DBG",
    info  = "INF",
    warn  = "WRN",
    error = "ERR",
    fatal = "FTL",
}

--------------------------------------------------------------------------------
-- Formatter
--------------------------------------------------------------------------------

local function prettyFormatter(options)
    options = options or {}
    local useColors = options.colors ~= false
    local showTimestamp = options.timestamp ~= false
    local timestampFmt = options.timestampFormat or "%H:%M:%S"

    return formatter_mod.create({
        name = "pretty",
        format = function(entry)
            local parts = {}

            -- Timestamp (dimmed)
            if showTimestamp then
                local ts = os.date(timestampFmt, entry.timestamp)
                if useColors then
                    parts[#parts + 1] = C.dim .. ts .. C.reset
                else
                    parts[#parts + 1] = ts
                end
            end

            -- Level badge
            local label = LEVEL_LABELS[entry.level] or entry.level:upper():sub(1, 3)
            if useColors then
                local color = LEVEL_COLORS[entry.level] or C.white
                parts[#parts + 1] = color .. label .. C.reset
            else
                parts[#parts + 1] = label
            end

            -- Name (magenta)
            if entry.name then
                if useColors then
                    parts[#parts + 1] = C.magenta .. entry.name .. C.reset
                else
                    parts[#parts + 1] = entry.name
                end
            end

            -- Separator
            if useColors then
                parts[#parts + 1] = C.dim .. "›" .. C.reset
            else
                parts[#parts + 1] = "-"
            end

            -- Message
            parts[#parts + 1] = entry.message

            -- Context (dimmed key=value)
            if entry.context and next(entry.context) then
                local ctxParts = {}
                for k, v in pairs(entry.context) do
                    if useColors then
                        ctxParts[#ctxParts + 1] = C.dim .. k .. "=" .. C.reset .. tostring(v)
                    else
                        ctxParts[#ctxParts + 1] = k .. "=" .. tostring(v)
                    end
                end
                table.sort(ctxParts)
                parts[#parts + 1] = " " .. table.concat(ctxParts, " ")
            end

            return table.concat(parts, " ")
        end,
    })
end

return prettyFormatter
