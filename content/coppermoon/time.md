# Time & Date

The `time` module provides timestamps, sleep, and date formatting. Timer functions (`setTimeout`, `setInterval`) are available as globals. All are available without `require()`.

## Current Time

### time.now()

Get the current Unix timestamp in seconds (with fractional milliseconds).

```lua
local ts = time.now()
print(ts)   -- 1738700000.123
```

### time.now_ms()

Get the current Unix timestamp in milliseconds.

```lua
local ms = time.now_ms()
print(ms)   -- 1738700000123
```

### time.monotonic()

Get monotonic time in seconds. Monotonic time always increases and is not affected by clock adjustments. Use it for measuring durations.

```lua
local start = time.monotonic()
-- ... do work ...
local elapsed = time.monotonic() - start
print("Took " .. elapsed .. " seconds")
```

### time.monotonic_ms()

Get monotonic time in milliseconds.

```lua
local start = time.monotonic_ms()
-- ... do work ...
local elapsed = time.monotonic_ms() - start
print("Took " .. elapsed .. "ms")
```

## Sleep

### time.sleep(ms)

Pause execution for the specified number of milliseconds.

```lua
print("Starting...")
time.sleep(1000)   -- Sleep for 1 second
print("Done!")

time.sleep(500)    -- Sleep for 500ms
```

## Formatting

### time.format(timestamp, format?)

Format a Unix timestamp as a human-readable string.

```lua
local ts = time.now()

time.format(ts)                    -- "2025-02-04 14:30:45"
time.format(ts, "%Y-%m-%d")       -- "2025-02-04"
time.format(ts, "%H:%M:%S")       -- "14:30:45"
time.format(ts, "%d/%m/%Y")       -- "04/02/2025"
time.format(ts, "%A, %B %d %Y")   -- "Tuesday, February 04 2025"
```

Default format: `"%Y-%m-%d %H:%M:%S"`

Common format specifiers:

| Specifier | Output | Example |
|-----------|--------|---------|
| `%Y` | 4-digit year | `2025` |
| `%m` | Month (01-12) | `02` |
| `%d` | Day (01-31) | `04` |
| `%H` | Hour, 24h (00-23) | `14` |
| `%I` | Hour, 12h (01-12) | `02` |
| `%M` | Minute (00-59) | `30` |
| `%S` | Second (00-59) | `45` |
| `%A` | Full weekday name | `Tuesday` |
| `%B` | Full month name | `February` |
| `%p` | AM/PM | `PM` |
| `%Z` | Timezone abbreviation | `UTC` |

### time.parse(string, format?)

Parse a date/time string into a Unix timestamp. Accepts ISO 8601 format by default.

```lua
local ts = time.parse("2025-02-04T14:30:00Z")
print(ts)   -- 1738679400.0
```

## Timers

Timer functions are available as globals, similar to JavaScript.

### setTimeout(fn, ms)

Schedule a function to run once after a delay. Returns a timer ID.

```lua
local id = setTimeout(function()
    print("This runs after 2 seconds")
end, 2000)
```

### setInterval(fn, ms)

Schedule a function to run repeatedly at a fixed interval. Returns a timer ID.

```lua
local id = setInterval(function()
    print("This runs every second")
end, 1000)
```

### clearTimeout(id)

Cancel a scheduled timeout.

```lua
local id = setTimeout(function()
    print("This won't run")
end, 5000)

clearTimeout(id)
```

### clearInterval(id)

Cancel a scheduled interval.

```lua
local id = setInterval(function()
    print("Tick")
end, 1000)

-- Stop after 5 seconds
setTimeout(function()
    clearInterval(id)
    print("Stopped")
end, 5000)
```

## Practical Examples

### Measure execution time

```lua
local function benchmark(name, fn)
    local start = time.monotonic_ms()
    fn()
    local elapsed = time.monotonic_ms() - start
    print(name .. ": " .. elapsed .. "ms")
end

benchmark("file read", function()
    fs.read("large-file.txt")
end)
```

### Timestamp in logs

```lua
local function log(level, message)
    local ts = time.format(time.now())
    print("[" .. ts .. "] [" .. level .. "] " .. message)
end

log("INFO", "Server started")
log("ERROR", "Connection failed")
-- [2025-02-04 14:30:45] [INFO] Server started
-- [2025-02-04 14:30:46] [ERROR] Connection failed
```

### Rate limiter

```lua
local lastRequest = {}

local function rateLimit(clientId, limitMs)
    local now = time.now_ms()
    local last = lastRequest[clientId] or 0

    if now - last < limitMs then
        return false  -- Too many requests
    end

    lastRequest[clientId] = now
    return true
end
```

### Cache with expiry

```lua
local cache = {}

local function cacheSet(key, value, ttlMs)
    cache[key] = {
        value = value,
        expires = time.now_ms() + ttlMs,
    }
end

local function cacheGet(key)
    local entry = cache[key]
    if not entry then return nil end
    if time.now_ms() > entry.expires then
        cache[key] = nil
        return nil
    end
    return entry.value
end

cacheSet("user:1", { name = "Alice" }, 60000)  -- 1 minute TTL
local user = cacheGet("user:1")
```

## Standard os Functions

Lua's built-in `os` module also provides time functions:

```lua
os.time()          -- Current time as integer (seconds)
os.clock()         -- CPU time used (seconds, float)
os.date()          -- Formatted date string
os.date("%Y-%m-%d") -- Formatted with specifier
os.difftime(t2, t1) -- Difference in seconds
```

Use `time.now()` for higher precision timestamps and `time.monotonic()` for duration measurements.
