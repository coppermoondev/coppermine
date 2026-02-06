-- Ember - Formatter Interface
-- Defines the formatter contract and provides a factory for custom formatters

local formatter = {}

--- Create a formatter from a function or table definition
---@param fn_or_table function|table
---@return table Formatter
function formatter.create(fn_or_table)
    if type(fn_or_table) == "function" then
        return {
            name = "custom",
            format = fn_or_table,
        }
    end

    if type(fn_or_table) == "table" then
        assert(fn_or_table.format, "Formatter must have a 'format' function")
        return {
            name = fn_or_table.name or "custom",
            format = fn_or_table.format,
        }
    end

    error("Formatter must be a function or table, got " .. type(fn_or_table))
end

return formatter
