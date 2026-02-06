# REST APIs

Build JSON APIs with HoneyMoon's Express-style routing, middleware pipeline, and built-in validation.

## Quick Start

```lua
local honeymoon = require("honeymoon")
local app = honeymoon.new()

-- Middleware
app:use(honeymoon.cors())
app:use(honeymoon.helmet())
app:use(honeymoon.responseTime())

-- Routes
app:get("/api/status", function(req, res)
    res:json({
        status = "ok",
        version = _COPPERMOON_VERSION,
        uptime = time.monotonic(),
    })
end)

app:listen(3000, function(port)
    print("API running on http://localhost:" .. port)
end)
```

## CRUD Example

A complete CRUD API for a `users` resource with SQLite:

```lua
local honeymoon = require("honeymoon")
local app = honeymoon.new()

local db = sqlite.open("app.db")
db:exec([[
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        created_at TEXT DEFAULT (datetime('now'))
    )
]])

-- List all users
app:get("/api/users", function(req, res)
    local users = db:query("SELECT * FROM users ORDER BY id DESC")
    res:json({ data = users })
end)

-- Get one user
app:get("/api/users/:id", function(req, res)
    local user = db:query_row("SELECT * FROM users WHERE id = ?", req.params.id)
    if not user then
        return res:status(404):json({ error = "User not found" })
    end
    res:json({ data = user })
end)

-- Create user
app:post("/api/users", function(req, res)
    local body = json.decode(req.body)

    if not body.name or not body.email then
        return res:status(400):json({ error = "name and email are required" })
    end

    db:execute("INSERT INTO users (name, email) VALUES (?, ?)", body.name, body.email)
    local id = db:last_insert_id()
    local user = db:query_row("SELECT * FROM users WHERE id = ?", id)

    res:status(201):json({ data = user })
end)

-- Update user
app:put("/api/users/:id", function(req, res)
    local body = json.decode(req.body)
    local existing = db:query_row("SELECT * FROM users WHERE id = ?", req.params.id)

    if not existing then
        return res:status(404):json({ error = "User not found" })
    end

    local name = body.name or existing.name
    local email = body.email or existing.email

    db:execute("UPDATE users SET name = ?, email = ? WHERE id = ?", name, email, req.params.id)
    local user = db:query_row("SELECT * FROM users WHERE id = ?", req.params.id)

    res:json({ data = user })
end)

-- Delete user
app:delete("/api/users/:id", function(req, res)
    local existing = db:query_row("SELECT * FROM users WHERE id = ?", req.params.id)
    if not existing then
        return res:status(404):json({ error = "User not found" })
    end

    db:execute("DELETE FROM users WHERE id = ?", req.params.id)
    res:json({ message = "User deleted" })
end)

app:listen(3000)
```

## JSON Request/Response

### Parsing Request Body

HoneyMoon provides the raw body in `req.body`. Parse JSON with the built-in `json` module:

```lua
app:post("/api/data", function(req, res)
    local body = json.decode(req.body)
    -- body is now a Lua table
end)
```

### JSON Responses

Use `res:json()` to send JSON with the correct `Content-Type` header:

```lua
-- Object response
res:json({ message = "success", count = 42 })

-- Array response
res:json({ data = { "item1", "item2", "item3" } })

-- With status code
res:status(201):json({ id = 1, created = true })
```

## Route Organization

For larger APIs, split routes into separate files using HoneyMoon routers:

```lua
-- routes/users.lua
local honeymoon = require("honeymoon")
local router = honeymoon.Router()

router:get("/", function(req, res)
    res:json({ data = get_all_users() })
end)

router:post("/", function(req, res)
    local body = json.decode(req.body)
    local user = create_user(body)
    res:status(201):json({ data = user })
end)

router:get("/:id", function(req, res)
    local user = get_user(req.params.id)
    if not user then
        return res:status(404):json({ error = "Not found" })
    end
    res:json({ data = user })
end)

return router
```

```lua
-- app.lua
local honeymoon = require("honeymoon")
local app = honeymoon.new()

local userRoutes = require("routes.users")
local authRoutes = require("routes.auth")

app:use("/api/users", userRoutes)
app:use("/api/auth", authRoutes)

app:listen(3000)
```

## Input Validation

Validate request data before processing:

```lua
local function validate_user(body)
    local errors = {}

    if not body.name or #body.name == 0 then
        table.insert(errors, "name is required")
    end

    if not body.email or not body.email:contains("@") then
        table.insert(errors, "valid email is required")
    end

    if body.name and #body.name > 100 then
        table.insert(errors, "name must be 100 characters or less")
    end

    return #errors == 0, errors
end

app:post("/api/users", function(req, res)
    local body = json.decode(req.body)
    local valid, errors = validate_user(body)

    if not valid then
        return res:status(422):json({ errors = errors })
    end

    -- proceed with creation...
end)
```

## Error Handling

Wrap routes with consistent error responses:

```lua
-- Global error handler
app:use(function(err, req, res, next)
    local status = err.status or 500
    local message = err.message or "Internal server error"

    res:status(status):json({
        error = message,
        path = req.path,
        method = req.method,
    })
end)
```

### Structured Error Responses

Use a consistent format across your API:

```lua
local function api_error(res, status, message, details)
    return res:status(status):json({
        error = {
            code = status,
            message = message,
            details = details,
        }
    })
end

-- Usage
app:get("/api/users/:id", function(req, res)
    local user = find_user(req.params.id)
    if not user then
        return api_error(res, 404, "User not found", {
            id = req.params.id
        })
    end
    res:json({ data = user })
end)
```

## Query Parameters

Access query string parameters from `req.query`:

```lua
-- GET /api/users?page=2&limit=10&sort=name
app:get("/api/users", function(req, res)
    local page = tonumber(req.query.page) or 1
    local limit = tonumber(req.query.limit) or 20
    local sort = req.query.sort or "id"

    local offset = (page - 1) * limit
    local users = db:query(
        "SELECT * FROM users ORDER BY " .. sort .. " LIMIT ? OFFSET ?",
        limit, offset
    )
    local total = db:query_row("SELECT COUNT(*) as count FROM users")

    res:json({
        data = users,
        pagination = {
            page = page,
            limit = limit,
            total = total.count,
            pages = math.ceil(total.count / limit),
        }
    })
end)
```

## Response Headers

Set custom headers for API responses:

```lua
-- Set individual header
res:header("X-Request-Id", crypto.uuid())

-- Cache control
res:header("Cache-Control", "public, max-age=3600")

-- No cache for dynamic data
res:header("Cache-Control", "no-store")
```

## Calling External APIs

Use the built-in `http` module to call other services:

```lua
app:get("/api/weather/:city", function(req, res)
    local response = http.get(
        "https://api.weather.example.com/v1/current?city=" .. req.params.city,
        { headers = { ["Authorization"] = "Bearer " .. API_KEY } }
    )

    if not response.ok then
        return res:status(502):json({ error = "Weather service unavailable" })
    end

    local weather = json.decode(response.body)
    res:json({ data = weather })
end)
```

## Next Steps

- [Middleware Patterns](/docs/backend-services/middleware-patterns) - Add CORS, auth, rate limiting
- [Database Integration](/docs/backend-services/database) - SQLite, MySQL, Redis
- [Configuration](/docs/backend-services/configuration) - Manage environment and config
