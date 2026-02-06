# Time & DateTime

A complete date and time toolkit built into CopperMoon's standard library. The `time` module provides timestamps, timers, and a full-featured **DateTime** type inspired by Moment.js — immutable, chainable, with Moment.js-style format tokens and relative time humanization.

## Quick Start

### Get the Current Date

```lua
local now = time.date()
print(now:format("dddd, MMMM DD YYYY"))  -- "Wednesday, February 05 2026"
print(now:format("HH:mm:ss"))            -- "14:30:00"
```

### Create Dates

```lua
-- From components
local d = time.date(2024, 6, 15)
local d = time.date(2024, 6, 15, 14, 30, 0)

-- From a string
local d = time.date("2024-06-15")
local d = time.date("2024-06-15T14:30:00")

-- From a Unix timestamp
local d = time.date(1718458200)

-- UTC dates
local d = time.utc()
local d = time.utc(2024, 6, 15, 14, 30, 0)
```

### Date Arithmetic

```lua
local d = time.date(2024, 1, 31)
local next_month = d:add(1, "month")   -- 2024-02-29 (leap year!)
local next_week = d:add(1, "week")     -- 2024-02-07
local yesterday = d:sub(1, "day")      -- 2024-01-30
```

### Format and Compare

```lua
local a = time.date(2024, 1, 1)
local b = time.date(2024, 12, 31)

print(a:format("DD/MM/YYYY"))     -- "01/01/2024"
print(a:isBefore(b))              -- true
print(b:diff(a, "days"))          -- 365.0
print(a:fromNow())                -- "2 years ago"
```

## Creating Dates

### `time.date(...)`

Creates a DateTime in the **local timezone**. Accepts multiple argument forms:

```lua
-- No arguments: current local time
local now = time.date()

-- From a Unix timestamp (number)
local d = time.date(1718458200)

-- From a string (auto-detected format)
local d = time.date("2024-06-15")
local d = time.date("2024-06-15T14:30:00")
local d = time.date("2024-06-15 14:30:00")
local d = time.date("2024-06-15T14:30:00+02:00")

-- From components: year, month, day [, hour, min, sec, ms]
local d = time.date(2024, 6, 15)
local d = time.date(2024, 6, 15, 14, 30, 0)
local d = time.date(2024, 6, 15, 14, 30, 0, 500)
```

When parsing strings without timezone information, the local timezone is assumed. If the string includes an explicit offset (like `+02:00` or `Z`), that offset is used.

### `time.utc(...)`

Creates a DateTime in **UTC**. Same argument forms as `time.date`:

```lua
local now = time.utc()
local d = time.utc(2024, 6, 15, 14, 30, 0)
local d = time.utc("2024-06-15T14:30:00")
```

When parsing strings without timezone information, UTC is assumed.

### Supported String Formats

The parser auto-detects these formats:

| Format | Example |
|--------|---------|
| ISO 8601 / RFC 3339 | `2024-06-15T14:30:00Z` |
| ISO with offset | `2024-06-15T14:30:00+02:00` |
| ISO with milliseconds | `2024-06-15T14:30:00.500Z` |
| Date and time (space) | `2024-06-15 14:30:00` |
| Date and time (slash) | `2024/06/15 14:30:00` |
| Date only | `2024-06-15` |
| Date only (slash) | `2024/06/15` |

## Getters

All getters return a single value from the DateTime:

```lua
local d = time.date(2024, 6, 15, 14, 30, 45)

d:year()        -- 2024
d:month()       -- 6       (1-12)
d:day()         -- 15      (1-31)
d:hour()        -- 14      (0-23)
d:minute()      -- 30      (0-59)
d:second()      -- 45      (0-59)
d:milli()       -- 0       (0-999)

d:weekday()     -- 6       (1=Monday, 7=Sunday)
d:yearday()     -- 167     (1-366)

d:timestamp()   -- 1718458245.0   (Unix seconds, float)
d:timestamp_ms() -- 1718458245000 (Unix milliseconds, integer)

d:offset()      -- 1.0     (UTC offset in hours)
d:isUTC()       -- false
```

## Setters

The `set` method returns a **new** DateTime with updated fields. The original is unchanged (immutable):

```lua
local d = time.date(2024, 6, 15, 14, 30, 0)

local d2 = d:set({ year = 2025 })
-- 2025-06-15T14:30:00 (only year changed)

local d3 = d:set({ month = 12, day = 25, hour = 10 })
-- 2024-12-25T10:30:00 (month, day, and hour changed)
```

Available fields: `year`, `month`, `day`, `hour`, `minute`, `second`, `milli`.

## Arithmetic

All arithmetic methods return **new** DateTime instances (immutable). They accept two forms:

### Amount + Unit

```lua
local d = time.date(2024, 1, 15)

d:add(7, "days")          -- 2024-01-22
d:add(3, "months")        -- 2024-04-15
d:add(1, "year")          -- 2025-01-15
d:add(2, "hours")         -- 2024-01-15T02:00:00
d:sub(30, "minutes")      -- 2024-01-14T23:30:00
d:sub(1, "week")          -- 2024-01-08
```

### Table Form

Add or subtract multiple units at once:

```lua
local d2 = d:add({ years = 1, months = 2, days = 3 })
local d3 = d:sub({ hours = 5, minutes = 30 })
```

Months and years are applied first (calendar arithmetic), then days/hours/minutes/seconds (duration arithmetic).

### Accepted Units

Both singular and plural forms are accepted:

| Unit | Aliases |
|------|---------|
| `years` | `year`, `y` |
| `months` | `month`, `M` |
| `weeks` | `week`, `w` |
| `days` | `day`, `d` |
| `hours` | `hour`, `h` |
| `minutes` | `minute`, `m` |
| `seconds` | `second`, `s` |
| `milliseconds` | `millisecond`, `ms` |

### Month Arithmetic Edge Cases

Month arithmetic clamps to the last valid day, following Moment.js behavior:

```lua
local jan31 = time.date(2024, 1, 31)
jan31:add(1, "month")   -- 2024-02-29 (leap year, clamped to 29)

local jan31_2023 = time.date(2023, 1, 31)
jan31_2023:add(1, "month")  -- 2023-02-28 (non-leap, clamped to 28)

local mar31 = time.date(2024, 3, 31)
mar31:add(1, "month")   -- 2024-04-30 (April has 30 days)
```

## Formatting

Format dates using **Moment.js-style tokens**:

```lua
local d = time.date(2024, 6, 15, 14, 30, 0)

d:format("YYYY-MM-DD")               -- "2024-06-15"
d:format("DD/MM/YYYY")               -- "15/06/2024"
d:format("dddd, MMMM DD YYYY")       -- "Saturday, June 15 2024"
d:format("HH:mm:ss")                 -- "14:30:00"
d:format("hh:mm A")                  -- "02:30 PM"
d:format("ddd MMM D, YYYY")          -- "Sat Jun 15, 2024"
d:format("YY-MM-DD")                 -- "24-06-15"
d:format("YYYY-MM-DDTHH:mm:ssZ")     -- "2024-06-15T14:30:00+01:00"
```

### Escape Literal Text

Use square brackets to escape text that shouldn't be interpreted as tokens:

```lua
d:format("[Date:] YYYY-MM-DD")  -- "Date: 2024-06-15"
d:format("[Today is] dddd")     -- "Today is Saturday"
```

### Format Tokens

| Token | Output | Example |
|-------|--------|---------|
| `YYYY` | 4-digit year | `2024` |
| `YY` | 2-digit year | `24` |
| `MMMM` | Full month name | `January` |
| `MMM` | Short month name | `Jan` |
| `MM` | Month (zero-padded) | `01` |
| `M` | Month | `1` |
| `DD` | Day of month (zero-padded) | `05` |
| `D` | Day of month | `5` |
| `dddd` | Full weekday name | `Monday` |
| `ddd` | Short weekday name | `Mon` |
| `dd` | Min weekday name | `Mo` |
| `d` | Weekday number (1=Mon) | `1` |
| `HH` | Hour 24h (zero-padded) | `09` |
| `H` | Hour 24h | `9` |
| `hh` | Hour 12h (zero-padded) | `02` |
| `h` | Hour 12h | `2` |
| `mm` | Minute (zero-padded) | `05` |
| `m` | Minute | `5` |
| `ss` | Second (zero-padded) | `03` |
| `s` | Second | `3` |
| `SSS` | Milliseconds | `042` |
| `A` | AM/PM | `PM` |
| `a` | am/pm | `pm` |
| `Z` | UTC offset | `+01:00` |
| `ZZ` | UTC offset (compact) | `+0100` |
| `X` | Unix timestamp (seconds) | `1718458200` |
| `x` | Unix timestamp (ms) | `1718458200000` |

### Shorthand Methods

```lua
d:format()    -- default: "YYYY-MM-DDTHH:mm:ssZ" (ISO-like)
d:toISO()     -- "2024-06-15T14:30:00.000+01:00" (with milliseconds)
d:toDate()    -- "2024-06-15"
d:toTime()    -- "14:30:00"
tostring(d)   -- same as toISO()
```

## Comparison

### Method-Based

```lua
local a = time.date(2024, 1, 1)
local b = time.date(2024, 12, 31)

a:isBefore(b)    -- true
a:isAfter(b)     -- false
a:isSame(b)      -- false
a:isSame(a:clone())  -- true

local mid = time.date(2024, 6, 15)
mid:isBetween(a, b)  -- true (exclusive bounds)
```

### Operator-Based

DateTime supports Lua comparison operators:

```lua
a < b       -- true
a <= b      -- true
a == a:clone()  -- true
b > a       -- true
```

### Subtraction

Subtracting two DateTimes returns the difference in **seconds**:

```lua
local diff = b - a   -- 31536000.0 (seconds in a year)
```

## Diff

Calculate the difference between two dates in any unit:

```lua
local a = time.date(2024, 1, 1)
local b = time.date(2024, 6, 15)

b:diff(a, "days")         -- 166.0
b:diff(a, "months")       -- 5.0
b:diff(a, "hours")        -- 3984.0
b:diff(a, "weeks")        -- 23.71...
b:diff(a, "years")        -- 0.416...
b:diff(a, "seconds")      -- 14342400.0
b:diff(a, "milliseconds") -- 14342400000.0
b:diff(a)                 -- 14342400.0 (default: seconds)
```

The result is `self - other`. Positive means `self` is after `other`, negative means before.

## Start/End of Period

Snap a date to the boundary of a time period. Returns a new DateTime:

```lua
local d = time.date(2024, 6, 15, 14, 30, 45)

-- Start of period (set to earliest moment)
d:startOf("year")     -- 2024-01-01 00:00:00
d:startOf("month")    -- 2024-06-01 00:00:00
d:startOf("week")     -- 2024-06-10 00:00:00 (Monday)
d:startOf("day")      -- 2024-06-15 00:00:00
d:startOf("hour")     -- 2024-06-15 14:00:00
d:startOf("minute")   -- 2024-06-15 14:30:00

-- End of period (set to latest moment)
d:endOf("year")       -- 2024-12-31 23:59:59.999
d:endOf("month")      -- 2024-06-30 23:59:59.999
d:endOf("week")       -- 2024-06-16 23:59:59.999 (Sunday)
d:endOf("day")        -- 2024-06-15 23:59:59.999
d:endOf("hour")       -- 2024-06-15 14:59:59.999
d:endOf("minute")     -- 2024-06-15 14:30:59.999
```

Weeks start on Monday (ISO 8601).

## Relative Time

Humanize the difference between dates in natural language:

```lua
local past = time.utc():sub(3, "hours")
past:fromNow()    -- "3 hours ago"

local future = time.utc():add(2, "days")
future:fromNow()  -- "in 2 days"
future:toNow()    -- "2 days ago" (inverse perspective)
```

### Between Two Dates

```lua
local a = time.date(2024, 1, 1)
local b = time.date(2024, 7, 15)

a:from(b)   -- "6 months ago" (a is 6 months before b)
a:to(b)     -- "in 6 months"  (from a to b is 6 months forward)
```

### Humanization Thresholds

| Range | Output |
|-------|--------|
| 0-44 seconds | "a few seconds ago" |
| 45-89 seconds | "a minute ago" |
| 90 seconds - 44 minutes | "X minutes ago" |
| 45-89 minutes | "an hour ago" |
| 90 minutes - 21 hours | "X hours ago" |
| 22-35 hours | "a day ago" |
| 36 hours - 25 days | "X days ago" |
| 26-45 days | "a month ago" |
| 46-345 days | "X months ago" |
| 346-547 days | "a year ago" |
| 548+ days | "X years ago" |

## Timezone Conversion

```lua
local local_dt = time.date(2024, 6, 15, 14, 30, 0)
local utc_dt = local_dt:toUTC()
local back = utc_dt:toLocal()

print(local_dt:offset())    -- 1.0 (UTC+1)
print(utc_dt:isUTC())       -- true
print(utc_dt:offset())      -- 0.0
```

## Utilities

### Instance Methods

```lua
local d = time.date(2024, 2, 15)

d:isLeapYear()    -- true (2024 is a leap year)
d:daysInMonth()   -- 29   (February in leap year)
d:clone()         -- independent copy
```

### Static Functions

```lua
time.isLeapYear(2024)       -- true
time.isLeapYear(2023)       -- false
time.daysInMonth(2024, 2)   -- 29
time.daysInMonth(2023, 2)   -- 28
```

## Basic Time Functions

The `time` module also provides simple utility functions for timestamps, sleeping, and measuring durations:

### Timestamps

```lua
time.now()         -- current Unix timestamp in seconds (float)
time.now_ms()      -- current Unix timestamp in milliseconds (integer)
```

### Sleeping

```lua
time.sleep(1000)   -- sleep for 1000 milliseconds
```

### Monotonic Time

For measuring elapsed time (unaffected by system clock changes):

```lua
local start = time.monotonic()
-- ... do work ...
local elapsed = time.monotonic() - start
print(string.format("Took %.3f seconds", elapsed))

-- Millisecond version
local start_ms = time.monotonic_ms()
```

### Legacy Format/Parse

The module also provides `time.format` and `time.parse` for working with raw timestamps. These use `strftime`-style `%Y/%m/%d` tokens (not Moment.js tokens):

```lua
-- Format a Unix timestamp
time.format(time.now())                        -- "2024-06-15T14:30:00Z"
time.format(time.now(), "%Y-%m-%d %H:%M:%S")  -- "2024-06-15 14:30:00"

-- Parse a string to Unix timestamp
time.parse("2024-06-15T14:30:00Z")             -- 1718458200.0
time.parse("2024-06-15 14:30:00", "%Y-%m-%d %H:%M:%S")
```

For new code, prefer `time.date(string)` which returns a full DateTime object.

## Global Timers

The following global functions are available everywhere (registered by the `time` module):

```lua
local id = setTimeout(function() print("later") end, 1000)
local id = setInterval(function() print("tick") end, 500)

clearTimeout(id)
clearInterval(id)
```

## Usage Examples

### Date Range Iteration

```lua
local start = time.date(2024, 1, 1)
local stop = time.date(2024, 1, 31)

local current = start
while current:isBefore(stop) or current:isSame(stop) do
    print(current:format("ddd DD MMM"))
    current = current:add(1, "day")
end
```

### Age Calculator

```lua
local birthday = time.date(1990, 5, 15)
local now = time.date()

local age = math.floor(now:diff(birthday, "years"))
print("Age: " .. age .. " years")
print("Born on a " .. birthday:format("dddd"))
print("Next birthday in " .. birthday:set({ year = now:year() }):add(1, "year"):fromNow())
```

### Working with Periods

```lua
-- Get all days in current month
local d = time.date()
local first = d:startOf("month")
local last = d:endOf("month")

print("Month: " .. first:format("MMMM YYYY"))
print("From: " .. first:format("dddd, D"))
print("To: " .. last:format("dddd, D"))
print("Days: " .. d:daysInMonth())
```

### Log Timestamp Formatting

```lua
local function log(message)
    local now = time.date()
    print(now:format("[[]YYYY-MM-DD HH:mm:ss.SSS[]]") .. " " .. message)
end

log("Server started")     -- "[2024-06-15 14:30:00.123] Server started"
log("Request received")   -- "[2024-06-15 14:30:01.456] Request received"
```

### ISO Week Boundaries

```lua
local d = time.date(2024, 6, 12)  -- a Wednesday
local monday = d:startOf("week")
local sunday = d:endOf("week")

print("Week of " .. d:format("MMMM D, YYYY"))
print("  Monday: " .. monday:format("YYYY-MM-DD"))
print("  Sunday: " .. sunday:format("YYYY-MM-DD"))
```

## Error Handling

DateTime operations raise Lua errors on invalid input. Use `pcall` for graceful handling:

```lua
local ok, err = pcall(function()
    local d = time.date("not a date")
end)
if not ok then
    print("Error:", err)
end
```

Common error scenarios:

- **Invalid date string** — format not recognized
- **Invalid components** — month 13, day 32, hour 25, etc.
- **Invalid timestamp** — number out of representable range
- **Unknown unit** — passing an unrecognized unit to `add`, `diff`, `startOf`, etc.

## Next Steps

- [API Reference](/docs/time/api) — Complete function and method reference
- [Buffer](/docs/buffer/overview) — Binary data manipulation
- [File System](/docs/fs/overview) — File and directory operations
