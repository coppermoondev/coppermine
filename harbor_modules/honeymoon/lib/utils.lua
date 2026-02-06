-- HoneyMoon Utils Module
-- Common utilities used throughout the framework

local utils = {}

--------------------------------------------------------------------------------
-- URL Encoding/Decoding
--------------------------------------------------------------------------------

--- URL decode a string
---@param str string
---@return string
function utils.url_decode(str)
    str = str:gsub("+", " ")
    str = str:gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end)
    return str
end

--- URL encode a string
---@param str string
---@return string
function utils.url_encode(str)
    str = str:gsub("([^%w%-_.~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    return str
end

--------------------------------------------------------------------------------
-- String Utilities
--------------------------------------------------------------------------------

--- Generate a random string of specified length
---@param length number
---@return string
function utils.random_string(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = ""
    for _ = 1, length do
        local idx = math.random(1, #chars)
        result = result .. chars:sub(idx, idx)
    end
    return result
end

--- Trim whitespace from both ends of a string
---@param str string
---@return string
function utils.trim(str)
    return str:match("^%s*(.-)%s*$")
end

--- Split a string by delimiter
---@param str string
---@param delimiter string
---@return table
function utils.split(str, delimiter)
    local result = {}
    local pattern = string.format("([^%s]+)", delimiter)
    for match in str:gmatch(pattern) do
        table.insert(result, match)
    end
    return result
end

--------------------------------------------------------------------------------
-- Table Utilities
--------------------------------------------------------------------------------

--- Deep copy a table
---@param t table
---@return table
function utils.deep_copy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = utils.deep_copy(v)
    end
    return copy
end

--- Shallow merge tables (right overwrites left)
---@param ... table
---@return table
function utils.merge(...)
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

--- Check if table is empty
---@param t table
---@return boolean
function utils.is_empty(t)
    return next(t) == nil
end

--- Get table keys
---@param t table
---@return table
function utils.keys(t)
    local keys = {}
    for k in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end

--- Get table values
---@param t table
---@return table
function utils.values(t)
    local values = {}
    for _, v in pairs(t) do
        table.insert(values, v)
    end
    return values
end

--------------------------------------------------------------------------------
-- Base64 Encoding/Decoding
--------------------------------------------------------------------------------

local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

--- Base64 encode a string
---@param data string
---@return string
function utils.base64_encode(data)
    return ((data:gsub(".", function(x)
        local r, b = "", x:byte()
        for i = 8, 1, -1 do
            r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and "1" or "0")
        end
        return r
    end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
        if #x < 6 then return "" end
        local c = 0
        for i = 1, 6 do
            c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
        end
        return b64chars:sub(c + 1, c + 1)
    end) .. ({"", "==", "="})[#data % 3 + 1])
end

--- Base64 decode a string
---@param data string
---@return string
function utils.base64_decode(data)
    data = data:gsub("[^" .. b64chars .. "=]", "")
    return (data:gsub(".", function(x)
        if x == "=" then return "" end
        local r, f = "", (b64chars:find(x) - 1)
        for i = 6, 1, -1 do
            r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0")
        end
        return r
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
        if #x ~= 8 then return "" end
        local c = 0
        for i = 1, 8 do
            c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
        end
        return string.char(c)
    end))
end

--------------------------------------------------------------------------------
-- MIME Types
--------------------------------------------------------------------------------

utils.mime_types = {
    html = "text/html; charset=utf-8",
    htm = "text/html; charset=utf-8",
    css = "text/css; charset=utf-8",
    js = "application/javascript; charset=utf-8",
    mjs = "application/javascript; charset=utf-8",
    json = "application/json",
    xml = "application/xml",
    txt = "text/plain; charset=utf-8",
    md = "text/markdown; charset=utf-8",

    -- Images
    png = "image/png",
    jpg = "image/jpeg",
    jpeg = "image/jpeg",
    gif = "image/gif",
    svg = "image/svg+xml",
    ico = "image/x-icon",
    webp = "image/webp",
    avif = "image/avif",

    -- Fonts
    woff = "font/woff",
    woff2 = "font/woff2",
    ttf = "font/ttf",
    otf = "font/otf",
    eot = "application/vnd.ms-fontobject",

    -- Media
    mp3 = "audio/mpeg",
    wav = "audio/wav",
    ogg = "audio/ogg",
    mp4 = "video/mp4",
    webm = "video/webm",

    -- Documents
    pdf = "application/pdf",
    zip = "application/zip",
    tar = "application/x-tar",
    gz = "application/gzip",

    -- Data
    csv = "text/csv",
    ics = "text/calendar",
}

--- Get MIME type for file extension
---@param ext string
---@return string
function utils.get_mime_type(ext)
    return utils.mime_types[ext:lower()] or "application/octet-stream"
end

--- Get extension from filepath
---@param filepath string
---@return string
function utils.get_extension(filepath)
    return filepath:match("%.([^%.]+)$") or ""
end

--------------------------------------------------------------------------------
-- HTTP Status Codes
--------------------------------------------------------------------------------

utils.status_codes = {
    [100] = "Continue",
    [101] = "Switching Protocols",
    [200] = "OK",
    [201] = "Created",
    [202] = "Accepted",
    [204] = "No Content",
    [301] = "Moved Permanently",
    [302] = "Found",
    [303] = "See Other",
    [304] = "Not Modified",
    [307] = "Temporary Redirect",
    [308] = "Permanent Redirect",
    [400] = "Bad Request",
    [401] = "Unauthorized",
    [403] = "Forbidden",
    [404] = "Not Found",
    [405] = "Method Not Allowed",
    [406] = "Not Acceptable",
    [408] = "Request Timeout",
    [409] = "Conflict",
    [410] = "Gone",
    [413] = "Payload Too Large",
    [415] = "Unsupported Media Type",
    [422] = "Unprocessable Entity",
    [429] = "Too Many Requests",
    [500] = "Internal Server Error",
    [501] = "Not Implemented",
    [502] = "Bad Gateway",
    [503] = "Service Unavailable",
    [504] = "Gateway Timeout",
}

--- Get status text for code
---@param code number
---@return string
function utils.get_status_text(code)
    return utils.status_codes[code] or "Unknown"
end

--------------------------------------------------------------------------------
-- Validation Helpers
--------------------------------------------------------------------------------

--- Check if string is valid email
---@param str string
---@return boolean
function utils.is_email(str)
    return str:match("^[%w._%+-]+@[%w.-]+%.[%a]+$") ~= nil
end

--- Check if string is valid URL
---@param str string
---@return boolean
function utils.is_url(str)
    return str:match("^https?://[%w.-]+") ~= nil
end

--- Check if string is valid UUID
---@param str string
---@return boolean
function utils.is_uuid(str)
    return str:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil
end

--------------------------------------------------------------------------------
-- Path Utilities
--------------------------------------------------------------------------------

--- Normalize path (remove double slashes, resolve ..)
---@param path string
---@return string
function utils.normalize_path(path)
    -- Remove double slashes
    path = path:gsub("//+", "/")
    -- Ensure starts with /
    if not path:match("^/") then
        path = "/" .. path
    end
    -- Remove trailing slash (except for root)
    if #path > 1 and path:sub(-1) == "/" then
        path = path:sub(1, -2)
    end
    return path
end

--- Join path segments
---@param ... string
---@return string
function utils.join_path(...)
    local parts = {...}
    local result = table.concat(parts, "/")
    return utils.normalize_path(result)
end

--- Check if path contains directory traversal
---@param path string
---@return boolean
function utils.is_safe_path(path)
    return not path:find("%.%.") and not path:find("^/etc") and not path:find("^/proc")
end

return utils
