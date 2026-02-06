# Transports

Transports determine where log entries are sent. Ember includes three built-in transports and a simple interface for creating custom ones.

## Built-in Transports

### Console Transport

Outputs formatted log lines to stdout via `print()`. This is the default transport when no transports are specified.

```lua
local log = ember({
    transports = {
        ember.transports.console({
            colors = true,     -- Enable ANSI colors (default: true)
            level = "debug",   -- Transport-level filter (optional)
        }),
    },
})
```

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `colors` | boolean | `true` | Enable ANSI colored output |
| `level` | string | Logger level | Minimum level for this transport |
| `formatter` | table | Pretty (colors) or Text (no colors) | Custom formatter |
| `stream` | function | `print` | Output function |

When `colors` is `true`, the console transport uses the **pretty** formatter by default. When `false`, it uses the **text** formatter.

### File Transport

Appends log lines to a file with optional size-based rotation.

```lua
local log = ember({
    transports = {
        ember.transports.file({
            path = "./logs/app.log",     -- Required: file path
            level = "warn",              -- Only warnings and above
            maxSize = 10 * 1024 * 1024,  -- 10 MB rotation threshold
            maxFiles = 5,                -- Keep 5 rotated files
        }),
    },
})
```

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `path` | string | *required* | File path for the log file |
| `level` | string | Logger level | Minimum level for this transport |
| `maxSize` | number or nil | `nil` (no rotation) | Max file size in bytes before rotation |
| `maxFiles` | number | `5` | Number of rotated files to keep |
| `mkdir` | boolean | `true` | Auto-create parent directories |
| `formatter` | table | Text with timestamps | Custom formatter |

**Rotation behavior:**

When a write would exceed `maxSize`, files are rotated before writing:

```
app.log   -> app.log.1
app.log.1 -> app.log.2
app.log.2 -> app.log.3
...
app.log.N -> deleted (when N > maxFiles)
```

The file transport uses `fs.append()` for atomic per-write operations — no file handle management needed. Parent directories are created automatically with `fs.mkdir_all()`.

### JSON Transport

Outputs structured JSON to stdout, designed for log aggregation systems (ELK, Datadog, CloudWatch).

```lua
local log = ember({
    transports = {
        ember.transports.json({
            level = "info",
            messageKey = "message",      -- Default: "msg"
            timestampKey = "timestamp",   -- Default: "time"
            levelKey = "severity",        -- Default: "level"
        }),
    },
})

log:info("User login", { userId = 42 })
```

Output:

```json
{"severity":"info","message":"User login","timestamp":1705312245,"userId":42}
```

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `level` | string | Logger level | Minimum level for this transport |
| `messageKey` | string | `"msg"` | JSON key for the message field |
| `timestampKey` | string | `"time"` | JSON key for the timestamp |
| `levelKey` | string | `"level"` | JSON key for the log level |
| `stream` | function | `print` | Output function |
| `formatter` | table | JSON formatter | Custom formatter override |

## Custom Transports

Create custom transports using `ember.transport()`:

```lua
local myTransport = ember.transport({
    name = "webhook",                    -- Required: unique name
    level = "error",                     -- Optional: minimum level
    formatter = ember.formatters.json(), -- Optional: custom formatter

    write = function(entry, formatted)   -- Required: write function
        -- entry: the raw log entry table
        -- formatted: string from the formatter
        http.post("https://hooks.example.com/logs", {
            body = formatted,
            headers = { ["Content-Type"] = "application/json" },
        })
    end,

    close = function()                   -- Optional: cleanup
        -- Called when logger:close() is invoked
    end,
})

local log = ember({
    transports = { myTransport },
})
```

### Transport Definition

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Unique identifier for the transport |
| `write` | function(entry, formatted) | Yes | Called for each log entry that passes the level filter |
| `level` | string or nil | No | Minimum level; entries below this are skipped |
| `formatter` | table or nil | No | Formatter for this transport; falls back to logger default |
| `close` | function or nil | No | Cleanup function called on `logger:close()` |

### The Entry Object

The `entry` parameter passed to `write` has this structure:

```lua
{
    level = "info",           -- Level name
    levelNumber = 30,         -- Numeric level value
    message = "Hello world",  -- Log message
    timestamp = 1705312245,   -- os.time() epoch seconds
    context = {               -- Merged context table
        requestId = "abc",
        userId = 42,
    },
    name = "my-app",          -- Logger name (or nil)
}
```

### Examples

**Database transport:**

```lua
local dbTransport = ember.transport({
    name = "database",
    level = "warn",
    write = function(entry, formatted)
        db:execute(
            "INSERT INTO logs (level, message, context, created_at) VALUES (?, ?, ?, ?)",
            entry.level,
            entry.message,
            json.encode(entry.context),
            entry.timestamp
        )
    end,
})
```

**In-memory buffer transport:**

```lua
local buffer = {}

local bufferTransport = ember.transport({
    name = "buffer",
    write = function(entry, formatted)
        buffer[#buffer + 1] = entry
        -- Flush when buffer is large
        if #buffer >= 100 then
            sendBatch(buffer)
            buffer = {}
        end
    end,
    close = function()
        if #buffer > 0 then
            sendBatch(buffer)
        end
    end,
})
```

**Filtered transport (only specific contexts):**

```lua
local auditTransport = ember.transport({
    name = "audit",
    write = function(entry, formatted)
        -- Only log entries with an audit flag
        if entry.context.audit then
            fs.append("./logs/audit.log", formatted .. "\n")
        end
    end,
})

log:info("User permission changed", { audit = true, userId = 42, role = "admin" })
```

## Per-Transport Level Filtering

Each transport can have its own minimum level independent of the logger level:

```lua
local log = ember({
    level = "debug",  -- Logger accepts debug and above
    transports = {
        ember.transports.console({ level = "debug" }),   -- Console gets everything
        ember.transports.file({
            path = "./logs/errors.log",
            level = "error",                              -- File only gets errors
        }),
    },
})

log:debug("Verbose info")   -- Console only
log:error("Something broke") -- Console AND file
```

The filtering hierarchy is:

1. **Logger level** — first gate; if the entry is below the logger level, it's discarded immediately
2. **Transport level** — second gate; each transport filters independently

## Fault Tolerance

Every `transport.write()` call is wrapped in `pcall`. If a transport throws an error:

- The error is printed to stdout: `[ember] Transport 'name' error: ...`
- All remaining transports still receive the entry
- The logger continues to function normally

This means a network failure in a webhook transport won't prevent the console or file transport from logging.
