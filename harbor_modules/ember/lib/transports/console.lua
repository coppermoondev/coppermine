-- Ember - Console Transport
-- Outputs formatted log lines to stdout via print()

local transport_mod = require("ember.lib.transport")

local function consoleTransport(options)
    options = options or {}
    local useColors = options.colors ~= false
    local stream = options.stream or print

    -- Choose default formatter based on color preference
    local fmt = options.formatter
    if not fmt then
        if useColors then
            local pretty = require("ember.lib.formatters.pretty")
            fmt = pretty({ colors = true })
        else
            local text = require("ember.lib.formatters.text")
            fmt = text()
        end
    end

    return transport_mod.create({
        name = "console",
        level = options.level,
        formatter = fmt,
        write = function(entry, formatted)
            stream(formatted)
        end,
    })
end

return consoleTransport
