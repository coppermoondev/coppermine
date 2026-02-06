# Ember

> **A structured logging library for CopperMoon — fast, extensible, with transports and child loggers**

Ember is a production-grade logging library inspired by [Pino](https://getpino.io/) and [Winston](https://github.com/winstonjs/winston). It provides structured JSON logging, multiple transports, child loggers with inherited context, and first-class integrations with HoneyMoon and Freight.

## Features

- 🚀 **Zero-config** — works out of the box with sensible defaults
- 📊 **Structured logging** — attach context to every log entry
- 🔀 **Multiple transports** — console, file (with rotation), JSON
- 👶 **Child loggers** — inherit context, share transports (Pino pattern)
- 🎨 **Formatters** — pretty (colored), plain text, JSON
- 🔌 **Integrations** — HoneyMoon middleware, Lantern bridge, Freight query logging
- ⚡ **Level filtering** — per-logger and per-transport level gates

## Installation

```bash
harbor install ember
```

## Quick Start

```lua
local ember = require("ember")

-- Zero-config: console output, info level, pretty colors
local log = ember()

log:info("Server starting")
log:warn("Cache miss", { key = "user:42" })
log:error("Connection failed", { host = "db.local", retries = 3 })
```

Output:

```
14:32:05 INF › Server starting
14:32:05 WRN › Cache miss key=user:42
14:32:05 ERR › Connection failed host=db.local retries=3
```

## Configuration

```lua
local log = ember({
    level = "debug",                -- Minimum level (default: "info")
    name = "my-app",                -- Logger name (shown in output)
    context = { service = "api" },  -- Default context for all entries
    transports = {
        ember.transports.console({ colors = true }),
        ember.transports.file({
            path = "./logs/app.log",
            level = "warn",              -- Only warn+ goes to file
            maxSize = 10 * 1024 * 1024,  -- 10MB rotation
            maxFiles = 5,                -- Keep 5 rotated files
        }),
    },
})
```

## Log Levels

| Level | Value | Method |
|-------|-------|--------|
| `trace` | 10 | `log:trace(msg, ctx?)` |
| `debug` | 20 | `log:debug(msg, ctx?)` |
| `info` | 30 | `log:info(msg, ctx?)` |
| `warn` | 40 | `log:warn(msg, ctx?)` |
| `error` | 50 | `log:error(msg, ctx?)` |
| `fatal` | 60 | `log:fatal(msg, ctx?)` |

```lua
log:setLevel("debug")           -- Change level at runtime
print(log:getLevel())           -- "debug"
print(log:isLevelEnabled("trace"))  -- false
```

## Structured Logging

Every log method accepts an optional context table. Context fields are merged with the logger's default context:

```lua
local log = ember({ context = { service = "auth" } })

log:info("User login", { userId = 42, ip = "192.168.1.1" })
-- Output includes: service=auth userId=42 ip=192.168.1.1
```

## Child Loggers

Child loggers inherit their parent's transports and context. Additional context is merged:

```lua
local log = ember({ name = "app", context = { env = "production" } })

-- Per-request child logger
local reqLog = log:child({ requestId = "abc-123", userId = 42 })
reqLog:info("Processing order")
-- Includes: env=production requestId=abc-123 userId=42

-- Children can have children
local dbLog = reqLog:child({ module = "database" })
dbLog:debug("Query executed", { sql = "SELECT ...", duration = 5.2 })
```

## Transports

### Console Transport

```lua
ember.transports.console({
    colors = true,       -- ANSI colors (default: true)
    level = "debug",     -- Minimum level for this transport
    formatter = nil,     -- Custom formatter (default: pretty if colors, text otherwise)
})
```

### File Transport

```lua
ember.transports.file({
    path = "./logs/app.log",    -- Required: log file path
    level = "warn",             -- Minimum level (default: logger level)
    maxSize = 10 * 1024 * 1024, -- Max file size before rotation (bytes)
    maxFiles = 5,               -- Number of rotated files to keep
    mkdir = true,               -- Create parent directories (default: true)
})
```

### JSON Transport

Outputs structured JSON to stdout — ideal for log aggregators (ELK, Datadog, etc.):

```lua
ember.transports.json({
    level = "info",
    messageKey = "msg",       -- JSON key for message (default: "msg")
    timestampKey = "time",    -- JSON key for timestamp (default: "time")
    levelKey = "level",       -- JSON key for level (default: "level")
})
```

Output: `{"level":"info","msg":"User login","time":1705312245,"userId":42}`

### Custom Transport

```lua
local myTransport = ember.transport({
    name = "webhook",
    level = "error",
    write = function(entry, formatted)
        -- entry.level, entry.message, entry.context, entry.timestamp
        http.post("https://hooks.example.com/log", json.encode(entry))
    end,
    close = function()
        -- cleanup
    end,
})

local log = ember({ transports = { myTransport } })
```

## Formatters

### Pretty Formatter (default for console)

Colored, human-readable output for development.

```lua
ember.formatters.pretty({
    colors = true,
    timestamp = true,
    timestampFormat = "%H:%M:%S",
})
```

### Text Formatter

Plain text output suitable for log files.

```lua
ember.formatters.text({
    timestamp = true,
    timestampFormat = "!%Y-%m-%dT%H:%M:%SZ",
    showName = true,
    showContext = true,
})
```

Output: `[2024-01-15T10:30:45Z] INFO  my-app: User login {ip=192.168.1.1, userId=42}`

### JSON Formatter

Structured JSON output.

```lua
ember.formatters.json({
    messageKey = "msg",
    timestampKey = "time",
    levelKey = "level",
})
```

### Custom Formatter

```lua
local fmt = ember.formatter(function(entry)
    return string.format("[%s] %s: %s", entry.level:upper(), entry.name or "app", entry.message)
end)
```

## Integrations

### HoneyMoon Middleware

Attaches a child logger to each request as `req.log`:

```lua
local honeymoon = require("honeymoon")
local ember = require("ember")

local app = honeymoon.new()
local log = ember({ name = "web" })

-- Adds req.log with requestId, method, path context
app:use(ember.honeymoon(log))

app:get("/users/:id", function(req, res)
    req.log:info("Fetching user", { id = req.params.id })
    res:json({ id = req.params.id })
end)
```

### Lantern Bridge

Connects Ember logs to the Lantern debug toolbar:

```lua
app:use(ember.lantern())
```

### Freight Query Logging

Automatically log all database queries:

```lua
local freight = require("freight")
local db = freight.open("sqlite", { database = "app.db" })

ember.freight(db, log, { level = "debug" })
-- All queries are now logged with duration and row count
```

## API Reference

### Logger

| Method | Description |
|--------|-------------|
| `ember(options?)` | Create a new logger (callable shorthand) |
| `ember.new(options?)` | Create a new logger |
| `log:trace(msg, ctx?)` | Log at trace level |
| `log:debug(msg, ctx?)` | Log at debug level |
| `log:info(msg, ctx?)` | Log at info level |
| `log:warn(msg, ctx?)` | Log at warn level |
| `log:error(msg, ctx?)` | Log at error level |
| `log:fatal(msg, ctx?)` | Log at fatal level |
| `log:log(level, msg, ctx?)` | Log at arbitrary level |
| `log:child(context)` | Create a child logger |
| `log:setLevel(level)` | Set minimum log level |
| `log:getLevel()` | Get current level name |
| `log:isLevelEnabled(level)` | Check if level would produce output |
| `log:addTransport(t)` | Add a transport |
| `log:removeTransport(name)` | Remove a transport by name |
| `log:close()` | Close all transports |

### Factory Functions

| Function | Description |
|----------|-------------|
| `ember.transport(definition)` | Create a custom transport |
| `ember.formatter(fn_or_table)` | Create a custom formatter |
| `ember.honeymoon(logger, options?)` | Create HoneyMoon middleware |
| `ember.lantern(options?)` | Create Lantern bridge middleware |
| `ember.freight(db, logger, options?)` | Wrap Freight DB for query logging |

## Related

- [CopperMoon](https://github.com/coppermoondev/coppermoon) — The Lua runtime
- [Harbor](https://github.com/coppermoondev/harbor) — Package manager (`harbor install ember`)
- [HoneyMoon](https://github.com/coppermoondev/honeymoon) — Web framework
- [Lantern](https://github.com/coppermoondev/lantern) — Debug toolbar
- [Freight](https://github.com/coppermoondev/freight) — ORM / database

## Documentation

For full documentation, visit [coppermoon.dev](https://coppermoon.dev).

## License

MIT License — CopperMoon Contributors
