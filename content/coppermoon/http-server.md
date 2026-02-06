# HTTP Server

CopperMoon provides a built-in HTTP module for both client requests and server creation.

## HTTP Client

### Making Requests

```lua
-- GET
local resp = http.get("https://api.example.com/users")

-- POST with body
local resp = http.post("https://api.example.com/users", json.encode({
    name = "Alice",
    email = "alice@example.com"
}))

-- PUT
local resp = http.put("https://api.example.com/users/1", json.encode({
    name = "Bob"
}))

-- DELETE
local resp = http.delete("https://api.example.com/users/1")

-- PATCH
local resp = http.patch("https://api.example.com/users/1", json.encode({
    name = "Charlie"
}))
```

### Request Options

Pass an options table as the last argument:

```lua
local resp = http.get("https://api.example.com/data", {
    headers = {
        ["Authorization"] = "Bearer token123",
        ["Accept"] = "application/json",
    },
    timeout = 5000,   -- milliseconds
})

local resp = http.post("https://api.example.com/data", body, {
    headers = {
        ["Content-Type"] = "application/json",
    },
    cookies = {
        ["session"] = "abc123",
    },
})
```

| Option | Type | Description |
|--------|------|-------------|
| `headers` | table | Key-value pairs of HTTP headers |
| `timeout` | integer | Request timeout in milliseconds |
| `cookies` | table | Key-value pairs of cookies to send |

### Generic Request

For full control, use `http.request()`:

```lua
local resp = http.request({
    method = "POST",
    url = "https://api.example.com/data",
    body = json.encode({ key = "value" }),
    headers = {
        ["Content-Type"] = "application/json",
    },
    timeout = 10000,
})
```

### Response Object

All request functions return a response table:

| Field | Type | Description |
|-------|------|-------------|
| `status` | integer | HTTP status code (200, 404, etc.) |
| `status_text` | string | Status text ("OK", "Not Found", etc.) |
| `body` | string | Response body |
| `ok` | boolean | `true` if status is 200-299 |
| `url` | string | Final URL (after redirects) |
| `headers` | table | Response headers |
| `cookies` | table | Set-Cookie headers (parsed) |

```lua
local resp = http.get("https://api.example.com/users")

if resp.ok then
    local users = json.decode(resp.body)
    for _, user in ipairs(users) do
        print(user.name)
    end
else
    print("Error:", resp.status, resp.status_text)
end
```

### HTTP Sessions

Create a persistent session that maintains cookies across requests:

```lua
local session = http.create_session()

-- Login (cookies are saved)
session:post("https://example.com/login", json.encode({
    username = "alice",
    password = "secret"
}))

-- Subsequent requests include session cookies
local resp = session:get("https://example.com/profile")

-- Manual cookie management
session:set_cookie("theme", "dark")
local theme = session:get_cookie("theme")
local all = session:get_cookies()
session:clear_cookies()
```

Session methods: `get()`, `post()`, `put()`, `delete()` — same signatures as the global `http` functions.

## HTTP Server

### Creating a Server

```lua
local server = http.server.new()

server:get("/", function(ctx)
    return ctx:html("<h1>Hello!</h1>")
end)

server:listen(3000, function(port)
    print("Listening on port " .. port)
end)
```

### Route Methods

```lua
server:get(path, handler)
server:post(path, handler)
server:put(path, handler)
server:delete(path, handler)
```

Routes match the exact path. The handler function receives a context object.

### Context Object

The handler's context provides request data and response methods:

#### Request Data

| Field | Type | Description |
|-------|------|-------------|
| `ctx.method` | string | HTTP method (`"GET"`, `"POST"`, etc.) |
| `ctx.path` | string | Request path |
| `ctx.body` | string | Request body |
| `ctx.headers` | table | Request headers (key-value) |
| `ctx.query` | table | URL query parameters (decoded) |

#### Response Methods

| Method | Description |
|--------|-------------|
| `ctx:status(code)` | Set HTTP status code (returns `ctx` for chaining) |
| `ctx:json(data)` | Send JSON response |
| `ctx:text(string)` | Send plain text response |
| `ctx:html(string)` | Send HTML response |

Methods can be chained:

```lua
ctx:status(201):json({ created = true })
ctx:status(404):text("Not Found")
```

### Complete Example

```lua
local server = http.server.new()

-- HTML page
server:get("/", function(ctx)
    return ctx:html([[
        <h1>My API</h1>
        <p>Welcome to the API.</p>
    ]])
end)

-- JSON endpoint
server:get("/api/status", function(ctx)
    return ctx:json({
        status = "ok",
        version = _COPPERMOON_VERSION,
        uptime = time.monotonic(),
    })
end)

-- Query parameters
server:get("/api/search", function(ctx)
    local query = ctx.query.q or ""
    local results = searchDatabase(query)
    return ctx:json({ query = query, results = results })
end)

-- POST with JSON body
server:post("/api/users", function(ctx)
    local ok, data = pcall(json.decode, ctx.body)
    if not ok or not data.name then
        return ctx:status(400):json({ error = "Invalid request" })
    end

    local user = createUser(data)
    return ctx:status(201):json(user)
end)

-- Request headers
server:get("/api/me", function(ctx)
    local token = ctx.headers["authorization"]
    if not token then
        return ctx:status(401):json({ error = "Unauthorized" })
    end

    local user = getUserByToken(token)
    return ctx:json(user)
end)

-- 404 handler (wildcard — place last)
server:get("*", function(ctx)
    return ctx:status(404):json({ error = "Not found" })
end)

server:listen(3000, function(port)
    print("API running on http://localhost:" .. port)
end)
```

### Note on HoneyMoon

The built-in `http.server` is a low-level server. For full web applications with routing, middleware, templating, and sessions, use [HoneyMoon](/docs/honeymoon/overview) which provides an Express.js-style API on top of CopperMoon.
