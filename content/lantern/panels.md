# Panels

The Lantern toolbar contains six tabbed panels, each showing a different aspect of the current request. Click the floating badge or press **Ctrl+Shift+L** to open the toolbar.

## Request Panel

Displays all incoming request information.

### General

| Field | Description |
|-------|-------------|
| Method | HTTP method (GET, POST, PUT, DELETE, etc.) |
| Path | Request path |
| Full URL | Path with query string |
| IP Address | Client IP (respects X-Forwarded-For) |
| Protocol | http or https |
| Hostname | Host header value |
| XHR | Whether this is an XMLHttpRequest |

### Headers

All request headers displayed as a key-value table.

### Query Parameters

Parsed query string parameters (`?key=value&other=123`).

### Route Parameters

Named route parameters (`:id`, `:slug`) and wildcard captures (`*`).

### Body

The raw request body with type detection:

- **JSON** — Parsed and syntax-highlighted
- **Form data** — Key-value pairs
- **Raw** — Plain text display

### Cookies

Parsed cookies from the `Cookie` header.

## Response Panel

Shows response metadata.

| Field | Description |
|-------|-------------|
| Status | HTTP status code with color badge (2xx green, 4xx yellow, 5xx red) |
| Content-Type | Response content type |
| Body Size | Response body size in bytes |

Response headers are displayed in a key-value table.

## Templates Panel

Shows Vein template engine metrics. Requires metrics to be enabled on the Vein engine (see [Setup](/docs/lantern/setup)).

### Summary Statistics

| Stat | Description |
|------|-------------|
| Total Renders | Number of template render calls |
| Total Time | Combined render time in milliseconds |
| Cache Hit Rate | Percentage of renders served from cache |
| Errors | Number of template rendering errors |

### Template Renders

A table of all rendered templates, sorted by total time (slowest first):

| Column | Description |
|--------|-------------|
| Name | Template file name |
| Count | Number of times rendered |
| Total Time | Combined render time |
| Avg Time | Average time per render |
| Max Time | Slowest single render |

### Template Errors

List of templates that failed to render, with the error message for each.

### Filter Usage

Table of Vein filters used during rendering, with the usage count for each.

### Empty State

If Vein metrics are not enabled, the panel shows a hint:

> Enable metrics in Vein: `vein.new({ metrics = true })`

## Logs Panel

Displays application log entries recorded during the request.

Each log entry shows:

| Field | Description |
|-------|-------------|
| Level | Badge: DEBUG (gray), INFO (blue), WARNING (yellow), ERROR (red) |
| Timestamp | Milliseconds since request start (+42ms) |
| Message | Log message text |
| Context | Additional data table (if provided) |

### Adding Logs

```lua
app:get("/users", function(req, res)
    req.lantern:debug("Loading users page")
    req.lantern:info("Querying database", { table = "users" })
    req.lantern:warning("Slow query detected", { duration = 150 })
    req.lantern:error("Failed to load avatar", { userId = 42 })
    res:render("users")
end)
```

### Error Badge

If any error-level logs or template errors exist, the floating badge shows a red count indicator.

### Empty State

> Use `lantern:log(level, message)` to add logs.

## Queries Panel

Displays database queries executed during the request. Requires Freight integration (see [Freight Integration](/docs/lantern/freight-integration)).

### Summary Statistics

| Stat | Description |
|------|-------------|
| Total Queries | Number of queries executed |
| Total Time | Combined query time |
| Average Time | Mean query duration |
| Slowest | Duration of the slowest query |

### Query Types Breakdown

Count of queries by type: SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER.

### Query Log

Each query is displayed with:

| Element | Description |
|---------|-------------|
| Index | Query number (#1, #2, ...) |
| Type Badge | Colored badge (SELECT blue, INSERT green, UPDATE yellow, DELETE red) |
| SQL | Syntax-highlighted SQL with keywords, strings, and numbers colored |
| Parameters | Query parameters displayed below the SQL |
| Duration | Execution time with slow-query highlighting |
| Row Count | Number of rows returned/affected |
| Results | Expandable "View" button for SELECT results |

### Slow Query Highlighting

A query is highlighted as slow if:
- Its duration is more than 2x the average query time
- AND its duration exceeds 10ms

### Results Viewer

For SELECT queries, click "View" to expand a results table:

- Column headers from the result set
- Up to 50 rows displayed (configurable)
- Total row count shown
- Truncation indicator if results were limited
- For INSERT queries: shows the last insert ID
- For UPDATE/DELETE: shows affected row count

### Empty State

> Use `lantern.freight(db)` or `recordQuery()` manually.

## Performance Panel

Shows overall request performance metrics.

### Summary

| Stat | Description |
|------|-------------|
| Total Time | Request-to-response duration in milliseconds |
| Memory Delta | Change in Lua memory during the request |
| Peak Memory | Maximum memory usage during the request |
| Lua Version | Current Lua runtime version |

### Timeline

Chronological list of events during the request:

| Event | When |
|-------|------|
| `request_received` | Start of request processing |
| Custom events | Any events added with `addTimelineEvent()` |
| `response_sent` | Response body ready |
| `vein_collected` | Template metrics collected |
| `request_complete` | All processing done |

Each event shows the time elapsed since request start.

### Middleware Execution

Table of middleware that ran during the request:

| Column | Description |
|--------|-------------|
| Name | Middleware identifier |
| Duration | Execution time in milliseconds |

### Memory Details

| Field | Description |
|-------|-------------|
| Start | Memory at request start (KB) |
| End | Memory at request end (KB) |
| Peak | Maximum memory during request (KB) |
| Delta | Memory change (KB) |

## Panel Controls

### Badge

- **Click** to toggle the panel open/closed
- **Red badge** appears when errors exist

### Toolbar

- **Tabs** — Click to switch between panels
- **Maximize** — Toggle between normal (45vh) and full (85vh) height
- **Close** — Hide the panel, show the badge
- **Resize** — Drag the top edge to adjust panel height

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| **Ctrl+Shift+L** | Toggle panel open/closed |
| **Esc** | Close the panel |

## Theme

Lantern uses a Catppuccin Mocha dark theme that blends with most development environments. The panel uses its own scoped CSS variables and does not affect your application's styling.
