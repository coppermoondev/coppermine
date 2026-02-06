# Sessions

HoneyMoon provides session middleware for managing user state across requests. Sessions are stored server-side with a session ID cookie sent to the client.

## Setup

```lua
app:use(honeymoon.session({
    name = "honeymoon.sid",
    secret = "your-secret-key",
    ttl = 86400,
    cookie = {
        path = "/",
        httpOnly = true,
        secure = false,
        sameSite = "Lax",
    },
}))
```

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `name` | `"honeymoon.sid"` | Session cookie name |
| `secret` | `nil` | Secret for signing (future use) |
| `ttl` | `86400` (24h) | Session lifetime in seconds |
| `rolling` | `false` | Refresh expiry on each request |
| `resave` | `false` | Save session even if unmodified |
| `saveUninitialized` | `false` | Save new sessions that have no data |
| `store` | `MemoryStore` | Session store implementation |
| `cookie` | `{}` | Cookie options (see below) |

### Cookie Options

| Option | Default | Description |
|--------|---------|-------------|
| `path` | `"/"` | Cookie path |
| `httpOnly` | `true` | Prevent JavaScript access |
| `secure` | `false` | HTTPS only |
| `sameSite` | `"Lax"` | `"Strict"`, `"Lax"`, or `"None"` |
| `maxAge` | `nil` | Overrides `ttl` for the cookie |
| `domain` | `nil` | Cookie domain |

## Reading and Writing Data

### Direct Property Access

```lua
-- Set a value
req.session.userId = 42
req.session.username = "Alice"
req.session.role = "admin"

-- Read a value
local userId = req.session.userId
local username = req.session.username
```

### session:set(key, value)

```lua
req.session:set("theme", "dark")
req.session:set("lang", "fr")
```

### session:get(key, default?)

Get a value with an optional default:

```lua
local theme = req.session:get("theme", "light")
local lang = req.session:get("lang", "en")
```

### session:has(key)

Check if a key exists:

```lua
if req.session:has("userId") then
    -- User is logged in
end
```

### session:all()

Get a copy of all session data:

```lua
local data = req.session:all()
for key, value in pairs(data) do
    print(key .. " = " .. tostring(value))
end
```

### session:forget(key)

Delete a specific key:

```lua
req.session:forget("tempData")
```

## Flash Messages

Flash messages are session values that persist for only one request. They are useful for displaying success or error messages after a redirect.

### session:flash(key, value)

Set a flash message:

```lua
app:post("/login", function(req, res)
    local data = req:form()
    local user = authenticate(data.username, data.password)
    if user then
        req.session.userId = user.id
        req.session:flash("success", "Welcome back, " .. user.name .. "!")
        res:redirect("/dashboard")
    else
        req.session:flash("error", "Invalid credentials")
        res:redirect("/login")
    end
end)
```

### session:getFlash(key)

Retrieve and remove a flash message:

```lua
app:get("/dashboard", function(req, res)
    local success = req.session:getFlash("success")
    local error = req.session:getFlash("error")
    res:render("dashboard", {
        flash = { success = success, error = error },
    })
end)
```

### session:clearFlash()

Clear all flash messages:

```lua
req.session:clearFlash()
```

## Session Lifecycle

### session:save()

Manually save the session (normally automatic):

```lua
req.session:save()
```

### session:destroy()

Destroy the session and clear the cookie:

```lua
app:post("/logout", function(req, res)
    req.session:destroy()
    res:redirect("/login")
end)
```

### session:regenerate(keepData?)

Generate a new session ID. Pass `true` to keep existing data:

```lua
-- After login, regenerate to prevent session fixation
app:post("/login", function(req, res)
    local user = authenticate(req:form())
    if user then
        req.session:regenerate(true)  -- New ID, keep data
        req.session.userId = user.id
        res:redirect("/dashboard")
    end
end)
```

### session:getId()

Get the current session ID:

```lua
local id = req.session:getId()
```

## Session Store

By default, HoneyMoon uses an in-memory store. You can implement a custom store for production use (e.g., database-backed, Redis-backed).

### MemoryStore

```lua
local store = honeymoon.MemoryStore()

app:use(honeymoon.session({
    store = store,
    secret = "secret",
}))
```

### Store Interface

A custom store must implement these methods:

| Method | Description |
|--------|-------------|
| `store:get(id)` | Return session data or nil |
| `store:set(id, data, ttl)` | Store data with TTL in seconds |
| `store:destroy(id)` | Delete a session |
| `store:touch(id, ttl)` | Refresh session expiry |
| `store:exists(id)` | Check if session exists |
| `store:all()` | Return all session IDs |
| `store:length()` | Count active sessions |
| `store:clear()` | Delete all sessions |

### Custom Store Example

```lua
local DatabaseStore = {}
DatabaseStore.__index = DatabaseStore

function DatabaseStore.new(db)
    return setmetatable({ db = db }, DatabaseStore)
end

function DatabaseStore:get(id)
    local row = self.db:query_row(
        "SELECT data FROM sessions WHERE id = ? AND expires_at > ?",
        id, os.time()
    )
    if row then
        return json.decode(row.data)
    end
    return nil
end

function DatabaseStore:set(id, data, ttl)
    local expires = os.time() + ttl
    self.db:execute(
        "INSERT OR REPLACE INTO sessions (id, data, expires_at) VALUES (?, ?, ?)",
        id, json.encode(data), expires
    )
end

function DatabaseStore:destroy(id)
    self.db:execute("DELETE FROM sessions WHERE id = ?", id)
end

function DatabaseStore:touch(id, ttl)
    self.db:execute(
        "UPDATE sessions SET expires_at = ? WHERE id = ?",
        os.time() + ttl, id
    )
end

function DatabaseStore:exists(id)
    local row = self.db:query_row(
        "SELECT 1 FROM sessions WHERE id = ? AND expires_at > ?",
        id, os.time()
    )
    return row ~= nil
end

function DatabaseStore:all()
    local rows = self.db:query("SELECT id FROM sessions WHERE expires_at > ?", os.time())
    local ids = {}
    for _, row in ipairs(rows) do
        ids[#ids + 1] = row.id
    end
    return ids
end

function DatabaseStore:length()
    local row = self.db:query_row(
        "SELECT COUNT(*) as count FROM sessions WHERE expires_at > ?", os.time()
    )
    return row.count
end

function DatabaseStore:clear()
    self.db:execute("DELETE FROM sessions")
end

-- Usage
app:use(honeymoon.session({
    store = DatabaseStore.new(db),
    secret = "secret",
    ttl = 86400,
}))
```

## Complete Example

```lua
local honeymoon = require("honeymoon")
local app = honeymoon.new()

app:use(honeymoon.json())
app:use(honeymoon.urlencoded())
app:use(honeymoon.session({
    name = "app.sid",
    secret = os_ext.env("SESSION_SECRET") or "dev-secret",
    ttl = 86400 * 7,   -- 7 days
    rolling = true,     -- Refresh on each request
    cookie = {
        httpOnly = true,
        secure = app:get_setting("env") == "production",
        sameSite = "Lax",
    },
}))
app:use(honeymoon.flash())

-- Login
app:post("/login", function(req, res)
    local data = req:form()
    local user = User:where({ email = data.email }):first()

    if user and verifyPassword(data.password, user.password_hash) then
        req.session:regenerate(false)
        req.session.userId = user.id
        req.session.username = user.name
        req.session.role = user.role
        req.session:flash("success", "Welcome back!")
        res:redirect("/dashboard")
    else
        req.session:flash("error", "Invalid email or password")
        res:redirect("/login")
    end
end)

-- Dashboard (protected)
app:get("/dashboard", function(req, res)
    if not req.session:has("userId") then
        return res:redirect("/login")
    end

    res:render("dashboard", {
        username = req.session.username,
        flash = {
            success = req.session:getFlash("success"),
            error = req.session:getFlash("error"),
        },
    })
end)

-- Logout
app:post("/logout", function(req, res)
    req.session:destroy()
    res:redirect("/login")
end)

-- Settings
app:post("/settings/theme", function(req, res)
    local data = req:json()
    req.session:set("theme", data.theme)
    res:json({ theme = data.theme })
end)

app:listen(3000)
```
