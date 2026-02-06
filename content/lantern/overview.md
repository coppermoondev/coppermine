# Lantern DevTools

Lantern is a debug toolbar and development profiler for HoneyMoon applications. Inspired by Laravel Debugbar and Symfony Profiler, it provides real-time insight into requests, database queries, template rendering, logs, and performance — all displayed in a panel injected into your HTML pages.

## Features

- **Request/Response inspector** — headers, params, body, cookies
- **Database query log** — SQL with syntax highlighting, timing, results viewer
- **Template metrics** — render counts, cache hit rate, errors (Vein integration)
- **Application logs** — debug, info, warning, error with timestamps
- **Performance profiler** — memory usage, middleware timing, request timeline
- **Freight integration** — automatic query capture from Freight ORM
- **Keyboard shortcut** — Ctrl+Shift+L to toggle the panel

## Quick Start

```lua
local honeymoon = require("honeymoon")
local lantern = require("lantern")
local app = honeymoon.new()

-- Setup Lantern (auto-injects middleware)
lantern.setup(app, {
    enabled = app:get_setting("env") ~= "production",
})

-- Your routes
app:get("/", function(req, res)
    req.lantern:info("Home page visited")
    res:render("index", { title = "Home" })
end)

app:listen(3000)
```

The debug panel appears at the bottom of every HTML page, showing a floating badge you can click to open the full toolbar.

## What You See

### Badge

A small circular button in the bottom-right corner of the page. It shows a red error count badge if any errors were logged during the request. Click it or press **Ctrl+Shift+L** to open the panel.

### Panel

A slide-up toolbar with six tabs:

| Tab | Shows |
|-----|-------|
| **Request** | HTTP method, path, headers, query params, route params, body, cookies |
| **Response** | Status code, content type, headers, body size |
| **Templates** | Render count, total time, cache hit rate, per-template stats, errors |
| **Logs** | All log entries with level, timestamp, message, and context |
| **Queries** | SQL queries with timing, parameters, syntax highlighting, results |
| **Performance** | Total duration, memory usage, middleware timeline |

## When to Use Lantern

Lantern is designed for **development only**. It should be disabled in production to avoid exposing internal application details.

```lua
lantern.setup(app, {
    enabled = os_ext.env("NODE_ENV") ~= "production",
})
```

## Next Steps

- [Setup](/docs/lantern/setup) — Configuration options and integration
- [Panels](/docs/lantern/panels) — Detailed panel descriptions
- [Freight Integration](/docs/lantern/freight-integration) — Database query tracking
- [Logging & Events](/docs/lantern/logging) — Application logs and timeline events
- [API Reference](/docs/lantern/api) — Full API documentation
