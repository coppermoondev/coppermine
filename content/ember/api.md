# API Reference

## Module: ember

```lua
local ember = require("ember")
```

### ember(options) / ember.new(options)

Creates a new Logger instance.

```lua
local log = ember({
    level = "info",
    name = "my-app",
    context = { service = "api" },
    transports = { ember.transports.console() },
    formatter = ember.formatters.text(),
})
```

**Parameters:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `level` | string or number | `"info"` | Minimum log level |
| `name` | string or nil | `nil` | Logger name |
| `context` | table | `{}` | Default context for all entries |
| `transports` | table | `{ console({ colors = true }) }` | Array of transports |
| `formatter` | table or nil | `nil` | Default formatter for transports |

**Returns:** Logger instance

---

### ember.transport(definition)

Creates a custom transport.

```lua
local t = ember.transport({
    name = "my-transport",
    level = "warn",
    formatter = ember.formatters.json(),
    write = function(entry, formatted) ... end,
    close = function() ... end,
})
```

**Parameters:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Transport identifier |
| `write` | function(entry, formatted) | Yes | Called for each log entry |
| `level` | string or nil | No | Minimum level filter |
| `formatter` | table or nil | No | Formatter override |
| `close` | function or nil | No | Cleanup on logger:close() |

**Returns:** Transport table

---

### ember.formatter(fn_or_table)

Creates a custom formatter.

```lua
-- From function
local fmt = ember.formatter(function(entry)
    return entry.level .. ": " .. entry.message
end)

-- From table
local fmt = ember.formatter({
    name = "custom",
    format = function(entry) ... end,
})
```

**Parameters:** A function `(entry) -> string` or a table with `{ name, format }`.

**Returns:** Formatter table with `name` and `format` fields.

---

### ember.honeymoon(logger, options)

Creates HoneyMoon middleware that attaches `req.log` child logger.

```lua
app:use(ember.honeymoon(log, {
    level = "info",
    requestIdHeader = "x-request-id",
    autoLog = true,
    ignorePaths = { "/health" },
    genReqId = function(req) return crypto.uuid() end,
    customProps = function(req) return { ua = req.headers["user-agent"] } end,
}))
```

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `logger` | Logger | Root logger to create children from |
| `options` | table or nil | Middleware options |

**Options:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `level` | string | `"info"` | Request completion log level |
| `requestIdHeader` | string | `"x-request-id"` | Header for request ID |
| `autoLog` | boolean | `true` | Auto-log request completion |
| `ignorePaths` | table | `{}` | Path prefixes to skip |
| `genReqId` | function(req) | `nil` | Custom request ID generator |
| `customProps` | function(req) | `nil` | Extra context per request |

**Returns:** Middleware function `(req, res, next)`

---

### ember.lantern(options)

Creates middleware bridging `req.log` to `req.lantern`.

```lua
app:use(ember.lantern())
```

Must be added after both `ember.honeymoon()` and `lantern.setup()`.

**Returns:** Middleware function `(req, res, next)`

---

### ember.freight(db, logger, options)

Wraps a Freight database instance for query logging.

```lua
ember.freight(db, log, {
    level = "debug",
    slowThreshold = 100,
    includeParams = true,
})
```

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `db` | table | Freight database instance |
| `logger` | Logger | Logger for query entries |
| `options` | table or nil | Configuration |

**Options:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `level` | string | `"debug"` | Normal query log level |
| `slowThreshold` | number | `100` | Slow query threshold in ms |
| `includeParams` | boolean | `true` | Include query parameters |

**Returns:** The wrapped `db` table (same reference, methods replaced)

---

## Class: Logger

### logger:log(level, message, context)

Core logging method. All convenience methods delegate to this.

```lua
log:log("info", "Hello", { key = "val" })
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `level` | string or number | Log level |
| `message` | string | Log message |
| `context` | table or nil | Additional context |

---

### logger:trace(message, context)

Log at trace level (10).

```lua
log:trace("Loop iteration", { i = 42 })
```

---

### logger:debug(message, context)

Log at debug level (20).

```lua
log:debug("Cache lookup", { key = "user:42" })
```

---

### logger:info(message, context)

Log at info level (30).

```lua
log:info("Server started", { port = 3000 })
```

---

### logger:warn(message, context)

Log at warn level (40).

```lua
log:warn("Slow response", { duration = 1500 })
```

---

### logger:error(message, context)

Log at error level (50).

```lua
log:error("Query failed", { sql = "SELECT..." })
```

---

### logger:fatal(message, context)

Log at fatal level (60).

```lua
log:fatal("Data corruption", { table = "users" })
```

---

### logger:child(context)

Creates a child logger with additional context. Shares transports by reference.

```lua
local child = log:child({ requestId = "abc-123" })
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `context` | table | Context to merge with parent |

**Returns:** New Logger instance

---

### logger:setLevel(level)

Changes the minimum log level.

```lua
log:setLevel("debug")
log:setLevel(20)
```

---

### logger:getLevel()

Returns the current level name.

```lua
print(log:getLevel())  -- "info"
```

**Returns:** string

---

### logger:isLevelEnabled(level)

Checks if a level would produce output.

```lua
if log:isLevelEnabled("debug") then
    log:debug("Expensive data", computeDebugInfo())
end
```

**Returns:** boolean

---

### logger:addTransport(transport)

Adds a transport to the logger. Since children share transports by reference, this also affects all child loggers.

```lua
log:addTransport(ember.transports.file({ path = "./app.log" }))
```

---

### logger:removeTransport(name)

Removes a transport by name.

```lua
log:removeTransport("console")
```

**Returns:** boolean (true if removed)

---

### logger:getTransports()

Returns the array of transports.

```lua
for _, t in ipairs(log:getTransports()) do
    print(t.name)
end
```

**Returns:** table (array of transports)

---

### logger:close()

Closes all transports. Calls each transport's `close` function if defined.

```lua
log:close()
```

---

## Tables

### ember.transports

| Name | Factory | Description |
|------|---------|-------------|
| `console` | `ember.transports.console(options)` | Outputs to stdout via `print()` |
| `file` | `ember.transports.file(options)` | Appends to file with rotation |
| `json` | `ember.transports.json(options)` | JSON to stdout for aggregators |

### ember.formatters

| Name | Factory | Description |
|------|---------|-------------|
| `text` | `ember.formatters.text(options)` | Plain text with timestamp and context |
| `json` | `ember.formatters.json(options)` | Flat JSON (Pino-style) |
| `pretty` | `ember.formatters.pretty(options)` | Colored ANSI output |

### ember.levels

Level utilities module.

| Function | Signature | Description |
|----------|-----------|-------------|
| `resolve` | `(level) -> number` | Resolve name/number/nil to numeric value |
| `toName` | `(number) -> string` | Get level name from number |
| `shouldLog` | `(msgLevel, minLevel) -> boolean` | Check if a level passes threshold |
| `isValid` | `(level) -> boolean` | Check if a level exists |

**Level values:**

| Name | Number |
|------|--------|
| trace | 10 |
| debug | 20 |
| info | 30 |
| warn | 40 |
| error | 50 |
| fatal | 60 |

### Log Entry

The entry table passed to formatters and transports:

```lua
{
    level = "info",           -- string: level name
    levelNumber = 30,         -- number: numeric level
    message = "Hello world",  -- string: log message
    timestamp = 1705312245,   -- number: os.time() epoch seconds
    context = { ... },        -- table: merged context
    name = "my-app",          -- string|nil: logger name
}
```
