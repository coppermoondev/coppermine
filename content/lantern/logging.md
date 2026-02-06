# Logging & Events

Lantern provides per-request logging and a timeline system for tracking events during request processing. Logs appear in the Logs panel, and events appear in the Performance panel timeline.

## Logging

### Log Levels

Lantern supports four log levels, each displayed with a colored badge in the panel:

| Level | Method | Badge Color |
|-------|--------|-------------|
| debug | `req.lantern:debug()` | Gray |
| info | `req.lantern:info()` | Blue |
| warning | `req.lantern:warning()` | Yellow |
| error | `req.lantern:error()` | Red |

### Basic Logging

```lua
app:get("/users", function(req, res)
    req.lantern:debug("Handler started")
    req.lantern:info("Fetching users from database")
    req.lantern:warning("Using deprecated API")
    req.lantern:error("Failed to send notification")
    res:render("users")
end)
```

### Logging with Context

Pass a table as the second argument to attach extra data:

```lua
req.lantern:info("User loaded", { userId = 42, role = "admin" })

req.lantern:warning("Slow query detected", {
    query = "SELECT * FROM posts",
    duration = 150,
})

req.lantern:error("Payment failed", {
    orderId = "ORD-123",
    gateway = "stripe",
    code = "card_declined",
})
```

Context data is displayed alongside the log message in the Logs panel.

### Generic Log Method

Use `log()` with an explicit level string:

```lua
req.lantern:log("info", "Custom log message", { key = "value" })
```

### Module-Level Helper

Log from code that doesn't have direct access to the collector:

```lua
local lantern = require("lantern")

lantern.log(req, "info", "Message from module")
lantern.log(req, "error", "Something failed", { detail = "context" })
```

## Log Display

Each log entry in the Logs panel shows:

| Field | Description |
|-------|-------------|
| Level Badge | Colored label (DEBUG, INFO, WARNING, ERROR) |
| Timestamp | Time offset from request start (e.g., +12ms) |
| Message | The log message text |
| Context | Expanded data table (if provided) |

### Error Indicator

When any error-level logs exist (or template rendering errors), the floating Lantern badge shows a red count indicator. This makes it easy to spot problems without opening the panel.

## Timeline Events

The Performance panel includes a timeline of events that occurred during the request. Use timeline events to mark significant points in your request lifecycle.

### Adding Events

```lua
app:get("/dashboard", function(req, res)
    req.lantern:addTimelineEvent("auth_check", "Checking authentication")

    local user = authenticate(req)

    req.lantern:addTimelineEvent("data_fetch", "Fetching dashboard data")

    local stats = loadDashboardStats(user)
    local notifications = loadNotifications(user)

    req.lantern:addTimelineEvent("render_start", "Rendering template")

    res:render("dashboard", {
        user = user,
        stats = stats,
        notifications = notifications,
    })
end)
```

### Event Data

Each event records:

| Field | Description |
|-------|-------------|
| `id` | Event identifier string |
| `label` | Human-readable label |
| `time` | Seconds elapsed since request start |
| `timestamp` | Unix timestamp |
| `data` | Optional custom data table |

Pass custom data as a third argument:

```lua
req.lantern:addTimelineEvent("cache_result", "Cache lookup", {
    key = "user:42:profile",
    hit = false,
})
```

### Module-Level Helper

```lua
lantern.addEvent(req, "event_id", "Event label", { optional = "data" })
```

### Automatic Events

Lantern records these events automatically:

| Event | When |
|-------|------|
| `request_received` | Request processing starts |
| `response_sent` | Response body is ready |
| `vein_collected` | Template metrics collected |
| `request_complete` | All processing done |

## Middleware Tracking

The Performance panel also shows middleware execution times. Lantern tracks which middleware ran and how long each took.

```lua
-- Tracked automatically for all middleware registered with app:use()
```

Each middleware entry shows:

| Column | Description |
|--------|-------------|
| Name | Middleware name or identifier |
| Duration | Execution time in milliseconds |

## Custom Data

Store arbitrary data on the request collector for inspection:

```lua
app:get("/users/:id", function(req, res)
    req.lantern:set("user_id", req.params.id)
    req.lantern:set("cache_hit", false)

    local user = User:find(req.params.id)
    req.lantern:set("user_found", user ~= nil)

    res:json({ user = user })
end)
```

Retrieve values:

```lua
local userId = req.lantern:get("user_id")
```

Custom data is available in the exported data under the `custom` field.

## Practical Patterns

### Request Context Logger

Create a helper that includes request context in every log:

```lua
local function createLogger(req)
    return {
        info = function(msg, ctx)
            ctx = ctx or {}
            ctx.path = req.path
            ctx.method = req.method
            req.lantern:info(msg, ctx)
        end,
        error = function(msg, ctx)
            ctx = ctx or {}
            ctx.path = req.path
            ctx.method = req.method
            req.lantern:error(msg, ctx)
        end,
    }
end

app:get("/users", function(req, res)
    local log = createLogger(req)
    log.info("Fetching users")
    log.error("Database timeout", { retries = 3 })
    res:json({})
end)
```

### Performance Measurement

Use timeline events to measure specific operations:

```lua
app:get("/report", function(req, res)
    req.lantern:addTimelineEvent("query_start", "Running report query")
    local data = db:query("SELECT ... complex query ...")

    req.lantern:addTimelineEvent("process_start", "Processing results")
    local report = processReport(data)

    req.lantern:addTimelineEvent("render_start", "Rendering PDF")
    local pdf = renderPDF(report)

    res:type("application/pdf"):send(pdf)
end)
```

### Conditional Logging

Log at different levels based on conditions:

```lua
app:get("/api/search", function(req, res)
    local start = os.clock()
    local results = performSearch(req.query.q)
    local duration = (os.clock() - start) * 1000

    if duration > 100 then
        req.lantern:warning("Slow search", { query = req.query.q, duration = duration })
    else
        req.lantern:debug("Search completed", { query = req.query.q, duration = duration })
    end

    res:json({ results = results })
end)
```
