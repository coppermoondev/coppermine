-- Ember - Text Formatter
-- Produces plain-text log lines: [2024-01-15T10:30:45] INFO  my-app: Hello world {key=val}

local formatter_mod = require("ember.lib.formatter")

local function textFormatter(options)
    options = options or {}
    local showTimestamp = options.timestamp ~= false
    local showName = options.showName ~= false
    local showContext = options.showContext ~= false
    local timestampFmt = options.timestampFormat or "!%Y-%m-%dT%H:%M:%SZ"

    return formatter_mod.create({
        name = "text",
        format = function(entry)
            local parts = {}

            -- Timestamp
            if showTimestamp then
                local ts = os.date(timestampFmt, entry.timestamp)
                parts[#parts + 1] = "[" .. ts .. "]"
            end

            -- Level (uppercased, padded to 5 chars)
            parts[#parts + 1] = string.format("%-5s", entry.level:upper())

            -- Name
            if showName and entry.name then
                parts[#parts + 1] = entry.name .. ":"
            end

            -- Message
            parts[#parts + 1] = entry.message

            -- Context
            if showContext and entry.context and next(entry.context) then
                local ctxParts = {}
                for k, v in pairs(entry.context) do
                    ctxParts[#ctxParts + 1] = k .. "=" .. tostring(v)
                end
                table.sort(ctxParts)
                parts[#parts + 1] = "{" .. table.concat(ctxParts, ", ") .. "}"
            end

            return table.concat(parts, " ")
        end,
    })
end

return textFormatter
