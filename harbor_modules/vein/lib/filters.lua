-- Vein Filters
-- Built-in filter functions for template expressions
--
-- @module vein.lib.filters

local filters = {}

--------------------------------------------------------------------------------
-- Escape Functions
--------------------------------------------------------------------------------

--- HTML escape a string
---@param value any Value to escape
---@return string Escaped string
function filters.escape(value)
    if value == nil then
        return ""
    end
    local s = tostring(value)
    return s:gsub("&", "&amp;")
            :gsub("<", "&lt;")
            :gsub(">", "&gt;")
            :gsub('"', "&quot;")
            :gsub("'", "&#39;")
end

filters.e = filters.escape
filters.html = filters.escape

--- URL encode a string
---@param value any Value to encode
---@return string Encoded string
function filters.url(value)
    if value == nil then
        return ""
    end
    local s = tostring(value)
    return s:gsub("([^%w%-_.~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
end

filters.urlencode = filters.url

--- URL decode a string
---@param value any Value to decode
---@return string Decoded string
function filters.urldecode(value)
    if value == nil then
        return ""
    end
    local s = tostring(value)
    s = s:gsub("+", " ")
    return s:gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end)
end

--- JSON encode a value
---@param value any Value to encode
---@return string JSON string
function filters.json(value)
    if json and json.encode then
        return json.encode(value)
    end
    -- Fallback basic implementation
    if type(value) == "string" then
        return '"' .. value:gsub('"', '\\"'):gsub("\n", "\\n") .. '"'
    elseif type(value) == "number" or type(value) == "boolean" then
        return tostring(value)
    elseif value == nil then
        return "null"
    elseif type(value) == "table" then
        local isArray = #value > 0
        local parts = {}
        if isArray then
            for _, v in ipairs(value) do
                table.insert(parts, filters.json(v))
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            for k, v in pairs(value) do
                table.insert(parts, '"' .. tostring(k) .. '":' .. filters.json(v))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end
    return "null"
end

--------------------------------------------------------------------------------
-- String Transformations
--------------------------------------------------------------------------------

--- Convert to uppercase
---@param value any Value to transform
---@return string Uppercase string
function filters.upper(value)
    if value == nil then
        return ""
    end
    return tostring(value):upper()
end

filters.uppercase = filters.upper

--- Convert to lowercase
---@param value any Value to transform
---@return string Lowercase string
function filters.lower(value)
    if value == nil then
        return ""
    end
    return tostring(value):lower()
end

filters.lowercase = filters.lower

--- Capitalize first letter
---@param value any Value to transform
---@return string Capitalized string
function filters.capitalize(value)
    if value == nil then
        return ""
    end
    local s = tostring(value)
    return s:sub(1, 1):upper() .. s:sub(2):lower()
end

--- Title case (capitalize each word)
---@param value any Value to transform
---@return string Title cased string
function filters.title(value)
    if value == nil then
        return ""
    end
    local s = tostring(value)
    return s:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
end

--- Trim whitespace
---@param value any Value to trim
---@return string Trimmed string
function filters.trim(value)
    if value == nil then
        return ""
    end
    return tostring(value):match("^%s*(.-)%s*$")
end

--- Strip HTML tags
---@param value any Value to strip
---@return string Stripped string
function filters.striptags(value)
    if value == nil then
        return ""
    end
    return tostring(value):gsub("<[^>]+>", "")
end

--- Convert newlines to <br>
---@param value any Value to transform
---@return string String with <br> tags
function filters.nl2br(value)
    if value == nil then
        return ""
    end
    return tostring(value):gsub("\n", "<br>\n")
end

--- Truncate string to length
---@param value any Value to truncate
---@param length number Maximum length
---@param suffix string? Suffix to add (default "...")
---@return string Truncated string
function filters.truncate(value, length, suffix)
    if value == nil then
        return ""
    end
    length = length or 50
    suffix = suffix or "..."
    local s = tostring(value)
    if #s <= length then
        return s
    end
    return s:sub(1, length - #suffix) .. suffix
end

--- Truncate words
---@param value any Value to truncate
---@param count number Maximum word count
---@param suffix string? Suffix to add (default "...")
---@return string Truncated string
function filters.truncatewords(value, count, suffix)
    if value == nil then
        return ""
    end
    count = count or 10
    suffix = suffix or "..."
    local words = {}
    for word in tostring(value):gmatch("%S+") do
        table.insert(words, word)
        if #words >= count then
            break
        end
    end
    local result = table.concat(words, " ")
    if #words >= count then
        result = result .. suffix
    end
    return result
end

--- Pad left
---@param value any Value to pad
---@param length number Target length
---@param char string? Padding character (default " ")
---@return string Padded string
function filters.padleft(value, length, char)
    if value == nil then
        return ""
    end
    char = char or " "
    local s = tostring(value)
    while #s < length do
        s = char .. s
    end
    return s
end

filters.lpad = filters.padleft

--- Pad right
---@param value any Value to pad
---@param length number Target length
---@param char string? Padding character (default " ")
---@return string Padded string
function filters.padright(value, length, char)
    if value == nil then
        return ""
    end
    char = char or " "
    local s = tostring(value)
    while #s < length do
        s = s .. char
    end
    return s
end

filters.rpad = filters.padright

--- Center string
---@param value any Value to center
---@param length number Target length
---@param char string? Padding character (default " ")
---@return string Centered string
function filters.center(value, length, char)
    if value == nil then
        return ""
    end
    char = char or " "
    local s = tostring(value)
    local padTotal = length - #s
    if padTotal <= 0 then
        return s
    end
    local padLeft = math.floor(padTotal / 2)
    local padRight = padTotal - padLeft
    return string.rep(char, padLeft) .. s .. string.rep(char, padRight)
end

--- Replace string
---@param value any Value to search in
---@param search string String to find
---@param replace string String to replace with
---@return string Result string
function filters.replace(value, search, replace)
    if value == nil then
        return ""
    end
    return tostring(value):gsub(search, replace)
end

--- Split string into array
---@param value any Value to split
---@param delimiter string? Delimiter (default " ")
---@return table Array of parts
function filters.split(value, delimiter)
    if value == nil then
        return {}
    end
    delimiter = delimiter or " "
    local result = {}
    local s = tostring(value)
    for part in s:gmatch("[^" .. delimiter .. "]+") do
        table.insert(result, part)
    end
    return result
end

--- Reverse string
---@param value any Value to reverse
---@return string Reversed string
function filters.reverse(value)
    if value == nil then
        return ""
    end
    return tostring(value):reverse()
end

--- Slugify string
---@param value any Value to slugify
---@return string Slugified string
function filters.slug(value)
    if value == nil then
        return ""
    end
    local s = tostring(value):lower()
    s = s:gsub("[^%w%s-]", "")
    s = s:gsub("%s+", "-")
    s = s:gsub("%-+", "-")
    s = s:match("^%-*(.-)%-*$")
    return s
end

filters.slugify = filters.slug

--------------------------------------------------------------------------------
-- Number Formatting
--------------------------------------------------------------------------------

--- Format number with separators
---@param value any Number to format
---@param decimals number? Decimal places
---@param decSep string? Decimal separator (default ".")
---@param thousandsSep string? Thousands separator (default ",")
---@return string Formatted number
function filters.number(value, decimals, decSep, thousandsSep)
    if value == nil then
        return "0"
    end
    local num = tonumber(value) or 0
    decimals = decimals or 0
    decSep = decSep or "."
    thousandsSep = thousandsSep or ","

    local formatted = string.format("%." .. decimals .. "f", num)

    -- Split integer and decimal parts
    local int, dec = formatted:match("^(-?%d+)%.?(%d*)$")

    -- Add thousands separators
    int = int:reverse():gsub("(%d%d%d)", "%1" .. thousandsSep):reverse()
    int = int:gsub("^" .. thousandsSep, ""):gsub("^%-" .. thousandsSep, "-")

    if decimals > 0 and dec and #dec > 0 then
        return int .. decSep .. dec
    end
    return int
end

--- Format as currency
---@param value any Number to format
---@param symbol string? Currency symbol (default "$")
---@param decimals number? Decimal places (default 2)
---@return string Formatted currency
function filters.currency(value, symbol, decimals)
    symbol = symbol or "$"
    decimals = decimals or 2
    return symbol .. filters.number(value, decimals)
end

filters.money = filters.currency

--- Format as percentage
---@param value any Number to format
---@param decimals number? Decimal places (default 0)
---@return string Formatted percentage
function filters.percent(value, decimals)
    if value == nil then
        return "0%"
    end
    decimals = decimals or 0
    local num = tonumber(value) or 0
    return string.format("%." .. decimals .. "f%%", num * 100)
end

--- Format bytes to human readable
---@param value any Bytes to format
---@param decimals number? Decimal places (default 2)
---@return string Formatted size
function filters.bytes(value, decimals)
    if value == nil then
        return "0 B"
    end
    decimals = decimals or 2
    local num = tonumber(value) or 0
    local units = { "B", "KB", "MB", "GB", "TB", "PB" }
    local unitIndex = 1

    while num >= 1024 and unitIndex < #units do
        num = num / 1024
        unitIndex = unitIndex + 1
    end

    return string.format("%." .. decimals .. "f %s", num, units[unitIndex])
end

filters.filesize = filters.bytes

--- Round number
---@param value any Number to round
---@param decimals number? Decimal places (default 0)
---@return number Rounded number
function filters.round(value, decimals)
    if value == nil then
        return 0
    end
    decimals = decimals or 0
    local num = tonumber(value) or 0
    local mult = 10 ^ decimals
    return math.floor(num * mult + 0.5) / mult
end

--- Floor number
---@param value any Number to floor
---@return number Floored number
function filters.floor(value)
    if value == nil then
        return 0
    end
    return math.floor(tonumber(value) or 0)
end

--- Ceil number
---@param value any Number to ceil
---@return number Ceiled number
function filters.ceil(value)
    if value == nil then
        return 0
    end
    return math.ceil(tonumber(value) or 0)
end

--- Absolute value
---@param value any Number
---@return number Absolute value
function filters.abs(value)
    if value == nil then
        return 0
    end
    return math.abs(tonumber(value) or 0)
end

--------------------------------------------------------------------------------
-- Date/Time Formatting
--------------------------------------------------------------------------------

--- Format date/timestamp
---@param value any Timestamp or date string
---@param format string? Date format (default "%Y-%m-%d")
---@return string Formatted date
function filters.date(value, format)
    format = format or "%Y-%m-%d"
    if value == nil then
        return ""
    end

    local timestamp
    if type(value) == "number" then
        timestamp = value
    else
        -- Try to parse common formats
        timestamp = os.time()
    end

    return os.date(format, timestamp)
end

--- Format as datetime
---@param value any Timestamp
---@param format string? Format (default "%Y-%m-%d %H:%M:%S")
---@return string Formatted datetime
function filters.datetime(value, format)
    format = format or "%Y-%m-%d %H:%M:%S"
    return filters.date(value, format)
end

--- Format as time
---@param value any Timestamp
---@param format string? Format (default "%H:%M:%S")
---@return string Formatted time
function filters.time(value, format)
    format = format or "%H:%M:%S"
    return filters.date(value, format)
end

--- Relative time (time ago)
---@param value any Timestamp
---@return string Relative time string
function filters.timeago(value)
    if value == nil then
        return ""
    end

    local timestamp = tonumber(value) or os.time()
    local diff = os.time() - timestamp

    if diff < 0 then
        diff = -diff
        local prefix = "in "
        if diff < 60 then return prefix .. "a moment" end
        if diff < 3600 then return prefix .. math.floor(diff / 60) .. " minutes" end
        if diff < 86400 then return prefix .. math.floor(diff / 3600) .. " hours" end
        if diff < 604800 then return prefix .. math.floor(diff / 86400) .. " days" end
        return prefix .. math.floor(diff / 604800) .. " weeks"
    else
        if diff < 60 then return "just now" end
        if diff < 3600 then return math.floor(diff / 60) .. " minutes ago" end
        if diff < 86400 then return math.floor(diff / 3600) .. " hours ago" end
        if diff < 604800 then return math.floor(diff / 86400) .. " days ago" end
        return math.floor(diff / 604800) .. " weeks ago"
    end
end

filters.ago = filters.timeago

--------------------------------------------------------------------------------
-- Array/Table Filters
--------------------------------------------------------------------------------

--- Get array/table length
---@param value any Array or table
---@return number Length
function filters.length(value)
    if value == nil then
        return 0
    end
    if type(value) == "string" then
        return #value
    end
    if type(value) == "table" then
        local count = 0
        for _ in pairs(value) do
            count = count + 1
        end
        return count
    end
    return 0
end

filters.count = filters.length
filters.size = filters.length

--- Get first element
---@param value any Array
---@return any First element
function filters.first(value)
    if value == nil or type(value) ~= "table" then
        return nil
    end
    return value[1]
end

--- Get last element
---@param value any Array
---@return any Last element
function filters.last(value)
    if value == nil or type(value) ~= "table" then
        return nil
    end
    return value[#value]
end

--- Join array elements
---@param value any Array
---@param separator string? Separator (default ", ")
---@return string Joined string
function filters.join(value, separator)
    if value == nil or type(value) ~= "table" then
        return ""
    end
    separator = separator or ", "
    local strings = {}
    for _, v in ipairs(value) do
        table.insert(strings, tostring(v))
    end
    return table.concat(strings, separator)
end

--- Sort array
---@param value any Array
---@param key string? Key to sort by (for array of tables)
---@return table Sorted array
function filters.sort(value, key)
    if value == nil or type(value) ~= "table" then
        return {}
    end

    local sorted = {}
    for _, v in ipairs(value) do
        table.insert(sorted, v)
    end

    if key then
        table.sort(sorted, function(a, b)
            return (a[key] or "") < (b[key] or "")
        end)
    else
        table.sort(sorted)
    end

    return sorted
end

--- Get keys of table
---@param value any Table
---@return table Keys array
function filters.keys(value)
    if value == nil or type(value) ~= "table" then
        return {}
    end
    local result = {}
    for k in pairs(value) do
        table.insert(result, k)
    end
    return result
end

--- Get values of table
---@param value any Table
---@return table Values array
function filters.values(value)
    if value == nil or type(value) ~= "table" then
        return {}
    end
    local result = {}
    for _, v in pairs(value) do
        table.insert(result, v)
    end
    return result
end

--- Slice array
---@param value any Array
---@param start number Start index
---@param stop number? End index
---@return table Sliced array
function filters.slice(value, start, stop)
    if value == nil or type(value) ~= "table" then
        return {}
    end
    start = start or 1
    stop = stop or #value
    local result = {}
    for i = start, stop do
        if value[i] then
            table.insert(result, value[i])
        end
    end
    return result
end

--- Map over array (extract key)
---@param value any Array of tables
---@param key string Key to extract
---@return table Array of values
function filters.pluck(value, key)
    if value == nil or type(value) ~= "table" then
        return {}
    end
    local result = {}
    for _, item in ipairs(value) do
        if type(item) == "table" then
            table.insert(result, item[key])
        end
    end
    return result
end

--- Group by key
---@param value any Array of tables
---@param key string Key to group by
---@return table Grouped table
function filters.groupby(value, key)
    if value == nil or type(value) ~= "table" then
        return {}
    end
    local result = {}
    for _, item in ipairs(value) do
        if type(item) == "table" then
            local groupKey = item[key]
            if groupKey then
                if not result[groupKey] then
                    result[groupKey] = {}
                end
                table.insert(result[groupKey], item)
            end
        end
    end
    return result
end

--------------------------------------------------------------------------------
-- Conditional Filters
--------------------------------------------------------------------------------

--- Default value if nil/empty
---@param value any Value to check
---@param default any Default value
---@return any Value or default
function filters.default(value, default)
    if value == nil or value == "" then
        return default
    end
    return value
end

filters.d = filters.default

--- Conditional output
---@param value any Value to check
---@param trueValue any Value if truthy
---@param falseValue any Value if falsy
---@return any Result
function filters.ternary(value, trueValue, falseValue)
    if value then
        return trueValue
    else
        return falseValue
    end
end

--------------------------------------------------------------------------------
-- Debug Filters
--------------------------------------------------------------------------------

--- Dump value for debugging
---@param value any Value to dump
---@return string Debug output
function filters.dump(value)
    local function dump_value(v, indent)
        indent = indent or 0
        local spaces = string.rep("  ", indent)

        if type(v) == "table" then
            local parts = { "{\n" }
            for k, val in pairs(v) do
                table.insert(parts, spaces .. "  " .. tostring(k) .. " = ")
                table.insert(parts, dump_value(val, indent + 1))
                table.insert(parts, ",\n")
            end
            table.insert(parts, spaces .. "}")
            return table.concat(parts)
        elseif type(v) == "string" then
            return '"' .. v .. '"'
        else
            return tostring(v)
        end
    end

    return "<pre>" .. filters.escape(dump_value(value)) .. "</pre>"
end

--- Get type of value
---@param value any Value
---@return string Type name
function filters.typeof(value)
    return type(value)
end

--------------------------------------------------------------------------------
-- Get default filters
--------------------------------------------------------------------------------

--- Get all default filters
---@return table Filters table
function filters.defaults()
    local defaults = {}
    for name, fn in pairs(filters) do
        if type(fn) == "function" and name ~= "defaults" then
            defaults[name] = fn
        end
    end
    return defaults
end

return filters
