# Middleware Patterns

Common middleware patterns for backend services: CORS, authentication, rate limiting, request logging, and more.

## How Middleware Works

Middleware functions run in order before your route handlers. Each receives `req`, `res`, and a `next` function to pass control:

```lua
app:use(function(req, res, next)
    -- do something before the route handler
    next()
    -- do something after the route handler
end)
```

## CORS

Enable Cross-Origin Resource Sharing for API access from browsers:

```lua
-- Use the built-in CORS middleware
app:use(honeymoon.cors())

-- With options
app:use(honeymoon.cors({
    origin = "https://myapp.com",
    methods = "GET, POST, PUT, DELETE",
    headers = "Content-Type, Authorization",
    credentials = true,
    maxAge = 86400,
}))
```

### Custom CORS for Specific Routes

```lua
local api_cors = honeymoon.cors({
    origin = "*",
    methods = "GET, POST",
})

app:use("/api", api_cors)
```

## Authentication

### JWT Token Authentication

```lua
local function auth_middleware(req, res, next)
    local header = req.headers["authorization"]
    if not header then
        return res:status(401):json({ error = "No token provided" })
    end

    local token = header:gsub("^Bearer ", "")

    -- Verify JWT (using crypto for HMAC verification)
    local parts = string.split(token, ".")
    if #parts ~= 3 then
        return res:status(401):json({ error = "Invalid token" })
    end

    local header_b64, payload_b64, signature = parts[1], parts[2], parts[3]
    local expected_sig = crypto.hmac("sha256", JWT_SECRET, header_b64 .. "." .. payload_b64)

    -- Decode payload
    local payload = json.decode(crypto.base64_decode(payload_b64))

    -- Check expiration
    if payload.exp and payload.exp < time.now() then
        return res:status(401):json({ error = "Token expired" })
    end

    req.user = payload
    next()
end

-- Protect all /api routes
app:use("/api", auth_middleware)

-- Or protect specific routes
app:get("/api/profile", auth_middleware, function(req, res)
    res:json({ user = req.user })
end)
```

### API Key Authentication

```lua
local function api_key_auth(req, res, next)
    local key = req.headers["x-api-key"] or req.query.api_key

    if not key then
        return res:status(401):json({ error = "API key required" })
    end

    local valid_key = db:query_row("SELECT * FROM api_keys WHERE key = ? AND active = 1", key)
    if not valid_key then
        return res:status(403):json({ error = "Invalid API key" })
    end

    req.api_client = valid_key
    next()
end
```

## Rate Limiting

Limit requests per client to protect your API:

```lua
local rate_limits = {}

local function rate_limiter(max_requests, window_seconds)
    return function(req, res, next)
        local client_ip = req.headers["x-forwarded-for"] or req.ip or "unknown"
        local now = time.now()
        local window_start = now - window_seconds

        -- Initialize or clean up client entry
        if not rate_limits[client_ip] then
            rate_limits[client_ip] = {}
        end

        -- Remove expired entries
        local requests = rate_limits[client_ip]
        local valid = table.filter(requests, function(t) return t > window_start end)
        rate_limits[client_ip] = valid

        -- Check limit
        if #valid >= max_requests then
            res:header("Retry-After", tostring(window_seconds))
            return res:status(429):json({
                error = "Too many requests",
                retry_after = window_seconds,
            })
        end

        -- Record this request
        table.insert(rate_limits[client_ip], now)

        -- Add rate limit headers
        res:header("X-RateLimit-Limit", tostring(max_requests))
        res:header("X-RateLimit-Remaining", tostring(max_requests - #valid - 1))

        next()
    end
end

-- 100 requests per minute
app:use("/api", rate_limiter(100, 60))

-- Stricter limit for auth endpoints
app:use("/api/auth/login", rate_limiter(5, 60))
```

## Request Logging

### Basic Logger

```lua
app:use(function(req, res, next)
    local start = time.monotonic_ms()
    next()
    local duration = time.monotonic_ms() - start
    print(string.format("[%s] %s %s %dms",
        time.format(time.now()),
        req.method,
        req.path,
        duration
    ))
end)
```

### Structured Logging with Ember

```lua
local ember = require("ember")
local log = ember({
    level = "info",
    name = "api",
    transports = {
        ember.transports.console({ colors = true }),
    },
})

app:use(ember.honeymoon(log))
```

This automatically logs each request with method, path, status code, and response time.

## Request ID

Add a unique ID to each request for tracing:

```lua
app:use(function(req, res, next)
    local request_id = crypto.uuid()
    req.id = request_id
    res:header("X-Request-Id", request_id)
    next()
end)
```

## Request Body Parsing

Parse JSON bodies and make them available as `req.json`:

```lua
local function json_body(req, res, next)
    if req.body and req.headers["content-type"] then
        local ct = req.headers["content-type"]:lower()
        if ct:contains("application/json") then
            local ok, parsed = pcall(json.decode, req.body)
            if ok then
                req.json = parsed
            else
                return res:status(400):json({ error = "Invalid JSON body" })
            end
        end
    end
    next()
end

app:use(json_body)

-- Now routes can use req.json
app:post("/api/users", function(req, res)
    local user = req.json
    -- ...
end)
```

## Security Headers

### Helmet Middleware

HoneyMoon includes a helmet middleware that sets common security headers:

```lua
app:use(honeymoon.helmet())
```

This sets:
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`
- `Strict-Transport-Security` (HSTS)

### Custom Security Headers

```lua
app:use(function(req, res, next)
    res:header("X-Content-Type-Options", "nosniff")
    res:header("X-Frame-Options", "DENY")
    res:header("Content-Security-Policy", "default-src 'self'")
    next()
end)
```

## Response Compression

Compress large JSON responses:

```lua
app:use(function(req, res, next)
    local original_json = res.json
    res.json = function(self, data)
        local body = json.encode(data)
        res:header("Content-Type", "application/json")
        -- Let the HTTP layer handle compression
        self:send(body)
    end
    next()
end)
```

## Middleware Composition

Combine multiple middleware into a reusable stack:

```lua
local function api_middleware()
    return {
        honeymoon.cors(),
        honeymoon.helmet(),
        honeymoon.responseTime(),
        json_body,
        auth_middleware,
        rate_limiter(100, 60),
    }
end

-- Apply all at once
for _, mw in ipairs(api_middleware()) do
    app:use("/api", mw)
end
```

## Route-Specific Middleware

Apply middleware to individual routes:

```lua
-- Public routes (no auth)
app:get("/api/status", function(req, res)
    res:json({ status = "ok" })
end)

-- Protected routes (with auth)
app:get("/api/users", auth_middleware, function(req, res)
    res:json({ data = get_users() })
end)

-- Admin-only routes (auth + role check)
local function admin_only(req, res, next)
    if not req.user or req.user.role ~= "admin" then
        return res:status(403):json({ error = "Admin access required" })
    end
    next()
end

app:delete("/api/users/:id", auth_middleware, admin_only, function(req, res)
    delete_user(req.params.id)
    res:json({ message = "User deleted" })
end)
```

## Next Steps

- [Database Integration](/docs/backend-services/database) - Connect to databases
- [REST APIs](/docs/backend-services/rest-api) - Build CRUD endpoints
- [Configuration](/docs/backend-services/configuration) - Manage secrets and config
