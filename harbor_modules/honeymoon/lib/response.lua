-- HoneyMoon Response Module
-- HTTP response builder

local utils = require("honeymoon.lib.utils")
local errors = require("honeymoon.lib.errors")

local response = {}

--------------------------------------------------------------------------------
-- Response Class
--------------------------------------------------------------------------------

---@class Response
---@field _status number HTTP status code
---@field _headers table Response headers
---@field _cookies table Cookies to set
---@field _sent boolean Whether response has been sent
---@field _ctx table Raw context
---@field app table Application instance
---@field locals table Template variables
local Response = {}
Response.__index = Response

--- Create a new response object
---@param ctx table Raw response context
---@param app table Application instance
---@return Response
function response.new(ctx, app)
    local self = setmetatable({}, Response)

    self._status = 200
    self._headers = {
        ["Content-Type"] = "text/plain; charset=utf-8"
    }
    self._cookies = {}
    self._sent = false
    self._ctx = ctx
    self.app = app
    self.locals = {}

    return self
end

--------------------------------------------------------------------------------
-- Status and Headers
--------------------------------------------------------------------------------

--- Set response status code
---@param code number HTTP status code
---@return Response self for chaining
function Response:status(code)
    self._status = code
    self._ctx._status = code
    return self
end

--- Get current status code
---@return number
function Response:getStatus()
    return self._status
end

--- Set a response header
---@param name string Header name
---@param value string Header value
---@return Response self for chaining
function Response:set(name, value)
    self._headers[name] = value
    return self
end

--- Get a response header
---@param name string Header name
---@return string|nil
function Response:get(name)
    return self._headers[name]
end

--- Append to a response header
---@param name string Header name
---@param value string Value to append
---@return Response self for chaining
function Response:append(name, value)
    local existing = self._headers[name]
    if existing then
        if type(existing) == "table" then
            table.insert(existing, value)
        else
            self._headers[name] = {existing, value}
        end
    else
        self._headers[name] = value
    end
    return self
end

--- Remove a response header
---@param name string Header name
---@return Response self for chaining
function Response:remove(name)
    self._headers[name] = nil
    return self
end

--- Set Content-Type header
---@param content_type string MIME type
---@return Response self for chaining
function Response:type(content_type)
    -- Handle short forms
    if content_type == "json" then
        content_type = "application/json"
    elseif content_type == "html" then
        content_type = "text/html; charset=utf-8"
    elseif content_type == "text" then
        content_type = "text/plain; charset=utf-8"
    elseif content_type == "xml" then
        content_type = "application/xml"
    end

    self._headers["Content-Type"] = content_type
    return self
end

--- Set multiple headers
---@param headers table Header key-value pairs
---@return Response self for chaining
function Response:headers(headers)
    for name, value in pairs(headers) do
        self._headers[name] = value
    end
    return self
end

--------------------------------------------------------------------------------
-- Cookies
--------------------------------------------------------------------------------

--- Set a cookie
---@param name string Cookie name
---@param value string Cookie value
---@param options table|nil Cookie options
---@return Response self for chaining
function Response:cookie(name, value, options)
    options = options or {}

    local parts = {
        utils.url_encode(name) .. "=" .. utils.url_encode(tostring(value))
    }

    if options.maxAge then
        table.insert(parts, "Max-Age=" .. options.maxAge)
    end

    if options.expires then
        if type(options.expires) == "number" then
            -- Convert timestamp to HTTP date
            table.insert(parts, "Expires=" .. os.date("!%a, %d %b %Y %H:%M:%S GMT", options.expires))
        else
            table.insert(parts, "Expires=" .. options.expires)
        end
    end

    table.insert(parts, "Path=" .. (options.path or "/"))

    if options.domain then
        table.insert(parts, "Domain=" .. options.domain)
    end

    if options.secure then
        table.insert(parts, "Secure")
    end

    if options.httpOnly ~= false then
        table.insert(parts, "HttpOnly")
    end

    if options.sameSite then
        table.insert(parts, "SameSite=" .. options.sameSite)
    else
        table.insert(parts, "SameSite=Lax")
    end

    self._cookies[name] = table.concat(parts, "; ")
    return self
end

--- Clear a cookie
---@param name string Cookie name
---@param options table|nil Cookie options
---@return Response self for chaining
function Response:clearCookie(name, options)
    options = options or {}
    options.maxAge = 0
    options.expires = 0
    return self:cookie(name, "", options)
end

--------------------------------------------------------------------------------
-- Response Body
--------------------------------------------------------------------------------

--- Check if response has been sent
---@return boolean
function Response:sent()
    return self._sent
end

--- Send response body
---@param body string|nil Response body
---@return Response self
function Response:send(body)
    if self._sent then
        return self
    end
    self._sent = true

    -- Apply cookies to headers
    for _, cookie in pairs(self._cookies) do
        self:append("Set-Cookie", cookie)
    end

    -- Set context fields for the HTTP server
    self._ctx._status = self._status
    self._ctx._content_type = self._headers["Content-Type"]
    self._ctx._body = body or ""
    self._ctx._headers = self._headers

    return self
end

--- Send JSON response
---@param data any Data to encode as JSON
---@return Response self
function Response:json(data)
    self:type("application/json")
    local encoded = json.encode(data)
    return self:send(encoded)
end

--- Send HTML response
---@param content string HTML content
---@return Response self
function Response:html(content)
    self:type("text/html; charset=utf-8")
    return self:send(content)
end

--- Send plain text response
---@param content string Text content
---@return Response self
function Response:text(content)
    self:type("text/plain; charset=utf-8")
    return self:send(content)
end

--- Send XML response
---@param content string XML content
---@return Response self
function Response:xml(content)
    self:type("application/xml")
    return self:send(content)
end

--------------------------------------------------------------------------------
-- Redirects
--------------------------------------------------------------------------------

--- Redirect to another URL
---@param url string Target URL
---@param status number|nil Status code (default 302)
---@return Response self
function Response:redirect(url, status)
    self:status(status or 302)
    self:set("Location", url)
    return self:send("")
end

--- Redirect back to referer
---@param fallback string Fallback URL if no referer
---@return Response self
function Response:back(fallback)
    local referer = self._ctx.headers and self._ctx.headers["referer"]
    return self:redirect(referer or fallback or "/")
end

--------------------------------------------------------------------------------
-- File Operations
--------------------------------------------------------------------------------

--- Send a file
---@param filepath string Path to file
---@return Response self
function Response:sendFile(filepath)
    local ok, content = pcall(fs.read, filepath)
    if not ok then
        return self:status(404):send("Not Found")
    end

    -- Determine content type from extension
    local ext = utils.get_extension(filepath)
    self:type(utils.get_mime_type(ext))

    return self:send(content)
end

--- Send file as download
---@param filepath string Path to file
---@param filename string|nil Download filename
---@return Response self
function Response:download(filepath, filename)
    filename = filename or filepath:match("([^/\\]+)$") or "download"
    self:set("Content-Disposition", 'attachment; filename="' .. filename .. '"')
    return self:sendFile(filepath)
end

--- Send file inline (for viewing)
---@param filepath string Path to file
---@param filename string|nil Suggested filename
---@return Response self
function Response:inline(filepath, filename)
    filename = filename or filepath:match("([^/\\]+)$") or "file"
    self:set("Content-Disposition", 'inline; filename="' .. filename .. '"')
    return self:sendFile(filepath)
end

--------------------------------------------------------------------------------
-- Content Negotiation
--------------------------------------------------------------------------------

--- Send response based on Accept header
---@param handlers table Format handlers
---@return Response self
function Response:format(handlers)
    local accept = (self._ctx.headers or {})["accept"] or "*/*"

    -- Try each handler
    for mime, handler in pairs(handlers) do
        if mime ~= "default" and (accept:find(mime, 1, true) or accept == "*/*") then
            handler(self)
            return self
        end
    end

    -- Use default handler
    if handlers.default then
        handlers.default(self)
        return self
    end

    -- No acceptable format
    return self:status(406):send("Not Acceptable")
end

--------------------------------------------------------------------------------
-- Error Responses
--------------------------------------------------------------------------------

--- Send validation error response
---@param errs table Validation errors
---@return Response self
function Response:validationError(errs)
    return self:status(422):json(errors.json_validation_error(errs))
end

--- Send error page
---@param status number HTTP status
---@param message string Error message
---@param stack string|nil Stack trace
---@return Response self
function Response:errorPage(status, message, stack)
    local is_production = self.app and self.app._settings.env == "production"
    local version = self.app and self.app._VERSION or "0.2.0"

    local html = errors.render_error_page({
        status = status,
        message = message,
        stack = stack,
        request = self._ctx,
        production = is_production,
        version = version
    })

    return self:status(status):html(html)
end

--- Send JSON error response
---@param status number HTTP status
---@param message string Error message
---@param code string|nil Error code
---@return Response self
function Response:error(status, message, code)
    return self:status(status):json(errors.json_error(status, message, code))
end

--------------------------------------------------------------------------------
-- Cache Control
--------------------------------------------------------------------------------

--- Set Cache-Control header
---@param options string|table Cache options
---@return Response self
function Response:cache(options)
    if type(options) == "string" then
        self:set("Cache-Control", options)
    elseif type(options) == "table" then
        local parts = {}

        if options.public then table.insert(parts, "public") end
        if options.private then table.insert(parts, "private") end
        if options.noCache then table.insert(parts, "no-cache") end
        if options.noStore then table.insert(parts, "no-store") end
        if options.maxAge then table.insert(parts, "max-age=" .. options.maxAge) end
        if options.sMaxAge then table.insert(parts, "s-maxage=" .. options.sMaxAge) end
        if options.mustRevalidate then table.insert(parts, "must-revalidate") end
        if options.immutable then table.insert(parts, "immutable") end

        self:set("Cache-Control", table.concat(parts, ", "))
    end
    return self
end

--- Disable caching
---@return Response self
function Response:noCache()
    return self:cache("no-store, no-cache, must-revalidate, proxy-revalidate")
end

--- Set ETag header
---@param tag string ETag value
---@param weak boolean|nil Whether weak ETag
---@return Response self
function Response:etag(tag, weak)
    local etag = weak and ('W/"' .. tag .. '"') or ('"' .. tag .. '"')
    self:set("ETag", etag)
    return self
end

--- Set Last-Modified header
---@param timestamp number Unix timestamp
---@return Response self
function Response:lastModified(timestamp)
    self:set("Last-Modified", os.date("!%a, %d %b %Y %H:%M:%S GMT", timestamp))
    return self
end

--------------------------------------------------------------------------------
-- Vary Header
--------------------------------------------------------------------------------

--- Add to Vary header
---@param field string|table Header field(s)
---@return Response self
function Response:vary(field)
    local existing = self:get("Vary") or ""
    local fields = existing ~= "" and {existing} or {}

    if type(field) == "table" then
        for _, f in ipairs(field) do
            table.insert(fields, f)
        end
    else
        table.insert(fields, field)
    end

    self:set("Vary", table.concat(fields, ", "))
    return self
end

--------------------------------------------------------------------------------
-- Links
--------------------------------------------------------------------------------

--- Set Link header for pagination/relations
---@param links table Link definitions
---@return Response self
function Response:links(links)
    local parts = {}
    for rel, url in pairs(links) do
        table.insert(parts, '<' .. url .. '>; rel="' .. rel .. '"')
    end
    self:set("Link", table.concat(parts, ", "))
    return self
end

--------------------------------------------------------------------------------
-- Template Rendering
--------------------------------------------------------------------------------

--- Render a template view
---@param name string Template name
---@param data table|nil Data to pass to template
---@return Response self
function Response:render(name, data)
    -- Merge locals with provided data
    local context = {}
    for k, v in pairs(self.locals) do
        context[k] = v
    end
    if data then
        for k, v in pairs(data) do
            context[k] = v
        end
    end

    -- Get view engine from app
    if not self.app or not self.app.views then
        error("No view engine configured. Use app.views:use('vein') first.")
    end

    local html = self.app.views:render(name, context)
    return self:html(html)
end

return response
