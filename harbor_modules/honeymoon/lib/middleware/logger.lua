-- HoneyMoon Logger Middleware
-- Request logging with customizable format

local logger = {}

--- Color codes for terminal output
local colors = {
    reset = "\27[0m",
    dim = "\27[2m",
    red = "\27[31m",
    green = "\27[32m",
    yellow = "\27[33m",
    blue = "\27[34m",
    magenta = "\27[35m",
    cyan = "\27[36m",
    white = "\27[37m",
}

--- Get color for HTTP method
local function method_color(method)
    local method_colors = {
        GET = colors.green,
        POST = colors.blue,
        PUT = colors.yellow,
        DELETE = colors.red,
        PATCH = colors.magenta,
        OPTIONS = colors.cyan,
        HEAD = colors.dim,
    }
    return method_colors[method] or colors.white
end

--- Get color for status code
local function status_color(status)
    if status >= 500 then
        return colors.red
    elseif status >= 400 then
        return colors.yellow
    elseif status >= 300 then
        return colors.cyan
    elseif status >= 200 then
        return colors.green
    else
        return colors.white
    end
end

--- Format bytes for display
local function format_bytes(bytes)
    if bytes < 1024 then
        return string.format("%dB", bytes)
    elseif bytes < 1024 * 1024 then
        return string.format("%.1fKB", bytes / 1024)
    else
        return string.format("%.1fMB", bytes / (1024 * 1024))
    end
end

--- Escape replacement string for gsub (% is special in replacement)
local function escape_replacement(str)
    if str then
        return str:gsub("%%", "%%%%")
    end
    return str
end

--- Create logger middleware
---@param options table|nil Logger options
---@return function Middleware function
function logger.create(options)
    options = options or {}

    local format_str = options.format or ":method :path :status :response-time ms"
    local use_colors = options.colors ~= false
    local skip = options.skip or function() return false end
    local immediate = options.immediate or false
    local stream = options.stream or print

    return function(req, res, next)
        -- Check if should skip
        if skip(req, res) then
            return next()
        end

        local start_time = time.monotonic_ms()
        local start_date = os.date("%Y-%m-%d %H:%M:%S")

        -- For immediate mode, log before processing
        if immediate then
            local log_line = format_str
                :gsub(":method", escape_replacement(req.method))
                :gsub(":path", escape_replacement(req.path))
                :gsub(":url", escape_replacement(req:originalUrl()))
                :gsub(":date", escape_replacement(start_date))
                :gsub(":ip", escape_replacement(req.ip or "-"))
                :gsub(":user%-agent", escape_replacement(req:get("user-agent") or "-"))
            stream(log_line)
            return next()
        end

        -- Wrap response.send to capture timing
        local original_send = res.send

        res.send = function(self, body)
            local duration = time.monotonic_ms() - start_time
            local body_len = body and #body or 0
            local status = self._status

            -- Build log line
            local method_str = req.method
            local status_str = tostring(status)
            local duration_str = string.format("%.2f", duration)
            local size_str = format_bytes(body_len)

            if use_colors then
                method_str = method_color(req.method) .. method_str .. colors.reset
                status_str = status_color(status) .. status_str .. colors.reset
                duration_str = colors.dim .. duration_str .. colors.reset
            end

            local log_line = format_str
                :gsub(":method", escape_replacement(method_str))
                :gsub(":path", escape_replacement(req.path))
                :gsub(":url", escape_replacement(req:originalUrl()))
                :gsub(":status", escape_replacement(status_str))
                :gsub(":response%-time", escape_replacement(duration_str))
                :gsub(":res%[content%-length%]", escape_replacement(size_str))
                :gsub(":content%-length", escape_replacement(size_str))
                :gsub(":date", escape_replacement(start_date))
                :gsub(":ip", escape_replacement(req.ip or "-"))
                :gsub(":remote%-addr", escape_replacement(req.ip or "-"))
                :gsub(":user%-agent", escape_replacement(req:get("user-agent") or "-"))
                :gsub(":referrer", escape_replacement(req:get("referer") or "-"))
                :gsub(":http%-version", "1.1")

            stream(log_line)

            return original_send(self, body)
        end

        next()
    end
end

--- Predefined formats
logger.formats = {
    -- Common Log Format
    combined = ':remote-addr - - [:date] ":method :url HTTP/:http-version" :status :content-length ":referrer" ":user-agent"',

    -- Common format without referrer/user-agent
    common = ':remote-addr - - [:date] ":method :url HTTP/:http-version" :status :content-length',

    -- Development format (default)
    dev = ":method :path :status :response-time ms - :content-length",

    -- Short format
    short = ":remote-addr :method :url :status :response-time ms - :content-length",

    -- Tiny format
    tiny = ":method :url :status :response-time ms",
}

--- Create logger with predefined format
---@param format_name string Format name
---@param options table|nil Additional options
---@return function
function logger.format(format_name, options)
    options = options or {}
    options.format = logger.formats[format_name] or logger.formats.dev
    return logger.create(options)
end

return logger
