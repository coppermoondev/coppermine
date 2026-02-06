# CopperMoon Runtime

CopperMoon is a Lua 5.4 runtime built in Rust. It provides a fast, safe execution environment with built-in modules for HTTP, file system, JSON, cryptography, networking, and databases.

## Running Lua Code

```bash
coppermoon script.lua
coppermoon script.lua arg1 arg2
```

Arguments are available in the global `arg` table:

```lua
-- coppermoon script.lua hello world
print(arg[0])   -- "script.lua"
print(arg[1])   -- "hello"
print(arg[2])   -- "world"
```

## Global Constants

| Constant | Type | Description |
|----------|------|-------------|
| `_COPPERMOON_VERSION` | string | Runtime version (e.g. `"0.1.0"`) |

## Built-in Modules

CopperMoon extends standard Lua with these global modules:

| Module | Description |
|--------|-------------|
| `http` | HTTP client and server |
| `json` | JSON encoding and decoding |
| `fs` | File system operations |
| `path` | Path manipulation |
| `time` | Time, timers, and date formatting |
| `crypto` | Hashing, HMAC, encoding, UUID |
| `process` | Process management and shell commands |
| `os_ext` | Environment variables, platform info |
| `buffer` | Binary data manipulation |
| `net` | TCP and UDP networking |
| `term` | Terminal colors, styling, and control |
| `console` | Interactive input (prompts, menus) |
| `sqlite` | SQLite database |
| `mysql` | MySQL database |

CopperMoon also extends the standard `string` and `table` libraries with utility functions like `string.split()`, `string.trim()`, `table.map()`, `table.filter()`, and more.

All modules are available as globals without `require()`.

## Global Timer Functions

JavaScript-style timers:

| Function | Description |
|----------|-------------|
| `setTimeout(fn, ms)` | Run function after delay, returns timer ID |
| `setInterval(fn, ms)` | Run function repeatedly, returns timer ID |
| `clearTimeout(id)` | Cancel a timeout |
| `clearInterval(id)` | Cancel an interval |

## Standard Lua Libraries

CopperMoon loads all standard Lua 5.4 libraries in safe mode:

- `math` - Mathematical functions
- `string` - String manipulation
- `table` - Table operations
- `io` - Input/output
- `os` - Basic OS functions (`os.clock()`, `os.date()`, `os.time()`)
- `coroutine` - Coroutines
- `utf8` - UTF-8 utilities

Some functions are restricted in safe mode. Use CopperMoon's modules instead:

| Instead of | Use |
|-----------|-----|
| `os.execute()` | `process.exec()` |
| `os.remove()` | `fs.remove()` |
| `os.rename()` | `fs.rename()` |
| `os.getenv()` | `os_ext.env()` |
| `debug.*` | Not available in safe mode |

## Quick Example

```lua
-- HTTP server with JSON and file system
local server = http.server.new()

server:get("/", function(ctx)
    return ctx:html("<h1>Hello, CopperMoon!</h1>")
end)

server:get("/api/info", function(ctx)
    return ctx:json({
        version = _COPPERMOON_VERSION,
        platform = os_ext.platform(),
        uptime = time.monotonic(),
    })
end)

server:get("/api/files", function(ctx)
    local files = fs.readdir(".")
    return ctx:json({ files = files })
end)

server:listen(3000, function(port)
    print("Server running on http://localhost:" .. port)
end)
```

## Next Steps

- [Lua Differences](/docs/coppermoon/lua-differences) - What's different from standard Lua
- [Built-in Modules](/docs/coppermoon/built-in-modules) - Complete module reference
- [HTTP Server](/docs/coppermoon/http-server) - Build HTTP servers and clients
- [File System](/docs/coppermoon/filesystem) - Read, write, and manage files
- [JSON](/docs/coppermoon/json) - Encode and decode JSON
- [Time & Date](/docs/coppermoon/time) - Timers, timestamps, formatting
