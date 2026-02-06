# API Reference

Complete reference for all Lantern functions and methods.

## Module Functions

### lantern.setup(app, options?)

Initialize Lantern with a HoneyMoon application. Automatically adds middleware.

```lua
lantern.setup(app, {
    enabled = true,
    htmlOnly = true,
    vein = app.views.engine,
    ignorePaths = { "/api/" },
    condition = function(req) return true end,
})
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `app` | Application | HoneyMoon app instance |
| `options` | table (optional) | Configuration options |

Returns the `lantern` module.

### lantern.middleware(options?)

Create Lantern middleware without `setup()`:

```lua
local mw = lantern.middleware({
    enabled = true,
    vein = veinEngine,
    htmlOnly = true,
    ignorePaths = {},
})
app:use(mw)
```

Returns a middleware function `(req, res, next)`.

### lantern.createCollector()

Create a standalone data collector:

```lua
local collector = lantern.createCollector()
collector:collectRequest(req)
-- ... do work ...
collector:finalize()
local data = collector:export()
```

Returns a new `Collector` instance.

### lantern.get(req)

Get the collector attached to a request:

```lua
local collector = lantern.get(req)
-- Equivalent to: req.lantern
```

Returns the `Collector` or `nil`.

### lantern.generatePanel(data)

Generate the panel HTML from exported data:

```lua
local data = collector:export()
local html = lantern.generatePanel(data)
```

Returns an HTML string containing the complete panel with styles and scripts.

### lantern.injectPanel(html, data)

Inject the panel into an HTML response:

```lua
local modifiedHtml = lantern.injectPanel(originalHtml, exportedData)
```

Inserts the panel before `</body>`. Returns the modified HTML.

---

## Logging Helpers

### lantern.log(req, level, message, context?)

Log a message to the request's collector:

```lua
lantern.log(req, "info", "Operation complete", { duration = 42 })
```

### lantern.recordQuery(req, sql, params, duration, rowCount)

Record a database query:

```lua
lantern.recordQuery(req, "SELECT * FROM users", {}, 5.2, 10)
```

### lantern.addEvent(req, id, label, data?)

Add a timeline event:

```lua
lantern.addEvent(req, "cache_miss", "Cache miss for key", { key = "user:42" })
```

---

## Freight Functions

### lantern.freight(db, options?)

Wrap a Freight database instance for query tracking:

```lua
lantern.freight(db, {
    captureResults = true,
    maxResultRows = 50,
    maxColumnWidth = 200,
})
```

| Option | Default | Description |
|--------|---------|-------------|
| `captureResults` | `true` | Capture SELECT result sets |
| `maxResultRows` | `50` | Max rows captured per query |
| `maxColumnWidth` | `200` | Truncate long column values |

Returns a `FreightLogger` instance.

### lantern.freightMiddleware(db)

Create per-request middleware for query logging:

```lua
app:use(lantern.freightMiddleware(db))
```

Returns a middleware function. Must be called after `lantern.freight(db)`.

### lantern.getFreightStats()

Get global query statistics:

```lua
local stats = lantern.getFreightStats()
-- {
--     totalQueries = 150,
--     totalDuration = 423.5,
--     queryTypes = { SELECT = 120, INSERT = 20, UPDATE = 10 }
-- }
```

### lantern.resetFreightStats()

Reset global statistics counters.

---

## Collector Methods

The collector is available as `req.lantern` in route handlers (after Lantern middleware runs).

### Data Collection

#### collector:collectRequest(req)

Capture request data (method, path, headers, params, body, cookies).

#### collector:collectResponse(res, statusCode)

Capture response data (status, headers, content type, body size).

#### collector:collectVeinMetrics(veinEngine)

Capture template rendering metrics from a Vein engine instance.

#### collector:finalize()

Mark the request as complete. Records end time and final memory snapshot.

#### collector:export()

Export all collected data as a table. Used by panel generation.

Returns:

```lua
{
    request = { method, path, url, headers, query, params, body, ... },
    response = { status, statusText, headers, contentType, bodySize },
    templates = { totalRenders, totalTime, cacheHitRate, renders, errors, ... },
    logs = { { level, message, context, time, timestamp }, ... },
    queries = { { type, sql, params, duration, rowCount, results }, ... },
    queryStats = { total, totalTime, byType, slowest, slowestTime },
    timeline = { { id, label, time, timestamp, data }, ... },
    middleware = { { name, duration, time }, ... },
    performance = { duration, memory, luaVersion },
    custom = { key = value, ... },
    timestamp = unix_timestamp,
}
```

### Logging

#### collector:log(level, message, context?)

```lua
req.lantern:log("info", "Message", { key = "value" })
```

#### collector:debug(message, context?)

```lua
req.lantern:debug("Debug message")
```

#### collector:info(message, context?)

```lua
req.lantern:info("Info message", { detail = "extra" })
```

#### collector:warning(message, context?)

```lua
req.lantern:warning("Warning message")
```

#### collector:error(message, context?)

```lua
req.lantern:error("Error message", { code = 500 })
```

### Query Tracking

#### collector:recordQuery(sql, params, duration, rowCount, queryType?, results?, lastInsertId?)

Record a database query manually:

```lua
req.lantern:recordQuery(
    "SELECT * FROM users WHERE id = ?",
    { 42 },
    5.2,
    1,
    "SELECT",
    { columns = {"id", "name"}, rows = {{ id = 42, name = "Alice" }} },
    nil
)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `sql` | string | SQL query string |
| `params` | table | Query parameters |
| `duration` | number | Execution time in ms |
| `rowCount` | number | Rows returned/affected |
| `queryType` | string (optional) | AUTO-detected from SQL if omitted |
| `results` | table (optional) | Prepared result set |
| `lastInsertId` | number (optional) | Last insert ID |

#### collector:getQueryStats()

Get query statistics for the current request:

```lua
local stats = req.lantern:getQueryStats()
-- {
--     total = 5,
--     totalTime = 23.4,
--     byType = { SELECT = 3, INSERT = 2 },
--     slowest = "SELECT * FROM posts ...",
--     slowestTime = 12.1,
-- }
```

### Timeline

#### collector:addTimelineEvent(id, label, data?)

```lua
req.lantern:addTimelineEvent("cache_check", "Checking cache", { key = "users" })
```

### Middleware

#### collector:recordMiddleware(name, duration)

Record middleware execution time:

```lua
req.lantern:recordMiddleware("auth", 2.3)
```

### Custom Data

#### collector:set(key, value)

Store custom data:

```lua
req.lantern:set("user_id", 42)
```

#### collector:get(key)

Retrieve custom data:

```lua
local userId = req.lantern:get("user_id")
```

### Memory

#### collector:updateMemory()

Update peak memory tracking. Called automatically during collection.

### Utility

#### collector:getDuration()

Get total request duration in milliseconds:

```lua
local ms = req.lantern:getDuration()
```

---

## FreightLogger Methods

Advanced methods on the logger returned by `lantern.freight(db)`.

#### logger:addListener(fn)

Add a query listener function:

```lua
logger:addListener(function(queryInfo)
    print(queryInfo.sql, queryInfo.duration)
end)
```

#### logger:removeListener(fn)

Remove a previously added listener.

#### logger:setEnabled(enabled)

Enable or disable query interception:

```lua
logger:setEnabled(false)  -- Temporarily disable
```

#### logger:wrap()

Wrap the database methods. Called automatically by `lantern.freight(db)`.

#### logger:unwrap()

Restore original database methods:

```lua
logger:unwrap()  -- Remove Lantern interception
```
