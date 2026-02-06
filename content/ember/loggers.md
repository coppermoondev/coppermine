# Loggers & Children

## Creating a Logger

The `ember()` factory creates a new Logger instance:

```lua
local ember = require("ember")

-- Using the callable shorthand
local log = ember({ name = "my-app", level = "debug" })

-- Equivalent to:
local log = ember.new({ name = "my-app", level = "debug" })
```

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `level` | string or number | `"info"` | Minimum log level |
| `name` | string or nil | `nil` | Logger name (appears in formatted output) |
| `context` | table | `{}` | Default context merged into every entry |
| `transports` | table | Console with colors | Array of transport instances |
| `formatter` | table or nil | `nil` | Default formatter (transports use their own if set) |

## Logging Messages

All log methods follow the same pattern: `logger:level(message, context)`.

```lua
log:trace("Loop iteration", { i = 42 })
log:debug("Cache lookup", { key = "user:42" })
log:info("Server started", { port = 3000 })
log:warn("Slow query", { duration = 250 })
log:error("Connection failed", { host = "db.local" })
log:fatal("Data corruption detected", { table = "users" })
```

The generic `log()` method accepts the level as first argument:

```lua
log:log("info", "Hello", { key = "val" })
```

### Context Merging

When you call `log:info("msg", ctx)`, the call-site context is merged with the logger's base context. Call-site values override base values:

```lua
local log = ember({
    context = { service = "api", version = "2.0" },
})

log:info("Request", { path = "/users", version = "override" })
-- Merged context: { service = "api", version = "override", path = "/users" }
```

When no call-site context is provided, the base context is used directly without any allocation:

```lua
log:info("Simple message")
-- Uses self._context directly — no table created
```

## Child Loggers

Child loggers are the core pattern for adding request-scoped or module-scoped context. They share transports with their parent by reference.

```lua
local log = ember({ name = "api", level = "debug" })

-- Create a child with additional context
local reqLog = log:child({ requestId = "abc-123", userId = 42 })
reqLog:info("Processing request")
-- Context: { requestId = "abc-123", userId = 42 }

reqLog:info("Fetching data", { table = "users" })
-- Context: { requestId = "abc-123", userId = 42, table = "users" }
```

### Context Inheritance

Child context is shallow-merged with the parent context at creation time. Child values override parent values:

```lua
local parent = ember({
    context = { env = "prod", region = "us-east" },
})

local child = parent:child({ region = "eu-west", tier = "premium" })
child:info("Hello")
-- Context: { env = "prod", region = "eu-west", tier = "premium" }
```

### Nested Children

Children can create their own children. Context accumulates through the chain:

```lua
local app = ember({ name = "api" })
local mod = app:child({ module = "auth" })
local req = mod:child({ requestId = "xyz" })

req:info("Login attempt")
-- Context: { module = "auth", requestId = "xyz" }
```

### Transport Sharing

Children share transports by reference with their parent. This means:

- Adding a transport to the parent affects all existing children
- Children don't duplicate transport instances
- All loggers in the hierarchy write to the same destinations

```lua
local log = ember()
local child = log:child({ scope = "worker" })

-- Adding a transport to parent also affects child
log:addTransport(ember.transports.file({ path = "./logs/app.log" }))

-- Both log and child now write to console AND file
child:info("This goes to both transports")
```

### Level Independence

Each child can have its own level, independent of the parent:

```lua
local log = ember({ level = "info" })
local verbose = log:child({ module = "debug-target" })
verbose:setLevel("trace")

log:trace("Filtered out")        -- Below info threshold
verbose:trace("This appears")    -- trace >= trace
```

## Level Management

### Check and Change Levels

```lua
-- Get current level
print(log:getLevel())  -- "info"

-- Change level at runtime
log:setLevel("debug")

-- Check if a level would produce output
if log:isLevelEnabled("debug") then
    -- Avoid expensive computation for disabled levels
    local data = expensiveDebugInfo()
    log:debug("Debug info", data)
end
```

### Level Resolution

Levels can be specified as strings or numbers:

```lua
log:setLevel("warn")    -- By name
log:setLevel(40)        -- By number (same as "warn")
log:setLevel("warning") -- Alias for "warn"
```

## Transport Management

### Adding Transports

```lua
-- At creation
local log = ember({
    transports = {
        ember.transports.console(),
        ember.transports.file({ path = "./app.log" }),
    },
})

-- After creation
log:addTransport(ember.transports.json())
```

### Removing Transports

```lua
-- Remove by name
log:removeTransport("console")
log:removeTransport("file")
```

### Listing Transports

```lua
local transports = log:getTransports()
for _, t in ipairs(transports) do
    print(t.name)  -- "console", "file", etc.
end
```

### Closing Transports

When shutting down, close all transports to flush pending writes:

```lua
log:close()
```

## Internal Pipeline

When `log:info("msg", ctx)` is called, the following happens:

1. **Level resolve** — `"info"` resolves to numeric `30`
2. **Level check** — if `30 < self._level`, return immediately (zero cost)
3. **Context merge** — if `ctx` is non-empty, shallow-merge with `self._context`; otherwise reuse `self._context` directly
4. **Entry creation** — `{ level = "info", levelNumber = 30, message = "msg", timestamp = os.time(), context = merged, name = self._name }`
5. **Transport fanout** — for each transport:
   - Check transport-level filter
   - Format entry (transport formatter > logger formatter > fallback)
   - Call `transport.write(entry, formatted)` inside `pcall`
   - On error, print `[ember] Transport 'name' error: ...` but continue

This design means disabled levels have zero overhead, and one failing transport never prevents others from receiving the entry.
