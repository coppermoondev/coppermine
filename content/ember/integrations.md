# Integrations

Ember provides first-class integrations with HoneyMoon, Lantern, and Freight. Each integration is lazy-loaded — only required when you call it.

## HoneyMoon Integration

The HoneyMoon integration creates a per-request child logger and auto-logs request completion.

### Setup

```lua
local honeymoon = require("honeymoon")
local ember = require("ember")

local app = honeymoon.new()
local log = ember({ name = "my-app", level = "debug" })

-- Add Ember middleware (replaces honeymoon.logger())
app:use(ember.honeymoon(log, {
    level = "info",                       -- Completion log level (default: "info")
    requestIdHeader = "x-request-id",     -- Header for request ID (default)
    autoLog = true,                       -- Auto-log request completion (default: true)
    ignorePaths = { "/health", "/public" }, -- Skip logging for these paths
    genReqId = function(req)              -- Custom request ID generator
        return crypto.uuid()
    end,
    customProps = function(req)           -- Extra context per request
        return { userAgent = req.headers["user-agent"] }
    end,
}))
```

### What It Does

1. **Creates `req.log`** — A child logger with request context:
   ```lua
   req.log = logger:child({
       method = req.method,
       path = req.path,
       requestId = "...",  -- From header, generator, or crypto.uuid()
   })
   ```

2. **Auto-logs completion** — Wraps `res.send()` to log when the response is sent:
   ```
   INF my-app > request completed status=200 duration=12.5 contentLength=1024
   ```

3. **Level escalation** — Status codes influence the log level:
   - `2xx`, `3xx` — uses `completionLevel` (default: `"info"`)
   - `4xx` — escalated to `"warn"`
   - `5xx` — escalated to `"error"`

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `level` | string | `"info"` | Log level for request completion |
| `requestIdHeader` | string | `"x-request-id"` | Header to read request ID from |
| `autoLog` | boolean | `true` | Auto-log request completion |
| `ignorePaths` | table | `{}` | Path prefixes to skip |
| `genReqId` | function(req) | `nil` | Custom request ID generator |
| `customProps` | function(req) | `nil` | Extra context properties per request |

### Using req.log

Inside route handlers, use `req.log` for structured, request-scoped logging:

```lua
app:get("/users/:id", function(req, res)
    req.log:info("Fetching user", { userId = req.params.id })

    local user = db:query_row("SELECT * FROM users WHERE id = ?", req.params.id)
    if not user then
        req.log:warn("User not found")
        return res:status(404):json({ error = "Not found" })
    end

    req.log:debug("User loaded", { name = user.name })
    res:json(user)
end)
```

Every `req.log` entry automatically includes `method`, `path`, and `requestId` from the middleware context.

### Path Ignoring

Paths in `ignorePaths` are matched by prefix. Matching requests skip the middleware entirely:

```lua
app:use(ember.honeymoon(log, {
    ignorePaths = { "/health", "/public", "/favicon.ico" },
}))
```

## Lantern Integration

The Lantern integration bridges Ember logs into Lantern's debug panel. Every log entry written through `req.log` also appears in Lantern's Logs tab.

### Setup

```lua
local lantern = require("lantern")

-- 1. Ember middleware (creates req.log)
app:use(ember.honeymoon(log))

-- 2. Lantern setup (creates req.lantern)
lantern.setup(app, {
    enabled = app:get_setting("env") ~= "production",
})

-- 3. Ember-Lantern bridge (connects req.log to req.lantern)
app:use(ember.lantern())
```

**Order matters:** The bridge middleware must be added **after** both `ember.honeymoon()` and `lantern.setup()`, because it needs both `req.log` and `req.lantern` to exist.

### What It Does

The bridge creates a per-request transport that forwards log entries to the Lantern collector:

1. Checks if both `req.log` and `req.lantern` exist
2. Creates a Lantern transport that calls `req.lantern:log(level, message, context)`
3. Adds the transport to `req.log`

### Level Mapping

Ember levels are mapped to Lantern levels:

| Ember Level | Lantern Level |
|-------------|---------------|
| trace | debug |
| debug | debug |
| info | info |
| warn | warning |
| error | error |
| fatal | error |

### Options

```lua
app:use(ember.lantern({
    -- Currently no options, reserved for future use
}))
```

### Result

With the bridge active, any call to `req.log:info(...)` or similar will:
- Output to the console (or whatever transports the logger has)
- Appear in the Lantern Logs panel in the browser

## Freight Integration

The Freight integration wraps database methods to automatically log queries with timing and slow query detection.

### Setup

```lua
local freight = require("freight")
local db = freight.open("sqlite", { database = "./app.db" })

-- Wrap database for query logging
ember.freight(db, log, {
    level = "debug",          -- Log level for normal queries (default: "debug")
    slowThreshold = 100,      -- Queries slower than this (ms) logged as "warn" (default: 100)
    includeParams = true,     -- Include query parameters in logs (default: true)
})
```

### What It Does

Wraps three Freight database methods:

- `db:query(sql, ...)` — SELECT returning multiple rows
- `db:query_row(sql, ...)` — SELECT returning a single row
- `db:execute(sql, ...)` — INSERT, UPDATE, DELETE, etc.

Each wrapped method:

1. Records the start time with `time.monotonic_ms()`
2. Calls the original method
3. Calculates duration
4. Detects query type from the SQL (SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER)
5. Logs the query with context

### Log Output

Normal query:

```
DBG my-app > query sql="SELECT * FROM users WHERE id = ?" duration=2.5 rows=1 queryType=SELECT params={42}
```

Slow query (automatically escalated to warn):

```
WRN my-app > query sql="SELECT * FROM orders..." duration=250.3 rows=1500 queryType=SELECT
```

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `level` | string | `"debug"` | Log level for normal queries |
| `slowThreshold` | number | `100` | Duration (ms) above which queries are logged as `"warn"` |
| `includeParams` | boolean | `true` | Include query parameters in log context |

### Query Context

Each query log entry includes:

| Field | Description |
|-------|-------------|
| `sql` | The SQL query string |
| `duration` | Execution time in milliseconds (2 decimal places) |
| `queryType` | Detected type: SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, or EXECUTE |
| `rows` | Number of rows returned (for query/query_row) |
| `affected` | Number of affected rows (for execute) |
| `params` | Query parameters (if `includeParams` is true and params exist) |

### Unwrapping

Restore the original database methods:

```lua
local freight_integration = require("ember.lib.integrations.freight")
freight_integration.unwrap(db)
```

This removes the Ember wrappers and restores `db.query`, `db.query_row`, and `db.execute` to their original functions.

## Full Stack Example

Here's a complete example using all three integrations:

```lua
local honeymoon = require("honeymoon")
local lantern = require("lantern")
local freight = require("freight")
local ember = require("ember")

local app = honeymoon.new()

-- Create logger
local log = ember({
    name = "my-app",
    level = "debug",
    transports = {
        ember.transports.console({ colors = true }),
        ember.transports.file({
            path = "./logs/app.log",
            level = "info",
            maxSize = 5 * 1024 * 1024,
        }),
    },
})

-- Database
local db = freight.open("sqlite", { database = "./app.db" })
ember.freight(db, log, { slowThreshold = 200 })

-- Middleware stack
app:use(ember.honeymoon(log, {
    ignorePaths = { "/public" },
}))

lantern.setup(app, {
    enabled = app:get_setting("env") ~= "production",
})

app:use(ember.lantern())
app:use("/public", honeymoon.static("./public"))

-- Routes
app:get("/users", function(req, res)
    req.log:info("Listing users")
    local users = db:query("SELECT * FROM users ORDER BY name")
    res:json(users)
end)

app:listen(3000)
```

This gives you:
- Colored console output for development
- File logs (info+) with rotation for production
- Per-request child loggers with method/path/requestId
- Automatic request completion logging with status and duration
- Database query logging with slow query warnings
- All logs visible in Lantern's debug panel
