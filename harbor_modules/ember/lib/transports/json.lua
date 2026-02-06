-- Ember - JSON Transport
-- Outputs structured JSON to stdout for log aggregators

local transport_mod = require("ember.lib.transport")

local function jsonTransport(options)
    options = options or {}
    local stream = options.stream or print

    -- JSON transport always uses the JSON formatter
    local jsonFmt = require("ember.lib.formatters.json")
    local fmt = options.formatter or jsonFmt({
        messageKey = options.messageKey,
        timestampKey = options.timestampKey,
        levelKey = options.levelKey,
    })

    return transport_mod.create({
        name = "json",
        level = options.level,
        formatter = fmt,
        write = function(entry, formatted)
            stream(formatted)
        end,
    })
end

return jsonTransport
