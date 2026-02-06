-- Ember - Lantern Integration
-- Bridge between Ember loggers and Lantern's per-request collector

local transport_mod = require("ember.lib.transport")

local lantern_integration = {}

--- Create a per-request transport that feeds into a Lantern collector
---@param collector table  Lantern collector (req.lantern)
---@return table Transport
function lantern_integration.createTransport(collector)
    return transport_mod.create({
        name = "lantern",
        write = function(entry, formatted)
            if collector and collector.log then
                -- Map Ember levels to Lantern levels
                local lanternLevel = entry.level
                if lanternLevel == "trace" then lanternLevel = "debug" end
                if lanternLevel == "fatal" then lanternLevel = "error" end
                if lanternLevel == "warn" then lanternLevel = "warning" end

                collector:log(lanternLevel, entry.message, entry.context)
            end
        end,
    })
end

--- Create middleware that bridges req.log (Ember) and req.lantern (Lantern)
--- Must be added AFTER both ember.honeymoon() and lantern.setup()
---@param options table|nil
---@return function middleware
function lantern_integration.middleware(options)
    options = options or {}

    return function(req, res, next)
        -- Only activate if both req.log (Ember) and req.lantern (Lantern) exist
        if req.log and req.lantern then
            local lt = lantern_integration.createTransport(req.lantern)
            req.log:addTransport(lt)
        end

        next()
    end
end

return lantern_integration
