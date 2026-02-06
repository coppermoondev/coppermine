-- Ember - Transport Interface
-- Defines the transport contract and provides a factory for custom transports

local levels = require("ember.lib.levels")

local transport = {}

--- Create a transport from a table definition
---@param definition table
---@return table Transport
function transport.create(definition)
    assert(definition.name, "Transport must have a 'name'")
    assert(definition.write, "Transport must have a 'write' function")

    return {
        name = definition.name,
        level = definition.level,
        levelNumber = definition.level and levels.resolve(definition.level) or nil,
        formatter = definition.formatter or nil,
        write = definition.write,
        close = definition.close or nil,
    }
end

return transport
