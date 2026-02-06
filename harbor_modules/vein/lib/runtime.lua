-- Vein Runtime Helpers
-- Runtime utilities for template execution
--
-- @module vein.lib.runtime

local runtime = {}

--------------------------------------------------------------------------------
-- Safe Access
--------------------------------------------------------------------------------

--- Safely access nested table properties
---@param obj table Object to access
---@param path string Dot-separated path
---@return any? Value or nil
function runtime.get(obj, path)
    if obj == nil then
        return nil
    end

    local current = obj

    for key in path:gmatch("[^.]+") do
        if type(current) ~= "table" then
            return nil
        end
        current = current[key]
        if current == nil then
            return nil
        end
    end

    return current
end

--- Safely set nested table property
---@param obj table Object to modify
---@param path string Dot-separated path
---@param value any Value to set
function runtime.set(obj, path, value)
    if obj == nil then
        return
    end

    local current = obj
    local keys = {}

    for key in path:gmatch("[^.]+") do
        table.insert(keys, key)
    end

    for i = 1, #keys - 1 do
        local key = keys[i]
        if type(current[key]) ~= "table" then
            current[key] = {}
        end
        current = current[key]
    end

    current[keys[#keys]] = value
end

--------------------------------------------------------------------------------
-- Iteration Helpers
--------------------------------------------------------------------------------

--- Iterate over array or table with index
---@param value any Value to iterate
---@return function Iterator
function runtime.each(value)
    if type(value) ~= "table" then
        return function() end
    end

    if #value > 0 then
        -- Array iteration
        local i = 0
        return function()
            i = i + 1
            if value[i] then
                return i, value[i]
            end
        end
    else
        -- Object iteration
        return pairs(value)
    end
end

--- Create range iterator
---@param start number Start value
---@param stop number? End value (if nil, start becomes stop and start is 1)
---@param step number? Step value (default 1)
---@return function Iterator
function runtime.range(start, stop, step)
    if stop == nil then
        stop = start
        start = 1
    end
    step = step or 1

    local i = start - step

    return function()
        i = i + step
        if (step > 0 and i <= stop) or (step < 0 and i >= stop) then
            return i
        end
    end
end

--------------------------------------------------------------------------------
-- Loop Helpers
--------------------------------------------------------------------------------

--- Create loop context for iterations
---@param length number Total length
---@return function Loop context generator
function runtime.loop(length)
    local index = 0

    return function()
        index = index + 1
        if index > length then
            return nil
        end

        return {
            index = index,
            index0 = index - 1,
            first = index == 1,
            last = index == length,
            length = length,
            revindex = length - index + 1,
            revindex0 = length - index,
            cycle = function(...)
                local args = {...}
                return args[((index - 1) % #args) + 1]
            end
        }
    end
end

--------------------------------------------------------------------------------
-- Object Utilities
--------------------------------------------------------------------------------

--- Merge tables
---@param ... table Tables to merge
---@return table Merged table
function runtime.merge(...)
    local result = {}
    for _, t in ipairs({...}) do
        if type(t) == "table" then
            for k, v in pairs(t) do
                result[k] = v
            end
        end
    end
    return result
end

--- Deep clone a table
---@param obj table Table to clone
---@return table Cloned table
function runtime.clone(obj)
    if type(obj) ~= "table" then
        return obj
    end

    local result = {}
    for k, v in pairs(obj) do
        result[k] = runtime.clone(v)
    end
    return result
end

--- Check if value is empty
---@param value any Value to check
---@return boolean Is empty
function runtime.empty(value)
    if value == nil then
        return true
    end
    if value == "" then
        return true
    end
    if value == false then
        return true
    end
    if type(value) == "table" then
        return next(value) == nil
    end
    return false
end

--- Check if value is defined (not nil)
---@param value any Value to check
---@return boolean Is defined
function runtime.defined(value)
    return value ~= nil
end

--------------------------------------------------------------------------------
-- String Utilities
--------------------------------------------------------------------------------

--- Check if string contains substring
---@param str string String to search
---@param substring string Substring to find
---@return boolean Contains
function runtime.contains(str, substring)
    if type(str) ~= "string" then
        return false
    end
    return str:find(substring, 1, true) ~= nil
end

--- Check if string starts with prefix
---@param str string String to check
---@param prefix string Prefix to find
---@return boolean Starts with
function runtime.startswith(str, prefix)
    if type(str) ~= "string" then
        return false
    end
    return str:sub(1, #prefix) == prefix
end

--- Check if string ends with suffix
---@param str string String to check
---@param suffix string Suffix to find
---@return boolean Ends with
function runtime.endswith(str, suffix)
    if type(str) ~= "string" then
        return false
    end
    return str:sub(-#suffix) == suffix
end

--------------------------------------------------------------------------------
-- Type Checking
--------------------------------------------------------------------------------

--- Check if value is an array
---@param value any Value to check
---@return boolean Is array
function runtime.isArray(value)
    if type(value) ~= "table" then
        return false
    end
    return #value > 0 or next(value) == nil
end

--- Check if value is an object
---@param value any Value to check
---@return boolean Is object
function runtime.isObject(value)
    if type(value) ~= "table" then
        return false
    end
    return #value == 0 and next(value) ~= nil
end

--- Check if value is callable
---@param value any Value to check
---@return boolean Is callable
function runtime.isCallable(value)
    if type(value) == "function" then
        return true
    end
    if type(value) == "table" then
        local mt = getmetatable(value)
        return mt and type(mt.__call) == "function"
    end
    return false
end

return runtime
