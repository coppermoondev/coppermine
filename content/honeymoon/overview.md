# HoneyMoon Framework

HoneyMoon is the web framework for CopperMoon. Inspired by Express.js, it provides a clean, chainable API for building web applications and APIs with routing, middleware, templating, sessions, authentication, and more.

## Features

- **Express-style routing** with parameters and wildcards
- **Middleware system** with 20+ built-in middleware
- **Request & Response** objects with extensive methods
- **Schema validation** with type coercion and sanitization
- **Session management** with in-memory store
- **Authentication** — Basic, Bearer, API Key, JWT
- **Security** — Helmet, CSRF, CORS, rate limiting
- **Static file serving** with caching and ETags
- **Template integration** with Vein
- **Error handling** with dev-mode stack traces

## Quick Start

```lua
local honeymoon = require("honeymoon")
local app = honeymoon.new()

-- Middleware
app:use(honeymoon.logger())
app:use(honeymoon.json())

-- Routes
app:get("/", function(req, res)
    res:send("Hello, CopperMoon!")
end)

app:get("/api/users", function(req, res)
    res:json({ users = {} })
end)

app:post("/api/users", function(req, res)
    local data = req:json()
    res:status(201):json({ created = true, name = data.name })
end)

-- Start server
app:listen(3000, function(port)
    print("Server running on port " .. port)
end)
```

## Creating an Application

```lua
local honeymoon = require("honeymoon")
local app = honeymoon.new()
```

`honeymoon.new()` returns an application instance with all routing, middleware, and configuration methods.

## Configuration

### app:set(key, value)

Set a configuration value:

```lua
app:set("views", "./views")
app:set("env", "production")
app:set("trust_proxy", true)
```

### app:get_setting(key)

Get a configuration value:

```lua
local env = app:get_setting("env")
```

### app:enable(key) / app:disable(key)

Toggle boolean settings:

```lua
app:enable("etag")
app:disable("trust_proxy")
```

### app:enabled(key) / app:disabled(key)

Check boolean settings:

```lua
if app:enabled("etag") then
    print("ETag is enabled")
end
```

### Default Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `port` | `3000` | Server port |
| `host` | `"127.0.0.1"` | Server host |
| `env` | `"development"` | Environment (from NODE_ENV) |
| `trust_proxy` | `false` | Trust X-Forwarded-* headers |
| `json_spaces` | `0` | JSON indentation |
| `etag` | `true` | Generate ETag headers |
| `query_parser` | `"extended"` | Query string parser mode |
| `views` | `"./views"` | Views directory |

## Starting the Server

```lua
-- Basic
app:listen(3000)

-- With callback
app:listen(3000, function(port)
    print("Server started on http://127.0.0.1:" .. port)
end)
```

## View Engine Setup

HoneyMoon integrates with Vein for templating:

```lua
-- Enable Vein
app.views:use("vein")

-- Configure paths
app.views:set("views", "./views")
app.views:set("layouts", "./views/layouts")
app.views:set("partials", "./views/partials")
app.views:set("components", "./views/components")
app.views:set("cache", true)
app.views:set("extension", ".vein")

-- Global template variables
app.views:global("siteName", "My App")
app.views:global({ appVersion = "1.0.0", year = 2025 })

-- Custom filters
app.views:filter("uppercase", function(str)
    return str:upper()
end)

-- Custom helpers
app.views:helper("formatDate", function(timestamp)
    return os.date("%Y-%m-%d", timestamp)
end)

-- Clear template cache
app.views:clearCache()
```

## Static Files

Serve static assets from a directory:

```lua
app:use("/public", honeymoon.static("./public"))
```

See [Security](/docs/honeymoon/security) for static file options.

## Complete Example

```lua
local honeymoon = require("honeymoon")
local app = honeymoon.new()

-- Configuration
app:set("env", os_ext.env("NODE_ENV") or "development")
app:set("views", "./views")
app.views:use("vein")

-- Middleware
app:use(honeymoon.logger())
app:use(honeymoon.json())
app:use(honeymoon.cors())
app:use(honeymoon.helmet())
app:use(honeymoon.session({ secret = "my-secret" }))
app:use("/public", honeymoon.static("./public"))

-- Routes
app:get("/", function(req, res)
    res:render("index", { title = "Home" })
end)

app:get("/api/status", function(req, res)
    res:json({ status = "ok", uptime = os.clock() })
end)

-- Error handler
app:error(function(err, req, res, stack)
    res:status(500):json({ error = "Something went wrong" })
end)

-- Start
app:listen(3000, function(port)
    print("App running on port " .. port)
end)
```

## Next Steps

- [Routing](/docs/honeymoon/routing) — Define routes with parameters and groups
- [Middleware](/docs/honeymoon/middleware) — Built-in and custom middleware
- [Request & Response](/docs/honeymoon/request-response) — Full API reference
- [Validation](/docs/honeymoon/validation) — Schema-based input validation
- [Sessions](/docs/honeymoon/sessions) — Session management
- [Authentication](/docs/honeymoon/authentication) — Basic, Bearer, API Key, JWT
- [Security](/docs/honeymoon/security) — Helmet, CSRF, CORS, rate limiting
- [Error Handling](/docs/honeymoon/error-handling) — Custom error handlers
