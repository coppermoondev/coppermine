# Middleware

Middleware functions run before route handlers. They can modify the request and response, end the request-response cycle, or pass control to the next middleware.

## How Middleware Works

Each middleware function receives three arguments:

```lua
function(req, res, next)
    -- Do something with req/res
    next()  -- Pass control to next middleware
end
```

- Call `next()` to continue to the next middleware or route handler
- Send a response (e.g., `res:send()`, `res:json()`) to stop the chain
- If neither is done, the request hangs

### Execution Order

1. Global middleware runs first (in the order registered)
2. Path-specific middleware runs if the path matches
3. Route handler executes

## Adding Middleware

### Global Middleware

Applies to all routes:

```lua
app:use(function(req, res, next)
    print(req.method .. " " .. req.path)
    next()
end)
```

### Path-Specific Middleware

Applies to routes matching a path prefix:

```lua
app:use("/api", function(req, res, next)
    -- Runs for /api, /api/users, /api/posts/1, etc.
    next()
end)
```

### Multiple Middleware

```lua
app:use(honeymoon.logger())
app:use(honeymoon.json())
app:use(honeymoon.cors())
app:use(honeymoon.helmet())
```

## Built-in Middleware

HoneyMoon ships with middleware for common tasks.

### Body Parsers

#### honeymoon.json(options?)

Parse JSON request bodies:

```lua
app:use(honeymoon.json())

app:post("/api/data", function(req, res)
    local data = req:json()  -- Parsed body
    res:json({ received = data })
end)
```

#### honeymoon.urlencoded(options?)

Parse URL-encoded form bodies (supports nested data):

```lua
app:use(honeymoon.urlencoded())

app:post("/form", function(req, res)
    local data = req:form()
    res:send("Name: " .. data.name)
end)
```

#### honeymoon.text(options?)

Parse plain text bodies:

```lua
app:use(honeymoon.text())
```

#### honeymoon.raw(options?)

Parse raw binary bodies:

```lua
app:use(honeymoon.raw())
```

#### honeymoon.bodyParser(options?)

Combined JSON + URL-encoded parser:

```lua
app:use(honeymoon.bodyParser())
```

### Logger

#### honeymoon.logger(options?)

Log HTTP requests with colors and configurable format:

```lua
-- Default format
app:use(honeymoon.logger())

-- Predefined format
app:use(honeymoon.logger("combined"))

-- Custom options
app:use(honeymoon.logger({
    format = ":method :path :status :response-time ms",
    colors = true,
    immediate = false,
    stream = print,
    skip = function(req, res)
        return req.path:match("^/health")
    end,
}))
```

| Option | Default | Description |
|--------|---------|-------------|
| `format` | `"dev"` | Format string or name |
| `colors` | `true` | Enable ANSI colors |
| `immediate` | `false` | Log before response |
| `stream` | `print` | Output function |
| `skip` | `nil` | Function to skip logging |

#### Predefined Formats

| Name | Output |
|------|--------|
| `dev` | Colored method, path, status, response time |
| `combined` | Apache combined log format |
| `common` | Apache common log format |
| `short` | Short format |
| `tiny` | Minimal format |

#### Format Tokens

| Token | Value |
|-------|-------|
| `:method` | HTTP method (GET, POST, etc.) |
| `:path` | Request path |
| `:url` | Full URL with query string |
| `:status` | Response status code |
| `:response-time` | Response time in ms |
| `:content-length` | Response body size |
| `:date` | Current date/time |
| `:ip` / `:remote-addr` | Client IP address |
| `:user-agent` | User-Agent header |
| `:referrer` | Referer header |
| `:http-version` | HTTP version |

### Response Time

#### honeymoon.responseTime(options?)

Add `X-Response-Time` header:

```lua
app:use(honeymoon.responseTime())

app:use(honeymoon.responseTime({
    header = "X-Response-Time",  -- Header name
    suffix = true,               -- Append "ms"
}))
```

### Request ID

#### honeymoon.requestId(options?)

Add a unique ID to each request:

```lua
app:use(honeymoon.requestId())

app:get("/", function(req, res)
    print("Request ID: " .. req.id)
end)
```

| Option | Default | Description |
|--------|---------|-------------|
| `header` | `"X-Request-ID"` | Header name |
| `generator` | Random 32-char string | Custom ID function |

### Favicon

#### honeymoon.favicon(path)

Serve a favicon:

```lua
app:use(honeymoon.favicon("./public/favicon.ico"))
```

### Method Override

#### honeymoon.methodOverride(options?)

Allow method override via header or query parameter (for clients that don't support PUT/DELETE):

```lua
app:use(honeymoon.methodOverride())
```

### Flash Messages

#### honeymoon.flash()

Enable flash message helpers (requires session middleware):

```lua
app:use(honeymoon.session({ secret = "secret" }))
app:use(honeymoon.flash())

app:post("/login", function(req, res)
    req.session:flash("success", "You are now logged in!")
    res:redirect("/dashboard")
end)

app:get("/dashboard", function(req, res)
    local message = req.session:getFlash("success")
    res:render("dashboard", { flash = message })
end)
```

## Creating Custom Middleware

### Simple Middleware

```lua
local function requestTimer(req, res, next)
    local start = os.clock()
    next()
    local elapsed = (os.clock() - start) * 1000
    print(string.format("[%s] %s %s - %.2fms", os.date(), req.method, req.path, elapsed))
end

app:use(requestTimer)
```

### Configurable Middleware

Return a middleware function from a factory:

```lua
local function requireRole(role)
    return function(req, res, next)
        if not req.user then
            return res:status(401):json({ error = "Not authenticated" })
        end
        if req.user.role ~= role then
            return res:status(403):json({ error = "Insufficient permissions" })
        end
        next()
    end
end

app:use("/admin", requireRole("admin"))
```

### Middleware as Module

```lua
-- middleware/api_logger.lua
local function apiLogger(options)
    options = options or {}
    local log = options.log or print

    return function(req, res, next)
        log(string.format("[API] %s %s from %s", req.method, req.path, req.ip))
        next()
    end
end

return apiLogger

-- app.lua
local apiLogger = require("middleware.api_logger")
app:use("/api", apiLogger({ log = myLogger }))
```

## Middleware Order

The order middleware is registered matters. A typical setup:

```lua
-- 1. Request ID (first, so all logs include it)
app:use(honeymoon.requestId())

-- 2. Logger (log all requests)
app:use(honeymoon.logger())

-- 3. Response time
app:use(honeymoon.responseTime())

-- 4. Security headers
app:use(honeymoon.helmet())

-- 5. CORS
app:use(honeymoon.cors())

-- 6. Body parsers
app:use(honeymoon.json())
app:use(honeymoon.urlencoded())

-- 7. Session
app:use(honeymoon.session({ secret = "secret" }))

-- 8. CSRF protection
app:use(honeymoon.csrf())

-- 9. Static files
app:use("/public", honeymoon.static("./public"))

-- 10. Routes come last
app:get("/", handler)
```

## Built-in Middleware Reference

| Middleware | Description |
|------------|-------------|
| `honeymoon.json()` | Parse JSON bodies |
| `honeymoon.urlencoded()` | Parse URL-encoded bodies |
| `honeymoon.text()` | Parse text bodies |
| `honeymoon.raw()` | Parse raw bodies |
| `honeymoon.bodyParser()` | Combined JSON + URL-encoded |
| `honeymoon.logger()` | Request logging |
| `honeymoon.responseTime()` | X-Response-Time header |
| `honeymoon.requestId()` | Unique request IDs |
| `honeymoon.favicon()` | Serve favicon |
| `honeymoon.methodOverride()` | HTTP method override |
| `honeymoon.flash()` | Flash messages |
| `honeymoon.static()` | Static file serving |
| `honeymoon.directory()` | Static files + directory listing |
| `honeymoon.cors()` | CORS headers |
| `honeymoon.helmet()` | Security headers |
| `honeymoon.csrf()` | CSRF protection |
| `honeymoon.rateLimit()` | Rate limiting |
| `honeymoon.session()` | Session management |
| `honeymoon.basicAuth()` | Basic HTTP auth |
| `honeymoon.bearerAuth()` | Bearer token auth |
| `honeymoon.apiKeyAuth()` | API key auth |
| `honeymoon.jwtAuth()` | JWT auth |
| `honeymoon.compression()` | Response compression |
| `honeymoon.timeout()` | Request timeout |

See [Security](/docs/honeymoon/security), [Sessions](/docs/honeymoon/sessions), and [Authentication](/docs/honeymoon/authentication) for details on those middleware.
