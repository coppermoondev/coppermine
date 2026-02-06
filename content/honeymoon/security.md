# Security

HoneyMoon includes built-in middleware for securing your application: security headers (Helmet), CORS, CSRF protection, rate limiting, and static file serving with protections.

## Helmet (Security Headers)

Helmet sets various HTTP headers to protect against common web vulnerabilities.

### Quick Start

```lua
-- Apply all defaults
app:use(honeymoon.helmet())
```

### Options

```lua
app:use(honeymoon.helmet({
    -- X-Content-Type-Options: nosniff
    noSniff = true,

    -- X-Frame-Options
    frameguard = "SAMEORIGIN",   -- "DENY", "SAMEORIGIN", "ALLOW-FROM uri"

    -- X-XSS-Protection
    xssFilter = true,

    -- Strict-Transport-Security (HSTS)
    hsts = {
        maxAge = 31536000,          -- 1 year
        includeSubDomains = true,
        preload = true,
    },

    -- Content-Security-Policy
    contentSecurityPolicy = {
        ["default-src"] = { "'self'" },
        ["script-src"] = { "'self'", "'unsafe-inline'" },
        ["style-src"] = { "'self'", "https://fonts.googleapis.com" },
        ["img-src"] = { "'self'", "data:", "https:" },
        ["font-src"] = { "'self'", "https://fonts.gstatic.com" },
        ["connect-src"] = { "'self'" },
    },

    -- Referrer-Policy
    referrerPolicy = "strict-origin-when-cross-origin",

    -- Permissions-Policy
    permissionsPolicy = {
        camera = false,
        microphone = false,
        geolocation = { "self" },
    },

    -- Hide X-Powered-By
    hidePoweredBy = true,
}))
```

### Individual Middleware

Apply specific security headers individually:

```lua
app:use(honeymoon.noSniff())
app:use(honeymoon.frameguard("DENY"))
app:use(honeymoon.xssFilter())
app:use(honeymoon.hidePoweredBy())

app:use(honeymoon.hsts({
    maxAge = 31536000,
    includeSubDomains = true,
}))

app:use(honeymoon.csp("default-src 'self'"))
app:use(honeymoon.cspReportOnly("default-src 'self'"))

app:use(honeymoon.referrerPolicy("no-referrer"))

app:use(honeymoon.permissionsPolicy({
    microphone = false,
    camera = false,
}))
```

### Headers Set by Helmet

| Header | Default | Purpose |
|--------|---------|---------|
| `X-Content-Type-Options` | `nosniff` | Prevent MIME type sniffing |
| `X-Frame-Options` | `SAMEORIGIN` | Prevent clickjacking |
| `X-XSS-Protection` | `1; mode=block` | XSS filter (legacy browsers) |
| `Strict-Transport-Security` | `max-age=31536000` | Force HTTPS |
| `Content-Security-Policy` | `default-src 'self'` | Control resource loading |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Control referrer info |
| `Permissions-Policy` | varies | Restrict browser features |
| `X-Powered-By` | removed | Hide server identity |

## CORS

Cross-Origin Resource Sharing controls which origins can access your API.

### Quick Start

```lua
-- Allow all origins
app:use(honeymoon.cors())
```

### Options

```lua
app:use(honeymoon.cors({
    origin = "https://example.com",
    methods = "GET,POST,PUT,DELETE",
    allowedHeaders = "Content-Type,Authorization",
    exposedHeaders = "X-Total-Count",
    credentials = true,
    maxAge = 86400,
    preflightContinue = false,
    optionsSuccessStatus = 204,
}))
```

| Option | Default | Description |
|--------|---------|-------------|
| `origin` | `"*"` | Allowed origin(s) — string, array, or function |
| `methods` | `"GET,HEAD,PUT,PATCH,POST,DELETE"` | Allowed methods |
| `allowedHeaders` | mirrors request | Allowed request headers |
| `exposedHeaders` | `nil` | Headers exposed to the client |
| `credentials` | `false` | Allow credentials (cookies, auth) |
| `maxAge` | `nil` | Preflight cache time in seconds |
| `preflightContinue` | `false` | Pass preflight to next handler |
| `optionsSuccessStatus` | `204` | Status for successful OPTIONS |

### Multiple Origins

```lua
app:use(honeymoon.cors({
    origin = { "https://app.example.com", "https://admin.example.com" },
}))
```

### Dynamic Origin

```lua
app:use(honeymoon.cors({
    origin = function(origin)
        if origin and origin:match("%.example%.com$") then
            return true
        end
        return false
    end,
}))
```

### Convenience Helpers

```lua
-- Allow everything
app:use(honeymoon.cors.allowAll())

-- Allow specific origins
app:use(honeymoon.cors.origins({ "https://example.com" }))
```

## CSRF Protection

Cross-Site Request Forgery protection for form-based applications.

### Setup

```lua
app:use(honeymoon.session({ secret = "secret" }))
app:use(honeymoon.csrf({
    cookie = "_csrf",
    header = "x-csrf-token",
    field = "_csrf",
}))
```

| Option | Default | Description |
|--------|---------|-------------|
| `cookie` | `"_csrf"` | Cookie name for the token |
| `header` | `"x-csrf-token"` | Header to check for the token |
| `field` | `"_csrf"` | Form field name to check |
| `secret` | `nil` | Secret for signing (optional) |

### How It Works

1. CSRF middleware generates a token for each session
2. The token is available as `req:csrfToken()` and `res.locals.csrfToken`
3. For non-safe methods (POST, PUT, DELETE, PATCH), the middleware verifies the token
4. The token is checked in the request body field, header, or query parameter

### Usage in Templates

Include the CSRF token in HTML forms:

```html
<form method="POST" action="/profile">
    <input type="hidden" name="_csrf" value="{{ csrfToken }}">
    <input type="text" name="name">
    <button type="submit">Update</button>
</form>
```

### Usage in AJAX

Include the token in request headers:

```javascript
fetch("/api/data", {
    method: "POST",
    headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
    },
    body: JSON.stringify(data),
})
```

## Rate Limiting

Protect against brute force and abuse with request rate limiting.

### Quick Start

```lua
app:use(honeymoon.rateLimit({
    windowMs = 60000,   -- 1 minute window
    max = 100,          -- 100 requests per window
}))
```

### Options

```lua
app:use(honeymoon.rateLimit({
    windowMs = 60000,
    max = 100,
    message = "Too many requests, please try again later",
    statusCode = 429,
    headers = true,
    legacyHeaders = true,
    standardHeaders = true,
    skipSuccessfulRequests = false,
    skipFailedRequests = false,
    keyGenerator = function(req)
        return req.ip
    end,
    skip = function(req)
        return req.user and req.user.role == "admin"
    end,
    handler = function(req, res, next, options)
        res:status(options.statusCode):json({
            error = "Too Many Requests",
            message = options.message,
            retryAfter = math.ceil(options.windowMs / 1000),
        })
    end,
}))
```

| Option | Default | Description |
|--------|---------|-------------|
| `windowMs` | `60000` | Time window in milliseconds |
| `max` | `100` | Max requests per window |
| `message` | `"Too many requests"` | Error message |
| `statusCode` | `429` | HTTP status when limited |
| `headers` | `true` | Send rate limit headers |
| `legacyHeaders` | `true` | Send `X-RateLimit-*` headers |
| `standardHeaders` | `true` | Send `RateLimit-*` headers |
| `skipSuccessfulRequests` | `false` | Don't count 2xx responses |
| `skipFailedRequests` | `false` | Don't count 4xx/5xx responses |
| `keyGenerator` | `req.ip` | Function to generate rate limit key |
| `skip` | `nil` | Function to skip rate limiting |
| `handler` | default | Custom handler when limit exceeded |
| `store` | memory | Custom store |

### Rate Limit Headers

When a client makes a request, these headers are returned:

| Header | Description |
|--------|-------------|
| `X-RateLimit-Limit` | Maximum requests allowed |
| `X-RateLimit-Remaining` | Remaining requests in window |
| `X-RateLimit-Reset` | Unix timestamp when window resets |
| `Retry-After` | Seconds until limit resets (when limited) |

### Convenience Helpers

```lua
-- Simple sliding window
app:use(honeymoon.rateLimit.sliding(100, 60))  -- 100 req per 60 sec

-- Rate limit by authenticated user
app:use(honeymoon.rateLimit.byUser({
    windowMs = 60000,
    max = 1000,
}))

-- Rate limit by API key
app:use(honeymoon.rateLimit.byApiKey("x-api-key", {
    windowMs = 60000,
    max = 500,
}))
```

### Route-Specific Rate Limits

Apply stricter limits to sensitive endpoints:

```lua
local loginLimiter = honeymoon.rateLimit({
    windowMs = 15 * 60 * 1000,  -- 15 minutes
    max = 5,                     -- 5 attempts
    message = "Too many login attempts, try again in 15 minutes",
})

app:post("/login", loginLimiter, function(req, res)
    -- Login handler
end)

local apiLimiter = honeymoon.rateLimit({
    windowMs = 60000,
    max = 30,
})

app:use("/api", apiLimiter)
```

## Static File Security

Serve static files with security protections.

### honeymoon.static(root, options?)

```lua
app:use("/public", honeymoon.static("./public", {
    index = "index.html",
    dotfiles = "ignore",
    etag = true,
    maxAge = 86400,
    immutable = false,
    lastModified = true,
    redirect = true,
    extensions = { "html", "js" },
}))
```

| Option | Default | Description |
|--------|---------|-------------|
| `index` | `"index.html"` | Directory index file |
| `dotfiles` | `"ignore"` | Handle dotfiles: `"ignore"`, `"allow"`, `"deny"` |
| `etag` | `true` | Generate ETag headers |
| `maxAge` | `0` | Cache-Control max-age in seconds |
| `immutable` | `false` | Add `immutable` flag to Cache-Control |
| `lastModified` | `true` | Set Last-Modified header |
| `redirect` | `true` | Redirect directories to trailing slash |
| `extensions` | `nil` | Try extensions when file not found |

### Security Features

- **Directory traversal prevention**: Blocks `..` in paths and system directories
- **Dotfile handling**: Ignores hidden files by default
- **ETag / If-None-Match**: Returns 304 Not Modified when possible
- **Range requests**: Supports partial content (206)

### honeymoon.directory(root, options?)

Serve static files with directory listing:

```lua
app:use("/files", honeymoon.directory("./uploads", {
    hidden = false,  -- Don't show hidden files
}))
```

## Complete Example

```lua
local honeymoon = require("honeymoon")
local app = honeymoon.new()

-- Security headers
app:use(honeymoon.helmet({
    hsts = { maxAge = 31536000, includeSubDomains = true },
    contentSecurityPolicy = {
        ["default-src"] = { "'self'" },
        ["script-src"] = { "'self'" },
        ["style-src"] = { "'self'", "'unsafe-inline'" },
        ["img-src"] = { "'self'", "data:" },
    },
}))

-- CORS for API
app:use("/api", honeymoon.cors({
    origin = { "https://app.example.com" },
    credentials = true,
    maxAge = 86400,
}))

-- Global rate limit
app:use(honeymoon.rateLimit({
    windowMs = 60000,
    max = 100,
}))

-- Stricter limit for auth endpoints
local authLimiter = honeymoon.rateLimit({
    windowMs = 15 * 60 * 1000,
    max = 10,
    message = "Too many attempts",
})
app:post("/login", authLimiter, loginHandler)
app:post("/register", authLimiter, registerHandler)

-- Body parsing
app:use(honeymoon.json())
app:use(honeymoon.urlencoded())

-- Sessions + CSRF
app:use(honeymoon.session({
    secret = os_ext.env("SESSION_SECRET"),
    cookie = {
        httpOnly = true,
        secure = true,
        sameSite = "Strict",
    },
}))
app:use(honeymoon.csrf())

-- Static files with caching
app:use("/public", honeymoon.static("./public", {
    maxAge = 86400 * 30,
    immutable = true,
}))

-- Routes
app:get("/", function(req, res)
    res:render("index", { csrfToken = req:csrfToken() })
end)

app:listen(3000)
```
