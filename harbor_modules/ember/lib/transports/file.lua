-- Ember - File Transport
-- Appends log lines to a file with optional size-based rotation

local transport_mod = require("ember.lib.transport")

local function fileTransport(options)
    options = options or {}
    assert(options.path, "File transport requires a 'path' option")

    local filePath = options.path
    local maxSize = options.maxSize
    local maxFiles = options.maxFiles or 5
    local shouldMkdir = options.mkdir ~= false
    local bytesWritten = 0

    -- Default formatter: plain text (no colors)
    local fmt = options.formatter
    if not fmt then
        local text = require("ember.lib.formatters.text")
        fmt = text({ timestamp = true })
    end

    -- Ensure parent directory exists
    if shouldMkdir then
        local dir = path.dirname(filePath)
        if dir and dir ~= "" and dir ~= "." then
            pcall(fs.mkdir_all, dir)
        end
    end

    -- Check existing file size
    if fs.exists(filePath) then
        local ok, stat = pcall(fs.stat, filePath)
        if ok and stat and stat.size then
            bytesWritten = stat.size
        end
    end

    -- Rotate log files: app.log -> app.log.1, app.log.1 -> app.log.2, etc.
    local function rotate()
        for i = maxFiles - 1, 1, -1 do
            local src = filePath .. "." .. i
            local dst = filePath .. "." .. (i + 1)
            if fs.exists(src) then
                pcall(fs.rename, src, dst)
            end
        end
        if fs.exists(filePath) then
            pcall(fs.rename, filePath, filePath .. ".1")
        end
        bytesWritten = 0
    end

    return transport_mod.create({
        name = "file",
        level = options.level,
        formatter = fmt,
        write = function(entry, formatted)
            local line = formatted .. "\n"

            -- Check rotation before write
            if maxSize and bytesWritten + #line > maxSize then
                rotate()
            end

            fs.append(filePath, line)
            bytesWritten = bytesWritten + #line
        end,
    })
end

return fileTransport
