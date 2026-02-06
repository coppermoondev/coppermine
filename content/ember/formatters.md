# Formatters

Formatters transform a log entry into a string. Each transport can have its own formatter, or fall back to the logger's default formatter.

## Built-in Formatters

### Text Formatter

Plain text output suitable for log files. No colors.

```lua
local fmt = ember.formatters.text({
    timestamp = true,                           -- Show timestamp (default: true)
    timestampFormat = "!%Y-%m-%dT%H:%M:%SZ",   -- ISO 8601 UTC (default)
    showName = true,                            -- Show logger name (default: true)
    showContext = true,                          -- Show context key=value (default: true)
})
```

Output:

```
[2024-01-15T10:30:45Z] INFO  my-app: User login {ip=192.168.1.1, userId=42}
```

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `timestamp` | boolean | `true` | Show timestamp |
| `timestampFormat` | string | `"!%Y-%m-%dT%H:%M:%SZ"` | Format string for `os.date()` |
| `showName` | boolean | `true` | Show logger name |
| `showContext` | boolean | `true` | Show context as key=value pairs |

Context keys are sorted alphabetically for consistent output.

### JSON Formatter

Structured JSON output where context fields are flattened to the top level (Pino-style).

```lua
local fmt = ember.formatters.json({
    messageKey = "msg",        -- Default: "msg"
    timestampKey = "time",     -- Default: "time"
    levelKey = "level",        -- Default: "level"
})
```

Output:

```json
{"level":"info","msg":"User login","time":1705312245,"name":"my-app","userId":42,"ip":"192.168.1.1"}
```

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `messageKey` | string | `"msg"` | JSON key for the message |
| `timestampKey` | string | `"time"` | JSON key for the timestamp |
| `levelKey` | string | `"level"` | JSON key for the level |

**Context flattening:** Context fields are merged into the top-level JSON object, following Pino's convention. Reserved keys (`level`, `msg`, `time`, `name`, `levelNumber`) are never overwritten by context values.

### Pretty Formatter

Colored human-readable output for development. Uses ANSI escape codes.

```lua
local fmt = ember.formatters.pretty({
    colors = true,             -- Enable ANSI colors (default: true)
    timestamp = true,          -- Show timestamp (default: true)
    timestampFormat = "%H:%M:%S",  -- Time only (default)
})
```

Output (with colors):

```
10:30:45 INF my-app > User login userId=42 ip=192.168.1.1
```

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `colors` | boolean | `true` | Enable ANSI colors |
| `timestamp` | boolean | `true` | Show timestamp |
| `timestampFormat` | string | `"%H:%M:%S"` | Format string for `os.date()` |

**Color scheme:**

| Level | Label | Color |
|-------|-------|-------|
| trace | TRC | Gray |
| debug | DBG | Cyan |
| info | INF | Green |
| warn | WRN | Yellow |
| error | ERR | Red |
| fatal | FTL | Bright Red + Bold |

Additional styling:
- Timestamps are dimmed
- Logger name is magenta
- Context keys are dimmed, values are normal
- The `>` separator is dimmed

## Custom Formatters

Create custom formatters using `ember.formatter()`:

### From a Function

```lua
local myFormatter = ember.formatter(function(entry)
    return string.format("[%s] %s: %s",
        entry.level:upper(),
        entry.name or "app",
        entry.message
    )
end)
```

### From a Table

```lua
local myFormatter = ember.formatter({
    name = "custom",
    format = function(entry)
        return string.format("%s|%s|%s|%s",
            os.date("%Y-%m-%d %H:%M:%S", entry.timestamp),
            entry.level,
            entry.message,
            json.encode(entry.context)
        )
    end,
})
```

### Formatter Interface

A formatter must have a `format` function:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | No | Identifier (defaults to "custom") |
| `format` | function(entry) -> string | Yes | Transforms a log entry into a string |

The `entry` parameter:

```lua
{
    level = "info",           -- Level name
    levelNumber = 30,         -- Numeric level
    message = "Hello",        -- Message string
    timestamp = 1705312245,   -- Epoch seconds (os.time())
    context = { ... },        -- Merged context table
    name = "my-app",          -- Logger name (or nil)
}
```

## Using Formatters

### Per-Logger Default

Set a default formatter for the logger. Transports without their own formatter will use this:

```lua
local log = ember({
    formatter = ember.formatters.json(),
    transports = {
        ember.transports.console(),  -- Uses JSON formatter
    },
})
```

### Per-Transport Override

Each transport can override the logger's default formatter:

```lua
local log = ember({
    formatter = ember.formatters.text(),  -- Default
    transports = {
        -- This transport uses pretty instead of text
        ember.transports.console({
            formatter = ember.formatters.pretty({ colors = true }),
        }),
        -- This transport uses the default (text)
        ember.transports.file({ path = "./logs/app.log" }),
    },
})
```

### Formatter Resolution Order

When a transport needs to format an entry:

1. **Transport formatter** — if the transport has a `formatter` field, use it
2. **Logger formatter** — if the logger has a `_formatter`, use it
3. **Fallback** — `[LEVEL] message` (minimal format, no context)

## Examples

### CSV Formatter

```lua
local csvFormatter = ember.formatter(function(entry)
    return string.format('%s,"%s","%s","%s"',
        os.date("!%Y-%m-%dT%H:%M:%SZ", entry.timestamp),
        entry.level,
        entry.message:gsub('"', '""'),  -- Escape quotes
        json.encode(entry.context):gsub('"', '""')
    )
end)

local log = ember({
    transports = {
        ember.transports.file({
            path = "./logs/app.csv",
            formatter = csvFormatter,
        }),
    },
})
```

### Syslog-style Formatter

```lua
local syslogFormatter = ember.formatter(function(entry)
    local facility = 1  -- user-level
    local severities = { trace = 7, debug = 7, info = 6, warn = 4, error = 3, fatal = 2 }
    local severity = severities[entry.level] or 6
    local priority = facility * 8 + severity

    return string.format("<%d>%s %s: %s",
        priority,
        os.date("!%b %d %H:%M:%S", entry.timestamp),
        entry.name or "app",
        entry.message
    )
end)
```

### Compact Formatter

```lua
local compactFormatter = ember.formatter(function(entry)
    local prefix = entry.level:sub(1, 1):upper()
    local ctx = ""
    if entry.context and next(entry.context) then
        local parts = {}
        for k, v in pairs(entry.context) do
            parts[#parts + 1] = k .. "=" .. tostring(v)
        end
        ctx = " " .. table.concat(parts, " ")
    end
    return string.format("%s %s%s", prefix, entry.message, ctx)
end)
-- Output: "I User login userId=42"
```
