-- HoneyMoon Errors Module
-- Error classes and error page rendering

local utils = require("honeymoon.lib.utils")

local errors = {}

--- Escape replacement string for gsub (% is special in replacement)
local function escape_replacement(str)
    if str then
        return tostring(str):gsub("%%", "%%%%")
    end
    return str or ""
end

--------------------------------------------------------------------------------
-- Error Classes
--------------------------------------------------------------------------------

--- Base HTTP Error class
---@class HttpError
---@field status number
---@field message string
---@field code string
errors.HttpError = {}
errors.HttpError.__index = errors.HttpError

function errors.HttpError.new(status, message, code)
    local self = setmetatable({}, errors.HttpError)
    self.status = status or 500
    self.message = message or utils.get_status_text(status)
    self.code = code or "HTTP_ERROR"
    return self
end

function errors.HttpError:__tostring()
    return string.format("HttpError(%d): %s", self.status, self.message)
end

--- Validation Error class
---@class ValidationError
---@field errors table
---@field message string
errors.ValidationError = {}
errors.ValidationError.__index = errors.ValidationError

function errors.ValidationError.new(validation_errors)
    local self = setmetatable({}, errors.ValidationError)
    self.errors = validation_errors or {}
    self.message = "Validation failed"
    self.status = 422
    return self
end

function errors.ValidationError:__tostring()
    local parts = {}
    for field, msgs in pairs(self.errors) do
        if type(msgs) == "table" then
            table.insert(parts, field .. ": " .. table.concat(msgs, ", "))
        else
            table.insert(parts, field .. ": " .. tostring(msgs))
        end
    end
    return "ValidationError: " .. table.concat(parts, "; ")
end

--- Check if error is a ValidationError
function errors.is_validation_error(err)
    return type(err) == "table" and err.errors ~= nil and err.status == 422
end

--- Check if error is an HttpError
function errors.is_http_error(err)
    return type(err) == "table" and err.status ~= nil and err.code ~= nil
end

--------------------------------------------------------------------------------
-- Error Factories
--------------------------------------------------------------------------------

function errors.bad_request(message)
    return errors.HttpError.new(400, message or "Bad Request", "BAD_REQUEST")
end

function errors.unauthorized(message)
    return errors.HttpError.new(401, message or "Unauthorized", "UNAUTHORIZED")
end

function errors.forbidden(message)
    return errors.HttpError.new(403, message or "Forbidden", "FORBIDDEN")
end

function errors.not_found(message)
    return errors.HttpError.new(404, message or "Not Found", "NOT_FOUND")
end

function errors.method_not_allowed(message)
    return errors.HttpError.new(405, message or "Method Not Allowed", "METHOD_NOT_ALLOWED")
end

function errors.conflict(message)
    return errors.HttpError.new(409, message or "Conflict", "CONFLICT")
end

function errors.unprocessable(message)
    return errors.HttpError.new(422, message or "Unprocessable Entity", "UNPROCESSABLE")
end

function errors.too_many_requests(message)
    return errors.HttpError.new(429, message or "Too Many Requests", "RATE_LIMITED")
end

function errors.internal(message)
    return errors.HttpError.new(500, message or "Internal Server Error", "INTERNAL_ERROR")
end

--------------------------------------------------------------------------------
-- Error Page Rendering
--------------------------------------------------------------------------------

--- Escape HTML entities
local function escape_html(str)
    if not str then return "" end
    return tostring(str)
        :gsub("&", "&amp;")
        :gsub("<", "&lt;")
        :gsub(">", "&gt;")
        :gsub('"', "&quot;")
end

--- Format stack trace for display
---@param stack string
---@return string
local function format_stack_trace(stack)
    if not stack then
        return '<span class="stack-line">No stack trace available</span>'
    end

    local lines = {}
    for line in stack:gmatch("[^\n]+") do
        local file, ln, func = line:match("([^:]+):(%d+): in (.+)")
        if file then
            table.insert(lines, string.format(
                '<span class="stack-line"><span class="stack-at">at</span> ' ..
                '<span class="stack-file">%s</span>:' ..
                '<span class="stack-line-num">%s</span> ' ..
                '<span class="stack-func">%s</span></span>',
                escape_html(file), ln, escape_html(func)
            ))
        else
            local trimmed = line:match("^%s*(.-)%s*$")
            if trimmed and #trimmed > 0 then
                table.insert(lines, string.format(
                    '<span class="stack-line">%s</span>',
                    escape_html(trimmed)
                ))
            end
        end
    end
    return table.concat(lines, "\n")
end

--- Get method badge color class
local function get_method_color(method)
    local colors = {
        GET = "#22c55e",
        POST = "#3b82f6",
        PUT = "#f59e0b",
        DELETE = "#ef4444",
        PATCH = "#a855f7",
    }
    return colors[method] or "#f59e0b"
end

--- Render error page HTML
---@param options table
---@return string
function errors.render_error_page(options)
    local status = options.status or 500
    local message = options.message or utils.get_status_text(status)
    local stack = options.stack
    local req = options.request
    local is_production = options.production or false
    local version = options.version or "0.2.0"

    local status_text = utils.get_status_text(status)
    local method = req and req.method or "GET"
    local path = req and req.path or "/"
    local request_id = req and req.id or "-"
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local method_color = get_method_color(method)

    local stack_html = format_stack_trace(stack)
    local escaped_message = escape_html(message)

    local debug_display = is_production and "none" or "block"
    local prod_display = is_production and "block" or "none"

    -- Build HTML directly with string concatenation (more reliable than gsub)
    local html = [[<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Error ]] .. status .. [[ - ]] .. status_text .. [[</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: Consolas, "Courier New", ui-monospace, monospace;
            background: #09090b;
            color: #fafafa;
            min-height: 100vh;
            line-height: 1.6;
        }
        .container { max-width: 900px; margin: 0 auto; padding: 40px 20px; }
        .error-card {
            background: #18181b;
            border: 1px solid #27272a;
            border-radius: 12px;
            overflow: hidden;
        }
        .error-header {
            background: linear-gradient(135deg, #ef4444 0%, #b91c1c 100%);
            padding: 32px;
            position: relative;
            overflow: hidden;
        }
        .error-header::before {
            content: "]] .. status .. [[";
            position: absolute;
            right: 20px;
            top: 50%;
            transform: translateY(-50%);
            font-size: 120px;
            font-weight: 900;
            opacity: 0.15;
            line-height: 1;
            font-family: Consolas, monospace;
        }
        .error-header h1 {
            font-size: 1.5rem;
            font-weight: 600;
            color: white;
            position: relative;
            z-index: 1;
        }
        .status-badge {
            display: inline-block;
            background: rgba(255,255,255,0.2);
            padding: 4px 12px;
            border-radius: 6px;
            font-size: 0.75rem;
            margin-bottom: 8px;
            font-weight: 600;
        }
        .error-body { padding: 24px; }
        .error-message {
            background: rgba(239, 68, 68, 0.1);
            border-left: 3px solid #f59e0b;
            padding: 16px 20px;
            border-radius: 0 8px 8px 0;
            margin-bottom: 24px;
        }
        .error-message p { color: #fbbf24; font-size: 0.95rem; }
        .section { margin-bottom: 24px; }
        .section-title {
            font-size: 0.7rem;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.1em;
            color: #71717a;
            margin-bottom: 12px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .section-title::after {
            content: "";
            flex: 1;
            height: 1px;
            background: #27272a;
        }
        .stack-trace {
            background: #09090b;
            border: 1px solid #27272a;
            border-radius: 8px;
            padding: 16px;
            overflow-x: auto;
            font-size: 0.8rem;
            line-height: 1.8;
        }
        .stack-line { display: block; padding: 2px 0; }
        .stack-line:hover { background: rgba(245, 158, 11, 0.1); margin: 0 -16px; padding: 2px 16px; }
        .stack-at { color: #71717a; }
        .stack-file { color: #f59e0b; }
        .stack-line-num { color: #22c55e; }
        .stack-func { color: #a855f7; }
        .request-info {
            background: #09090b;
            border: 1px solid #27272a;
            border-radius: 8px;
            overflow: hidden;
        }
        .request-info table { width: 100%; border-collapse: collapse; }
        .request-info tr { border-bottom: 1px solid #27272a; }
        .request-info tr:last-child { border-bottom: none; }
        .request-info td { padding: 10px 16px; font-size: 0.85rem; }
        .request-info td:first-child {
            width: 120px;
            color: #71717a;
            font-weight: 500;
            background: rgba(0,0,0,0.3);
        }
        .method-badge {
            display: inline-block;
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 0.7rem;
            font-weight: 600;
            background: ]] .. method_color .. [[20;
            color: ]] .. method_color .. [[;
        }
        .footer {
            text-align: center;
            padding: 20px;
            color: #52525b;
            font-size: 0.75rem;
            border-top: 1px solid #27272a;
        }
        .footer a { color: #f59e0b; text-decoration: none; }
        .footer a:hover { text-decoration: underline; }
        .production-notice { text-align: center; padding: 40px; color: #a1a1aa; }
        .production-notice p { margin-bottom: 8px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="error-card">
            <div class="error-header">
                <span class="status-badge">]] .. status .. [[ Error</span>
                <h1>]] .. status_text .. [[</h1>
            </div>
            <div class="error-body">
                <div class="error-message">
                    <p>]] .. escaped_message .. [[</p>
                </div>

                <div style="display: ]] .. debug_display .. [[;">
                    <div class="section">
                        <div class="section-title">Stack Trace</div>
                        <div class="stack-trace">
]] .. stack_html .. [[
                        </div>
                    </div>

                    <div class="section">
                        <div class="section-title">Request Information</div>
                        <div class="request-info">
                            <table>
                                <tr>
                                    <td>Method</td>
                                    <td><span class="method-badge">]] .. method .. [[</span></td>
                                </tr>
                                <tr>
                                    <td>Path</td>
                                    <td>]] .. escape_html(path) .. [[</td>
                                </tr>
                                <tr>
                                    <td>Timestamp</td>
                                    <td>]] .. timestamp .. [[</td>
                                </tr>
                                <tr>
                                    <td>Request ID</td>
                                    <td>]] .. request_id .. [[</td>
                                </tr>
                            </table>
                        </div>
                    </div>
                </div>

                <div style="display: ]] .. prod_display .. [[;">
                    <div class="production-notice">
                        <p>An error occurred while processing your request.</p>
                        <p>Please try again later or contact support if the problem persists.</p>
                    </div>
                </div>
            </div>
            <div class="footer">
                Powered by <a href="https://coppermoon.dev">HoneyMoon</a> v]] .. version .. [[
            </div>
        </div>
    </div>
</body>
</html>]]

    return html
end

--------------------------------------------------------------------------------
-- JSON Error Response
--------------------------------------------------------------------------------

--- Create JSON error response body
---@param status number
---@param message string
---@param code string|nil
---@param details table|nil
---@return table
function errors.json_error(status, message, code, details)
    local response = {
        error = {
            status = status,
            message = message,
            code = code or "ERROR"
        }
    }
    if details then
        response.error.details = details
    end
    return response
end

--- Create validation error JSON response
---@param validation_errors table
---@return table
function errors.json_validation_error(validation_errors)
    return {
        error = {
            status = 422,
            message = "Validation failed",
            code = "VALIDATION_ERROR",
            details = validation_errors
        }
    }
end

return errors
