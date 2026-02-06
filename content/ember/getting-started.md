# Getting Started

## Installation

Add Ember to your project's `harbor.toml`:

```toml
[dependencies.ember]
version = "0.1.0"
```

Or with a local path during development:

```toml
[dependencies.ember]
path = "../../packages/ember"
```

Then install dependencies:

```bash
harbor install
```

## Basic Usage

```lua
local ember = require("ember")

-- Create a logger with defaults (console, info level, colors)
local log = ember()

log:info("Application started")
log:debug("This won't appear -- info is the default level")
```

## Configuration

Pass an options table to customize the logger:

```lua
local log = ember({
    level = "debug",          -- Minimum level (default: "info")
    name = "my-app",          -- Logger name (appears in output)
    context = {               -- Default context for all entries
        service = "api",
        version = "1.2.0",
    },
    transports = {            -- Where logs are sent
        ember.transports.console({ colors = true }),
        ember.transports.file({ path = "./logs/app.log" }),
    },
})
```

## Log Levels

Ember has 6 log levels, ordered from least to most severe:

| Level | Value | Use case |
|-------|-------|----------|
| **trace** | 10 | Extremely detailed debugging (loop iterations, variable state) |
| **debug** | 20 | Development diagnostics (function calls, config values) |
| **info** | 30 | Normal operation events (server start, request handled) |
| **warn** | 40 | Potential issues (deprecated usage, slow queries, retries) |
| **error** | 50 | Errors that need attention (failed operations, exceptions) |
| **fatal** | 60 | Unrecoverable errors (crash imminent, data corruption) |

Setting a level filters out everything below it:

```lua
local log = ember({ level = "warn" })
log:info("Filtered out")  -- Does nothing
log:warn("This appears")  -- Logged
log:error("This too")     -- Logged
```

## Structured Logging

Every log method accepts an optional context table as the second argument:

```lua
log:info("User login", {
    userId = 42,
    ip = "192.168.1.1",
    method = "oauth",
})
```

The context is merged with the logger's base context. Call-site values override base values:

```lua
local log = ember({
    context = { service = "api", env = "production" },
})

log:info("Request", { path = "/users" })
-- Context: { service = "api", env = "production", path = "/users" }
```

## Multiple Transports

Send logs to different destinations with different levels:

```lua
local log = ember({
    level = "debug",
    transports = {
        -- Console: all levels with colors
        ember.transports.console({ colors = true }),

        -- File: only warnings and above
        ember.transports.file({
            path = "./logs/errors.log",
            level = "warn",
        }),

        -- JSON stdout: for log aggregators
        ember.transports.json({ level = "info" }),
    },
})
```

Each transport independently filters by its own level. A transport only receives entries at or above its configured level.

## Child Loggers

Create child loggers that inherit configuration and add context:

```lua
local log = ember({ name = "api" })

-- Child inherits transports and level, adds context
local userLog = log:child({ module = "users" })
userLog:info("User created", { userId = 42 })
-- Context: { module = "users", userId = 42 }

-- Children can have children
local authLog = userLog:child({ action = "login" })
authLog:info("Login attempt")
-- Context: { module = "users", action = "login" }
```

## With HoneyMoon

Replace `honeymoon.logger()` with Ember for structured request logging:

```lua
local honeymoon = require("honeymoon")
local ember = require("ember")

local app = honeymoon.new()
local log = ember({ name = "my-app", level = "debug" })

-- Creates req.log child logger per request
app:use(ember.honeymoon(log))

app:get("/users/:id", function(req, res)
    -- req.log has method, path, requestId context
    req.log:info("Fetching user", { userId = req.params.id })
    res:json({ id = req.params.id })
end)
-- Auto-logs: "request completed" with status, duration, contentLength
```

## With Lantern

Bridge Ember logs into Lantern's debug panel:

```lua
local lantern = require("lantern")

-- Setup Lantern first
lantern.setup(app, { enabled = true })

-- Then add the Ember-Lantern bridge (after both ember.honeymoon and lantern.setup)
app:use(ember.lantern())

-- Now req.log entries appear in Lantern's Logs panel
```

## With Freight

Log database queries automatically:

```lua
local freight = require("freight")
local db = freight.open("sqlite", { database = "./app.db" })

-- Wrap database for query logging
ember.freight(db, log, {
    level = "debug",          -- Log level for queries
    slowThreshold = 100,      -- Queries > 100ms logged as "warn"
    includeParams = true,     -- Include query parameters
})

-- All queries are now logged
db:query("SELECT * FROM users WHERE id = ?", 42)
-- Logs: query { sql="SELECT...", duration=2.5, rows=1, queryType="SELECT" }
```

## Next Steps

- [Loggers & Children](/docs/ember/loggers) — Deep dive into child loggers and context
- [Transports](/docs/ember/transports) — Built-in transports and how to create custom ones
- [Formatters](/docs/ember/formatters) — Control how log entries are formatted
- [Integrations](/docs/ember/integrations) — HoneyMoon, Lantern, Freight details
