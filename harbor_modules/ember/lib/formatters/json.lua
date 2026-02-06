-- Ember - JSON Formatter
-- Produces structured JSON: {"level":"info","msg":"Hello","time":1705312245}

local formatter_mod = require("ember.lib.formatter")

local function jsonFormatter(options)
    options = options or {}
    local messageKey = options.messageKey or "msg"
    local timestampKey = options.timestampKey or "time"
    local levelKey = options.levelKey or "level"

    return formatter_mod.create({
        name = "json",
        format = function(entry)
            local output = {}
            output[levelKey] = entry.level
            output[messageKey] = entry.message
            output[timestampKey] = entry.timestamp

            if entry.name then
                output.name = entry.name
            end

            -- Flatten context into top-level keys (Pino-style)
            if entry.context then
                for k, v in pairs(entry.context) do
                    -- Don't override reserved keys
                    if k ~= levelKey and k ~= messageKey and k ~= timestampKey
                       and k ~= "name" and k ~= "levelNumber" then
                        output[k] = v
                    end
                end
            end

            return json.encode(output)
        end,
    })
end

return jsonFormatter
