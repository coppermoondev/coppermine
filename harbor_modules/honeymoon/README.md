# HoneyMoon

> **A complete, production-ready web framework for CopperMoon**

HoneyMoon is an Express.js-inspired web framework built for the CopperMoon Lua runtime. It provides everything you need to build modern web applications and REST APIs: routing with parameters, middleware, request validation, sessions, authentication, security headers, static file serving, template rendering, and more.

## Features

- 🚀 **Express-style API** — familiar `app:get()`, `app:post()`, `app:use()` patterns
- 🛣️ **Powerful routing** — parameters (`:id`), wildcards (`*`), sub-routers, route groups
- 🔌 **Rich middleware** — logger, CORS, body parsers, rate limiting, auth, sessions, security
- ✅ **Request validation** — schema-based validation with type coercion and sanitization
- 🔐 **Authentication** — Basic, Bearer, API Key, and JWT out of the box
- 🛡️ **Security** — Helmet (security headers), CSRF protection, request IDs
- 📁 **Static files** — serve static assets with MIME type detection
- 🎨 **Template rendering** — first-class Vein integration with layouts, partials, components
- 💾 **Sessions** — cookie-based sessions with in-memory store
- ⚡ **Error handling** — custom error handlers, HTML error pages in dev, JSON in production

## Installation

```bash
harbor install honeymoon
```

Or create a new project with HoneyMoon pre-installed:

```bash
shipyard new my-app --template web
```

## Quick Start

```lua
local honeymoon = require("honeymoon")

local app = honeymoon.new()

-- Built-in middleware
app:use(honeymoon.logger())
app:use(honeymoon.cors())
app:use(honeymoon.json())

-- Routes
app:get("/", function(req, res)
    res:html("<h1>Hello, World!</h1>")
end)

app:get("/api/users/:id", function(req, res)
    res:json({ id = req.params.id, name = "Alice" })
end)

app:post("/api/users", function(req, res)
    local data = req:json()
    res:status(201):json({ created = true, user = data })
end)

-- Start server
app:listen(3000)
```

```
HoneyMoon v0.2.0 listening on http://127.0.0.1:3000
```

## Routing

### HTTP Methods

```lua
app:get("/path", handler)
app:post("/path", handler)
app:put("/path", handler)
app:delete("/path", handler)
app:patch("/path", handler)
app:options("/path", handler)
app:head("/path", handler)
app:all("/path", handler)    -- All methods
```

### Route Parameters

```lua
-- Named parameters
app:get("/users/:id", function(req, res)
    local id = req.params.id
    res:json({ id = id })
end)

-- Multiple parameters
app:get("/users/:userId/posts/:postId", function(req, res)
    local userId = req.params.userId
    local postId = req.params.postId
    res:json({ userId = userId, postId = postId })
end)

-- Wildcard
app:get("/files/*", function(req, res)
    local filepath = req.params["*"]
    res:send("File: " .. filepath)
end)
```

### Sub-Routers

```lua
-- Create a modular router
local api = app:router()

api:get("/users", function(req, res)
    res:json({ users = {} })
end)

api:post("/users", function(req, res)
    res:status(201):json({ created = true })
end)

api:get("/users/:id", function(req, res)
    res:json({ id = req.params.id })
end)

-- Mount at prefix
app:mount("/api/v1", api)
-- Routes: GET /api/v1/users, POST /api/v1/users, GET /api/v1/users/:id
```

### Route Chaining

```lua
local router = app:router()

router:routePath("/users")
    :get(listUsers)
    :post(createUser)

router:routePath("/users/:id")
    :get(getUser)
    :put(updateUser)
    :delete(deleteUser)
```

## Middleware

Middleware functions receive `(req, res, next)`. Call `next()` to continue the chain:

```lua
-- Custom middleware
app:use(function(req, res, next)
    local start = time.monotonic_ms()
    next()
    local duration = time.monotonic_ms() - start
    print(req.method, req.path, duration .. "ms")
end)

-- Path-scoped middleware
app:use("/api", function(req, res, next)
    -- Only runs for /api/* routes
    next()
end)
```

### Built-in Middleware

#### Logger

```lua
app:use(honeymoon.logger())
-- GET /users 200 12.3ms
```

#### CORS

```lua
-- Allow all origins
app:use(honeymoon.cors())

-- Custom configuration
app:use(honeymoon.cors({
    origin = "https://example.com",
    methods = "GET,POST,PUT,DELETE",
    headers = "Content-Type,Authorization",
    credentials = true,
    maxAge = 86400,
}))
```

#### Body Parsers

```lua
app:use(honeymoon.json())            -- Parse JSON bodies
app:use(honeymoon.urlencoded())       -- Parse URL-encoded bodies
app:use(honeymoon.bodyParser())       -- Both JSON + URL-encoded
app:use(honeymoon.raw())              -- Raw body
app:use(honeymoon.text())             -- Plain text body
```

#### Static Files

```lua
-- Serve files from ./public
app:use(honeymoon.static("./public"))

-- With path prefix
app:use("/assets", honeymoon.static("./public"))

-- Directory listing
app:use("/files", honeymoon.directory("./uploads"))
```

#### Rate Limiting

```lua
app:use(honeymoon.rateLimit({
    windowMs = 60 * 1000,   -- 1 minute window
    max = 100,               -- 100 requests per window
    message = "Too many requests",
}))
```

#### Authentication

```lua
-- Basic auth
app:use("/admin", honeymoon.basicAuth({
    verify = function(username, password)
        return username == "admin" and password == "secret"
    end,
}))

-- Bearer token
app:use("/api", honeymoon.bearerAuth({
    verify = function(token)
        return validateToken(token)  -- return user table or nil
    end,
}))

-- API key (header, query, or both)
app:use("/api", honeymoon.apiKeyAuth({
    header = "X-API-Key",
    verify = function(key)
        return db:findApiKey(key)
    end,
}))

-- JWT
app:use("/api", honeymoon.jwtAuth({
    secret = "your-secret-key",
}))

-- Role-based access
app:use("/admin", honeymoon.requireAuth())
app:use("/admin", honeymoon.requireRoles({"admin", "moderator"}))
```

#### Sessions

```lua
app:use(honeymoon.session({
    secret = "session-secret",
    name = "sid",
    maxAge = 3600,  -- 1 hour
}))

app:get("/profile", function(req, res)
    local visits = (req.session:get("visits") or 0) + 1
    req.session:set("visits", visits)
    res:json({ visits = visits })
end)

-- Flash messages
app:use(honeymoon.flash())
```

#### Security (Helmet)

```lua
-- All security headers at once
app:use(honeymoon.helmet())

-- Or individually
app:use(honeymoon.helmet({
    hsts = true,
    noSniff = true,
    xssFilter = true,
    frameguard = "DENY",
}))

-- CSRF protection
app:use(honeymoon.csrf())

-- Request ID
app:use(honeymoon.requestId())
```

#### Utility Middleware

```lua
app:use(honeymoon.responseTime())     -- X-Response-Time header
app:use(honeymoon.favicon("./public/favicon.ico"))
app:use(honeymoon.methodOverride())   -- _method override for forms
```

## Request Object

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `req.method` | string | HTTP method (GET, POST, etc.) |
| `req.path` | string | Request path |
| `req.headers` | table | Request headers (lowercase keys) |
| `req.query` | table | Parsed query string parameters |
| `req.params` | table | Route parameters |
| `req.body` | string | Raw request body |
| `req.ip` | string | Client IP (respects X-Forwarded-For) |
| `req.protocol` | string | "http" or "https" |
| `req.hostname` | string | Host header value |
| `req.secure` | boolean | Whether HTTPS |
| `req.xhr` | boolean | Whether XMLHttpRequest |
| `req.session` | table | Session data (if session middleware) |
| `req.user` | table | Authenticated user (if auth middleware) |
| `req.id` | string | Request ID (if requestId middleware) |

### Methods

```lua
-- Headers
req:get("content-type")            -- Get header (case-insensitive)
req:has("authorization")           -- Check if header exists

-- Body parsing
local data = req:json()            -- Parse body as JSON
local form = req:form()            -- Parse body as form data

-- Parameters (checks params → query → body)
local id = req:param("id")
local page = req:param("page", 1)  -- With default

-- Content negotiation
req:accepts("json")                 -- Check Accept header
req:accepts({"json", "html"})
req:is("json")                      -- Check Content-Type

-- Cookies
local cookies = req:cookies()       -- All cookies
local token = req:cookie("token")   -- Single cookie

-- Validation
local data = req:validate(schema)        -- Validate body
local query = req:validateQuery(schema)  -- Validate query params
local params = req:validateParams(schema) -- Validate route params
```

## Response Object

### Status and Headers

```lua
res:status(201)                     -- Set status code
res:set("X-Custom", "value")       -- Set header
res:type("json")                    -- Set Content-Type
res:headers({ ["X-A"] = "1", ["X-B"] = "2" })
```

### Sending Responses

```lua
res:send("Hello")                   -- Plain text
res:json({ key = "value" })        -- JSON
res:html("<h1>Hello</h1>")         -- HTML
res:text("Plain text")             -- text/plain
res:xml("<root/>")                  -- application/xml
```

### Redirects

```lua
res:redirect("/login")              -- 302 redirect
res:redirect("/new-path", 301)      -- 301 redirect
res:back("/fallback")               -- Redirect to referer
```

### Files

```lua
res:sendFile("./public/report.pdf")           -- Serve file
res:download("./files/data.csv", "export.csv") -- Force download
res:inline("./files/preview.pdf")              -- Inline display
```

### Cookies

```lua
res:cookie("token", "abc123", {
    maxAge = 3600,
    httpOnly = true,
    secure = true,
    sameSite = "Strict",
})

res:clearCookie("token")
```

### Caching

```lua
res:cache({ public = true, maxAge = 3600 })
res:noCache()
res:etag("abc123")
res:lastModified(os.time())
```

### Content Negotiation

```lua
res:format({
    ["application/json"] = function(res) res:json({ ok = true }) end,
    ["text/html"] = function(res) res:html("<p>OK</p>") end,
    default = function(res) res:send("OK") end,
})
```

### Template Rendering

```lua
-- Configure view engine (Vein)
app.views:use("vein")
app.views:set("views", "./views")

-- In route handler
res:render("users/profile", {
    user = { name = "Alice", email = "alice@example.com" },
})
```

## Schema Validation

Define schemas for request validation with type coercion and sanitization:

```lua
local userSchema = honeymoon.schema({
    name = {
        type = "string",
        required = true,
        min = 2,
        max = 50,
        trim = true,
    },
    email = {
        type = "email",
        required = true,
        lowercase = true,
        trim = true,
    },
    age = {
        type = "integer",
        minValue = 0,
        maxValue = 150,
    },
    role = {
        type = "string",
        enum = {"user", "admin", "moderator"},
        default = "user",
    },
})

app:post("/users", function(req, res)
    local data = req:validate(userSchema)
    -- data is sanitized and type-coerced
    -- Throws ValidationError (422) on failure
    res:status(201):json(data)
end)
```

### Supported Types

`string`, `number`, `integer`, `boolean`, `email`, `url`, `uuid`, `array`, `object`, `any`

### Schema Composition

```lua
-- Partial (all fields optional)
local updateSchema = userSchema:partial()

-- Extend with additional fields
local adminSchema = userSchema:extend({
    permissions = { type = "array", required = true },
})

-- Pick specific fields
local loginSchema = userSchema:pick({"email", "password"})

-- Omit fields
local publicSchema = userSchema:omit({"password", "role"})
```

### Schema Presets

```lua
local schema = honeymoon.schema({
    email = honeymoon.preset("email"),
    password = honeymoon.preset("password"),
    username = honeymoon.preset("username"),
    limit = honeymoon.preset("limit"),       -- Pagination limit
    offset = honeymoon.preset("offset"),     -- Pagination offset
})
```

## Error Handling

### Custom Error Handler

```lua
app:error(function(err, req, res, stack)
    print("Error:", err)
    res:status(500):json({ error = "Something went wrong" })
end)
```

### HTTP Errors

```lua
app:get("/users/:id", function(req, res)
    local user = findUser(req.params.id)
    if not user then
        error(honeymoon.errors.notFound("User not found"))
    end
    res:json(user)
end)
```

Available error factories: `badRequest`, `unauthorized`, `forbidden`, `notFound`, `methodNotAllowed`, `conflict`, `unprocessable`, `tooManyRequests`, `internal`.

### Validation Errors

Validation errors automatically return a structured 422 response:

```json
{
    "error": "Validation Error",
    "code": "VALIDATION_ERROR",
    "errors": {
        "email": ["must be a valid email address"],
        "name": ["is required"]
    }
}
```

## Sessions

```lua
app:use(honeymoon.session({ secret = "keyboard-cat" }))

app:post("/login", function(req, res)
    local data = req:json()
    local user = authenticate(data.email, data.password)

    if user then
        req.session:set("userId", user.id)
        req.session:set("role", user.role)
        res:json({ success = true })
    else
        res:status(401):json({ error = "Invalid credentials" })
    end
end)

app:post("/logout", function(req, res)
    req.session:destroy()
    res:json({ success = true })
end)
```

### Session API

| Method | Description |
|--------|-------------|
| `session:get(key, default?)` | Get session value |
| `session:set(key, value)` | Set session value |
| `session:has(key)` | Check if key exists |
| `session:forget(key)` | Remove a key |
| `session:all()` | Get all session data |
| `session:flash(key, value)` | Set flash data (next request only) |
| `session:getFlash(key)` | Get flash data |
| `session:destroy()` | Destroy session |
| `session:regenerate(keepData?)` | Regenerate session ID |
| `session:getId()` | Get session ID |

## Application Settings

```lua
app:set("env", "production")
app:set("port", 8080)
app:set("trust_proxy", true)
app:set("views", "./templates")
app:set("json_spaces", 2)

local env = app:get_setting("env")
app:enable("etag")
app:disable("etag")
```

## Utility Functions

```lua
honeymoon.utils.urlEncode(str)
honeymoon.utils.urlDecode(str)
honeymoon.utils.randomString(length)
honeymoon.utils.deepCopy(table)
honeymoon.utils.merge(t1, t2)
honeymoon.utils.isEmail(str)
honeymoon.utils.isUrl(str)
honeymoon.utils.isUuid(str)
honeymoon.utils.getMimeType(ext)
honeymoon.utils.getStatusText(code)
```

## Complete Example

```lua
local honeymoon = require("honeymoon")
local dotenv = require("dotenv")
local ember = require("ember")
local freight = require("freight")

-- Configuration
dotenv.config()
local app = honeymoon.new()
local log = ember({ name = "api" })

-- Database
local db = freight.open("sqlite", { database = "app.db" })
local User = db:model("users", {
    id = { type = "integer", primaryKey = true, autoIncrement = true },
    name = { type = "string", notNull = true },
    email = { type = "string", unique = true },
})
db:autoMigrate(User)

-- Middleware
app:use(honeymoon.logger())
app:use(honeymoon.cors())
app:use(honeymoon.json())
app:use(honeymoon.helmet())

-- Validation schemas
local createUserSchema = honeymoon.schema({
    name = { type = "string", required = true, min = 2, max = 50, trim = true },
    email = honeymoon.preset("email"),
})

-- Routes
app:get("/api/users", function(req, res)
    local users = User:findAll()
    res:json({ users = users })
end)

app:post("/api/users", function(req, res)
    local data = req:validate(createUserSchema)
    local user = User:create(data)
    res:status(201):json({ user = user })
end)

app:get("/api/users/:id", function(req, res)
    local user = User:find(tonumber(req.params.id))
    if not user then
        error(honeymoon.errors.notFound("User not found"))
    end
    res:json({ user = user })
end)

-- Error handler
app:error(function(err, req, res)
    log:error("Unhandled error", { error = tostring(err), path = req.path })
    res:status(500):json({ error = "Internal server error" })
end)

-- Start
local port = dotenv.getNumber("PORT", 3000)
app:listen(port)
```

## Related

- [CopperMoon](https://github.com/coppermoondev/coppermoon) — The Lua runtime
- [Harbor](https://github.com/coppermoondev/harbor) — Package manager (`harbor install honeymoon`)
- [Shipyard](https://github.com/coppermoondev/shipyard) — Project toolchain (`shipyard new my-app --template web`)
- [Vein](https://github.com/coppermoondev/vein) — Templating engine
- [Freight](https://github.com/coppermoondev/freight) — ORM / database
- [Ember](https://github.com/coppermoondev/ember) — Structured logging
- [Lantern](https://github.com/coppermoondev/lantern) — Debug toolbar
- [Tailwind](https://github.com/coppermoondev/tailwind) — TailwindCSS integration
- [Dotenv](https://github.com/coppermoondev/dotenv) — Environment variables

## Documentation

For full documentation, tutorials, and guides, visit [coppermoon.dev](https://coppermoon.dev).

## License

MIT License — CopperMoon Contributors
