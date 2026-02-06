# Ember Logging

Ember is a structured logging library for CopperMoon. Inspired by Pino, Winston, and Go's slog, it provides fast, extensible logging with transports, formatters, child loggers, and first-class integrations with HoneyMoon, Lantern, and Freight.

## Features

- **Zero-config defaults** — one line to start logging with colored output
- **Structured context** — attach key-value data to every log entry
- **Child loggers** — inherit context from parents, share transports by reference
- **6 log levels** — trace, debug, info, warn, error, fatal
- **Pluggable transports** — console, file (with rotation), JSON, or build your own
- **Pluggable formatters** — text, JSON (Pino-style flat), pretty (colored), or custom
- **Per-transport filtering** — each transport can have its own minimum level
- **HoneyMoon integration** — automatic `req.log` child logger per request
- **Lantern integration** — bridge logs into the Lantern debug panel
- **Freight integration** — automatic database query logging with slow query detection
- **Fault-tolerant** — one transport failure never breaks others (pcall isolation)

## Quick Start

```lua
local ember = require("ember")

-- Zero-config: console output, info level, colored
local log = ember()
log:info("Server starting")
log:warn("Cache miss", { key = "user:42" })
```

Output:

```
10:30:45 INF coppermine > Server starting
10:30:45 WRN coppermine > Cache miss key=user:42
```

## Philosophy

Ember follows three principles:

**Easy to learn** — Create a logger in one line. Use `log:info()`, `log:warn()`, `log:error()`. Context is a plain Lua table. No configuration files, no XML, no complex setup.

**Hard to master** — Per-transport formatters, custom transport pipelines, child logger context inheritance, level-gated transports, Lantern bridge middleware. The depth is there when you need it.

**Deep to understand** — The internal pipeline is transparent: level check, context merge, entry creation, transport fanout with pcall isolation. Each piece is a simple Lua module you can read and extend.

## Architecture

```
log:info("msg", { key = "val" })
  |
  v
Level check (fast path - zero allocations if filtered)
  |
  v
Context merge (parent + call-site)
  |
  v
Entry creation { level, message, timestamp, context, name }
  |
  v
Transport fanout (each wrapped in pcall)
  |
  +---> Transport A: Formatter.format(entry) -> Transport.write(entry, formatted)
  +---> Transport B: Formatter.format(entry) -> Transport.write(entry, formatted)
  +---> Transport C: ...
```

Child loggers share transports by reference. Adding a transport to the parent affects all children. Context is shallow-merged at child creation time.

## Next Steps

- [Getting Started](/docs/ember/getting-started) — Installation and configuration
- [Loggers & Children](/docs/ember/loggers) — Child loggers, context inheritance
- [Transports](/docs/ember/transports) — Built-in transports and custom transports
- [Formatters](/docs/ember/formatters) — Built-in formatters and custom formatters
- [Integrations](/docs/ember/integrations) — HoneyMoon, Lantern, Freight
- [API Reference](/docs/ember/api) — Complete API documentation
