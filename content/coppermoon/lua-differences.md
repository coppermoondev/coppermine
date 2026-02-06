# Lua Differences

CopperMoon runs Lua 5.4 with some differences from the standard Lua distribution. This page covers what's added, changed, and restricted.

## Safe Mode

CopperMoon loads standard libraries in **safe mode** (`ALL_SAFE`). This disables potentially dangerous operations while keeping the language fully functional.

### Disabled

| Feature | Reason |
|---------|--------|
| `debug` library | Disabled entirely in safe mode |
| `os.execute()` | Use `process.exec()` instead |
| `os.remove()` | Use `fs.remove()` instead |
| `os.rename()` | Use `fs.rename()` instead |
| `os.getenv()` | Use `os_ext.env()` instead |
| `loadfile()` from arbitrary paths | Restricted in safe mode |
| C module loading | Cannot load `.so`/`.dll` modules |

### Available

All core Lua features remain available:

- Variables, functions, closures
- Tables, metatables, metamethods
- String patterns and manipulation
- Math operations
- Coroutines
- `pcall()` and `xpcall()` for error handling
- `require()` for Lua modules
- `io` library for basic I/O
- `os.clock()`, `os.date()`, `os.time()`, `os.difftime()`
- `utf8` library
- `table` library (`insert`, `remove`, `sort`, `concat`, `move`, `pack`, `unpack`)
- `string` library (all functions including `format`, `match`, `gmatch`, `gsub`)
- `math` library (all functions)

## Additional Global Modules

CopperMoon adds these modules as globals (no `require()` needed):

| Module | Purpose |
|--------|---------|
| `fs` | File system (read, write, mkdir, stat, etc.) |
| `path` | Path manipulation (join, dirname, basename, etc.) |
| `json` | JSON encode/decode |
| `crypto` | Hashing (SHA-256, SHA-1, MD5), HMAC, base64, UUID |
| `time` | Timestamps, sleep, formatting |
| `http` | HTTP client (get, post, put, delete) and server |
| `net` | TCP and UDP networking |
| `process` | Shell execution, process info |
| `os_ext` | Environment variables, platform, hostname |
| `sqlite` | SQLite database access |
| `mysql` | MySQL database access |

## Additional Global Functions

### Timers

```lua
local id = setTimeout(function()
    print("Delayed!")
end, 1000)

local id = setInterval(function()
    print("Repeated!")
end, 500)

clearTimeout(id)
clearInterval(id)
```

### Enhanced print()

CopperMoon's `print()` provides better formatting for tables and complex values compared to standard Lua.

## Module System

### require()

`require()` works for Lua modules. CopperMoon sets up a custom module loader that resolves modules from the filesystem following Lua's `package.path`.

```lua
local myLib = require("mylib")
local sub = require("mylib.submodule")
```

### No C Modules

C modules (`.so`, `.dll`) cannot be loaded in safe mode. The `package.cpath` searcher is disabled. If you need native functionality, use CopperMoon's built-in modules or write a Rust extension.

### Custom Searcher Workaround

In some cases, the built-in `require` searcher may not find Lua files correctly. You can add a custom searcher:

```lua
local function luaSearcher(modname)
    local path = modname:gsub("%.", "/")
    for pattern in package.path:gmatch("[^;]+") do
        local filepath = pattern:gsub("%?", path)
        local fn = loadfile(filepath)
        if fn then return fn, filepath end
    end
end
table.insert(package.searchers, 2, luaSearcher)
```

## Comparison Table

| Feature | Standard Lua 5.4 | CopperMoon |
|---------|-------------------|------------|
| `debug` library | Available | Disabled |
| C modules | Available | Disabled |
| `os.execute()` | Available | Use `process.exec()` |
| `os.remove()` | Available | Use `fs.remove()` |
| `os.getenv()` | Available | Use `os_ext.env()` |
| HTTP | Not available | `http` module |
| File system | Basic `io` only | Full `fs` module |
| JSON | Not available | `json` module |
| Crypto | Not available | `crypto` module |
| Networking | Not available | `net` module |
| Database | Not available | `sqlite`, `mysql` modules |
| Timers | Not available | `setTimeout`, `setInterval` |
| Path utilities | Not available | `path` module |
