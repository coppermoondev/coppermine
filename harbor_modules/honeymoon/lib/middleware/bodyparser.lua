-- HoneyMoon Body Parser Middleware
-- Parse request bodies (JSON, URL-encoded, etc.)

local utils = require("honeymoon.lib.utils")

local bodyparser = {}

--- Parse a size string like "50mb", "1kb", "100" into bytes
---@param size string|number Size value
---@return number Bytes
local function parse_size(size)
    if type(size) == "number" then
        return size
    end
    if type(size) ~= "string" then
        return 1024 * 1024 -- default 1MB
    end

    local num, unit = size:lower():match("^(%d+)%s*(%a*)$")
    num = tonumber(num)
    if not num then
        return 1024 * 1024 -- default 1MB
    end

    if unit == "" or unit == "b" then
        return num
    elseif unit == "kb" or unit == "k" then
        return num * 1024
    elseif unit == "mb" or unit == "m" then
        return num * 1024 * 1024
    elseif unit == "gb" or unit == "g" then
        return num * 1024 * 1024 * 1024
    else
        return num
    end
end

--- Default options
local defaults = {
    limit = 1024 * 1024,  -- 1MB
    strict = true,         -- Only accept arrays/objects for JSON
}

--- Create JSON body parser middleware
---@param options table|nil Parser options
---@return function Middleware function
function bodyparser.json(options)
    options = options or {}
    local limit = parse_size(options.limit or defaults.limit)
    local strict = options.strict ~= false

    return function(req, res, next)
        -- Check content type
        local content_type = req:get("content-type") or ""
        if not content_type:find("application/json") then
            return next()
        end

        -- Check body size
        if #req.body > limit then
            return res:status(413):json({
                error = "Payload Too Large",
                message = "Request body exceeds " .. limit .. " bytes"
            })
        end

        -- Skip empty body
        if #req.body == 0 then
            req._parsed_body = {}
            return next()
        end

        -- Parse JSON
        local ok, data = pcall(json.decode, req.body)
        if not ok then
            return res:status(400):json({
                error = "Bad Request",
                message = "Invalid JSON: " .. tostring(data)
            })
        end

        -- Strict mode: only accept objects/arrays
        if strict and type(data) ~= "table" then
            return res:status(400):json({
                error = "Bad Request",
                message = "JSON must be an object or array"
            })
        end

        req._parsed_body = data
        next()
    end
end

--- Create URL-encoded body parser middleware
---@param options table|nil Parser options
---@return function Middleware function
function bodyparser.urlencoded(options)
    options = options or {}
    local limit = parse_size(options.limit or defaults.limit)
    local extended = options.extended ~= false  -- Support nested objects

    return function(req, res, next)
        -- Check content type
        local content_type = req:get("content-type") or ""
        if not content_type:find("application/x%-www%-form%-urlencoded") then
            return next()
        end

        -- Check body size
        if #req.body > limit then
            return res:status(413):json({
                error = "Payload Too Large",
                message = "Request body exceeds " .. limit .. " bytes"
            })
        end

        -- Parse body
        local parsed = {}
        for pair in req.body:gmatch("[^&]+") do
            local key, value = pair:match("([^=]+)=?(.*)")
            if key then
                key = utils.url_decode(key)
                value = utils.url_decode(value or "")

                if extended then
                    -- Handle nested keys like "user[name]" or "items[]"
                    local base, rest = key:match("^([^%[]+)(.*)$")
                    if rest and #rest > 0 then
                        -- Has brackets
                        local current = parsed
                        local parts = {base}

                        -- Extract all bracket parts
                        for part in rest:gmatch("%[([^%]]*)%]") do
                            table.insert(parts, part)
                        end

                        -- Build nested structure
                        for i = 1, #parts - 1 do
                            local part = parts[i]
                            local next_part = parts[i + 1]

                            if part == "" then
                                -- Array index
                                if type(current) ~= "table" then
                                    current = {}
                                end
                                part = #current + 1
                            end

                            if current[part] == nil then
                                -- Determine if next level is array or object
                                if next_part == "" or tonumber(next_part) then
                                    current[part] = {}
                                else
                                    current[part] = {}
                                end
                            end

                            current = current[part]
                        end

                        -- Set the final value
                        local last_part = parts[#parts]
                        if last_part == "" then
                            -- Array push
                            table.insert(current, value)
                        else
                            current[last_part] = value
                        end
                    else
                        parsed[key] = value
                    end
                else
                    -- Simple mode: just key=value
                    parsed[key] = value
                end
            end
        end

        req._parsed_body = parsed
        next()
    end
end

--- Create raw body parser middleware
---@param options table|nil Parser options
---@return function Middleware function
function bodyparser.raw(options)
    options = options or {}
    local limit = parse_size(options.limit or defaults.limit)
    local type_filter = options.type or "application/octet-stream"

    return function(req, res, next)
        local content_type = req:get("content-type") or ""

        -- Check content type if filter specified
        if type_filter ~= "*" and not content_type:find(type_filter, 1, true) then
            return next()
        end

        -- Check body size
        if #req.body > limit then
            return res:status(413):json({
                error = "Payload Too Large"
            })
        end

        -- Keep body as-is (already raw)
        req._parsed_body = req.body
        next()
    end
end

--- Create text body parser middleware
---@param options table|nil Parser options
---@return function Middleware function
function bodyparser.text(options)
    options = options or {}
    local limit = parse_size(options.limit or defaults.limit)
    local type_filter = options.type or "text/plain"
    local default_charset = options.defaultCharset or "utf-8"

    return function(req, res, next)
        local content_type = req:get("content-type") or ""

        -- Check content type
        if not content_type:find(type_filter, 1, true) and not content_type:find("text/") then
            return next()
        end

        -- Check body size
        if #req.body > limit then
            return res:status(413):json({
                error = "Payload Too Large"
            })
        end

        req._parsed_body = req.body
        next()
    end
end

--- Create combined body parser (JSON + URL-encoded)
---@param options table|nil Parser options
---@return function Middleware function
function bodyparser.create(options)
    options = options or {}

    local json_parser = bodyparser.json(options)
    local urlencoded_parser = bodyparser.urlencoded(options)

    return function(req, res, next)
        local content_type = req:get("content-type") or ""

        if content_type:find("application/json") then
            return json_parser(req, res, next)
        elseif content_type:find("application/x%-www%-form%-urlencoded") then
            return urlencoded_parser(req, res, next)
        else
            next()
        end
    end
end

return bodyparser
