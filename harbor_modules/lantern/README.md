# Lantern

> **Debug toolbar for HoneyMoon — inspect requests, queries, templates, and performance**

Lantern is a development debugging tool inspired by [Laravel Debugbar](https://github.com/barryvdh/laravel-debugbar) and [Symfony Profiler](https://symfony.com/doc/current/profiler.html). It injects a beautiful, interactive debug panel into your HTML responses, giving you real-time insight into every request.

## Features

- 🔍 **Request inspector** — method, path, headers, query, body, cookies
- 📤 **Response viewer** — status, headers, body size
- 🗄️ **Query log** — SQL queries with syntax highlighting, duration, row counts, and inline result viewer
- 🎨 **Template metrics** — render times, cache hit rates, filter usage (Vein integration)
- 📝 **Log viewer** — debug, info, warning, error logs with context
- ⏱️ **Performance** — total duration, memory delta, timeline, middleware execution
- 🔗 **Freight ORM integration** — automatic query tracking with zero config
- ⌨️ **Keyboard shortcut** — Ctrl+Shift+L to toggle the panel

## Installation

```bash
harbor install lantern
```

## Quick Start

```lua
local honeymoon = require("honeymoon")
local lantern = require("lantern")

local app = honeymoon.new()

-- One-line setup (auto-detects dev environment)
lantern.setup(app)

app:get("/", function(req, res)
    res:html("<h1>Hello World</h1>")
end)

app:listen(3000)
-- Open browser → click the 🔮 badge in the bottom-right corner
```

## Setup Options

```lua
lantern.setup(app, {
    enabled = true,            -- Enable/disable (default: auto-detect dev env)
    vein = veinEngine,         -- Vein engine for template metrics
    ignorePaths = { "/api" },  -- Paths to skip
    condition = function(req)  -- Custom enable condition
        return req:get("x-debug") == "true"
    end,
})
```

Or use as middleware directly:

```lua
app:use(lantern.middleware({
    enabled = true,
    htmlOnly = true,
}))
```

## Logging in Routes

Every request gets a `req.lantern` collector. Use it to add custom logs and data:

```lua
app:get("/users/:id", function(req, res)
    req.lantern:info("Fetching user", { id = req.params.id })

    local user = getUser(req.params.id)

    if not user then
        req.lantern:warning("User not found")
    end

    req.lantern:debug("Response ready", { cached = false })

    res:json({ user = user })
end)
```

### Log Methods

```lua
req.lantern:debug(message, context?)
req.lantern:info(message, context?)
req.lantern:warning(message, context?)
req.lantern:error(message, context?)
req.lantern:log(level, message, context?)
```

### Custom Data

```lua
req.lantern:set("cache_status", "miss")
req.lantern:set("user_id", 42)
```

### Timeline Events

```lua
req.lantern:addTimelineEvent("db_query", "Database query started")
-- ... do work ...
req.lantern:addTimelineEvent("db_done", "Database query finished")
```

## Freight ORM Integration

Automatically track all database queries with duration, row counts, and inline result viewing:

```lua
local freight = require("freight")
local lantern = require("lantern")

local app = honeymoon.new()
local db = freight.open("sqlite", { database = "app.db" })

-- 1. Setup Lantern
lantern.setup(app)

-- 2. Wrap the database (enables global query tracking)
lantern.freight(db)

-- 3. Connect queries to per-request collectors
app:use(lantern.freightMiddleware(db))

-- Now all Freight queries appear in the Queries tab!
app:get("/users", function(req, res)
    local users = User:findAll()  -- Automatically logged
    res:render("users/index", { users = users })
end)
```

### Freight Options

```lua
lantern.freight(db, {
    captureResults = true,     -- Capture query results (default: true)
    maxResultRows = 50,        -- Max rows to capture (default: 50)
    maxColumnWidth = 200,      -- Truncate long values (default: 200)
})
```

### Global Stats

```lua
local stats = lantern.getFreightStats()
-- { totalQueries = 42, totalDuration = 123.4, queryTypes = { SELECT = 30, INSERT = 12 } }

lantern.resetFreightStats()
```

## Manual Query Tracking

If you're not using Freight, you can manually record queries:

```lua
app:get("/data", function(req, res)
    local start = time.monotonic_ms()
    local result = db:query("SELECT * FROM users WHERE active = ?", true)
    local duration = time.monotonic_ms() - start

    req.lantern:recordQuery("SELECT * FROM users WHERE active = ?", {true}, duration, #result)

    res:json(result)
end)
```

## Vein Template Metrics

When using Vein with metrics enabled, Lantern shows:
- Render count and times per template
- Cache hit/miss rates
- Filter usage statistics
- Template errors

```lua
local vein = require("vein")
local engine = vein.new({ metrics = true })

app.views:use("vein", engine)
lantern.setup(app, { vein = engine })
```

## Debug Panel Tabs

| Tab | Contents |
|-----|----------|
| **Request** | Method, path, headers, query params, route params, body, cookies |
| **Response** | Status code, headers, body size |
| **Templates** | Render stats, cache rates, filter usage, errors |
| **Logs** | All log entries with level, timestamp, message, and context |
| **Queries** | SQL with syntax highlighting, duration, type badges, expandable results |
| **Performance** | Total duration, memory usage, timeline, middleware execution |

## API Reference

### Setup

| Function | Description |
|----------|-------------|
| `lantern.setup(app, options?)` | Setup with HoneyMoon app |
| `lantern.middleware(options?)` | Create middleware function |
| `lantern.freight(db, options?)` | Wrap Freight DB for query tracking |
| `lantern.freightMiddleware(db)` | Per-request query collector middleware |

### Collector

| Method | Description |
|--------|-------------|
| `collector:log(level, msg, ctx?)` | Add a log entry |
| `collector:debug(msg, ctx?)` | Debug log |
| `collector:info(msg, ctx?)` | Info log |
| `collector:warning(msg, ctx?)` | Warning log |
| `collector:error(msg, ctx?)` | Error log |
| `collector:recordQuery(sql, params?, duration, rowCount?)` | Record a query |
| `collector:addTimelineEvent(id, label, data?)` | Add timeline event |
| `collector:set(key, value)` | Add custom data |
| `collector:get(key)` | Get custom data |

### Utility

| Function | Description |
|----------|-------------|
| `lantern.get(req)` | Get collector from request |
| `lantern.log(req, level, msg, ctx?)` | Log to request collector |
| `lantern.recordQuery(req, sql, params?, duration, rowCount?)` | Record query |
| `lantern.getFreightStats()` | Get global Freight stats |
| `lantern.resetFreightStats()` | Reset global stats |

## Related

- [CopperMoon](https://github.com/coppermoondev/coppermoon) — The Lua runtime
- [Harbor](https://github.com/coppermoondev/harbor) — Package manager (`harbor install lantern`)
- [HoneyMoon](https://github.com/coppermoondev/honeymoon) — Web framework
- [Freight](https://github.com/coppermoondev/freight) — ORM / database
- [Ember](https://github.com/coppermoondev/ember) — Structured logging
- [Vein](https://github.com/coppermoondev/vein) — Templating engine

## Documentation

For full documentation, visit [coppermoon.dev](https://coppermoon.dev).

## License

MIT License — CopperMoon Contributors
