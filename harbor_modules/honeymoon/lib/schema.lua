-- HoneyMoon Schema Module
-- Request validation and data sanitization

local utils = require("honeymoon.lib.utils")
local errors = require("honeymoon.lib.errors")

local schema = {}

--------------------------------------------------------------------------------
-- Schema Class
--------------------------------------------------------------------------------

---@class Schema
---@field _fields table
local Schema = {}
Schema.__index = Schema

--- Create a new schema
---@param definition table
---@return Schema
function schema.new(definition)
    local self = setmetatable({}, Schema)
    self._fields = definition or {}
    return self
end

--- Type validators
local type_validators = {
    string = function(value)
        return type(value) == "string", "must be a string"
    end,

    number = function(value)
        local num = tonumber(value)
        if num == nil then
            return false, "must be a number"
        end
        return true, nil, num
    end,

    integer = function(value)
        local num = tonumber(value)
        if num == nil or num ~= math.floor(num) then
            return false, "must be an integer"
        end
        return true, nil, math.floor(num)
    end,

    boolean = function(value)
        if type(value) == "boolean" then
            return true, nil, value
        end
        if value == "true" or value == "1" or value == 1 then
            return true, nil, true
        end
        if value == "false" or value == "0" or value == 0 then
            return true, nil, false
        end
        return false, "must be a boolean"
    end,

    email = function(value)
        if type(value) ~= "string" then
            return false, "must be a string"
        end
        if not utils.is_email(value) then
            return false, "must be a valid email address"
        end
        return true
    end,

    url = function(value)
        if type(value) ~= "string" then
            return false, "must be a string"
        end
        if not utils.is_url(value) then
            return false, "must be a valid URL"
        end
        return true
    end,

    uuid = function(value)
        if type(value) ~= "string" then
            return false, "must be a string"
        end
        if not utils.is_uuid(value) then
            return false, "must be a valid UUID"
        end
        return true
    end,

    array = function(value)
        if type(value) ~= "table" then
            return false, "must be an array"
        end
        -- Check if it's actually an array (sequential integer keys)
        local count = 0
        for _ in pairs(value) do
            count = count + 1
        end
        if count ~= #value then
            return false, "must be an array"
        end
        return true
    end,

    object = function(value)
        if type(value) ~= "table" then
            return false, "must be an object"
        end
        return true
    end,

    any = function(value)
        return true
    end
}

--- Validate a single field
---@param value any
---@param rules table
---@return boolean, string|nil, any
local function validate_field(value, rules)
    local field_errors = {}
    local sanitized = value

    -- Required check
    if rules.required and (value == nil or value == "") then
        return false, {"is required"}, nil
    end

    -- If value is nil/empty and not required, apply default or skip
    if value == nil or value == "" then
        if rules.default ~= nil then
            return true, nil, rules.default
        end
        return true, nil, nil
    end

    -- Type validation
    if rules.type then
        local validator = type_validators[rules.type]
        if validator then
            local valid, err, converted = validator(value)
            if not valid then
                table.insert(field_errors, err)
            elseif converted ~= nil then
                sanitized = converted
            end
        end
    end

    -- String length validations
    if type(sanitized) == "string" then
        if rules.min and #sanitized < rules.min then
            table.insert(field_errors, "must be at least " .. rules.min .. " characters")
        end
        if rules.max and #sanitized > rules.max then
            table.insert(field_errors, "must be at most " .. rules.max .. " characters")
        end
        if rules.length and #sanitized ~= rules.length then
            table.insert(field_errors, "must be exactly " .. rules.length .. " characters")
        end
    end

    -- Number range validations
    if type(sanitized) == "number" then
        if rules.minValue and sanitized < rules.minValue then
            table.insert(field_errors, "must be at least " .. rules.minValue)
        end
        if rules.maxValue and sanitized > rules.maxValue then
            table.insert(field_errors, "must be at most " .. rules.maxValue)
        end
    end

    -- Array length validations
    if type(sanitized) == "table" and rules.type == "array" then
        if rules.minItems and #sanitized < rules.minItems then
            table.insert(field_errors, "must have at least " .. rules.minItems .. " items")
        end
        if rules.maxItems and #sanitized > rules.maxItems then
            table.insert(field_errors, "must have at most " .. rules.maxItems .. " items")
        end
    end

    -- Pattern validation
    if rules.pattern and type(sanitized) == "string" then
        if not sanitized:match(rules.pattern) then
            table.insert(field_errors, rules.patternMessage or "has invalid format")
        end
    end

    -- Enum validation
    if rules.enum then
        local found = false
        for _, allowed in ipairs(rules.enum) do
            if sanitized == allowed then
                found = true
                break
            end
        end
        if not found then
            table.insert(field_errors, "must be one of: " .. table.concat(rules.enum, ", "))
        end
    end

    -- Custom validation function
    if rules.validate and type(rules.validate) == "function" then
        local ok, msg = rules.validate(sanitized)
        if not ok then
            table.insert(field_errors, msg or "is invalid")
        end
    end

    -- Sanitization/transformation (only if no errors so far)
    if #field_errors == 0 then
        if type(sanitized) == "string" then
            if rules.trim then
                sanitized = utils.trim(sanitized)
            end
            if rules.lowercase then
                sanitized = sanitized:lower()
            end
            if rules.uppercase then
                sanitized = sanitized:upper()
            end
        end
        if rules.transform and type(rules.transform) == "function" then
            sanitized = rules.transform(sanitized)
        end
    end

    if #field_errors > 0 then
        return false, field_errors, nil
    end
    return true, nil, sanitized
end

--- Validate data against schema
---@param data table
---@return boolean, table|nil, table|nil
function Schema:validate(data)
    data = data or {}
    local all_errors = {}
    local sanitized = {}
    local has_errors = false

    for field, rules in pairs(self._fields) do
        local value = data[field]
        local valid, field_errors, clean_value = validate_field(value, rules)

        if not valid then
            all_errors[field] = field_errors
            has_errors = true
        elseif clean_value ~= nil then
            sanitized[field] = clean_value
        end
    end

    if has_errors then
        return false, nil, all_errors
    end
    return true, sanitized, nil
end

--- Create a partial schema (all fields optional)
---@return Schema
function Schema:partial()
    local partial_fields = {}
    for field, rules in pairs(self._fields) do
        partial_fields[field] = utils.merge(rules, { required = false })
    end
    return schema.new(partial_fields)
end

--- Extend schema with additional fields
---@param additional table
---@return Schema
function Schema:extend(additional)
    local extended = utils.deep_copy(self._fields)
    for field, rules in pairs(additional) do
        extended[field] = rules
    end
    return schema.new(extended)
end

--- Pick specific fields from schema
---@param fields table
---@return Schema
function Schema:pick(fields)
    local picked = {}
    for _, field in ipairs(fields) do
        if self._fields[field] then
            picked[field] = self._fields[field]
        end
    end
    return schema.new(picked)
end

--- Omit specific fields from schema
---@param fields table
---@return Schema
function Schema:omit(fields)
    local omit_set = {}
    for _, field in ipairs(fields) do
        omit_set[field] = true
    end

    local remaining = {}
    for field, rules in pairs(self._fields) do
        if not omit_set[field] then
            remaining[field] = rules
        end
    end
    return schema.new(remaining)
end

--------------------------------------------------------------------------------
-- Common Schema Presets
--------------------------------------------------------------------------------

schema.presets = {
    --- Email field preset
    email = {
        type = "email",
        lowercase = true,
        trim = true
    },

    --- Password field preset
    password = {
        type = "string",
        required = true,
        min = 8,
        max = 128
    },

    --- Username field preset
    username = {
        type = "string",
        required = true,
        min = 3,
        max = 32,
        pattern = "^[%w_%-]+$",
        patternMessage = "must only contain letters, numbers, underscores, and hyphens",
        trim = true,
        lowercase = true
    },

    --- UUID field preset
    uuid = {
        type = "uuid",
        required = true
    },

    --- Positive integer preset
    positiveInt = {
        type = "integer",
        minValue = 1
    },

    --- Pagination limit preset
    limit = {
        type = "integer",
        default = 20,
        minValue = 1,
        maxValue = 100
    },

    --- Pagination offset preset
    offset = {
        type = "integer",
        default = 0,
        minValue = 0
    },

    --- URL field preset
    url = {
        type = "url",
        trim = true
    },

    --- Non-empty string preset
    nonEmptyString = {
        type = "string",
        required = true,
        min = 1,
        trim = true
    }
}

--- Get a preset by name
---@param name string
---@return table|nil
function schema.preset(name)
    return utils.deep_copy(schema.presets[name])
end

return schema
