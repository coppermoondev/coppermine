# API Reference

Complete API reference for the CopperMoon `time` module — DateTime, timestamps, formatting, and timers.

## DateTime Factory

### `time.date(...)`

Create a DateTime in the local timezone.

**Signatures:**

```lua
time.date()                              -- current local time
time.date(timestamp)                     -- from Unix timestamp
time.date(string)                        -- from date string
time.date(year, month, day)              -- from components
time.date(year, month, day, hour, min, sec)      -- with time
time.date(year, month, day, hour, min, sec, ms)  -- with milliseconds
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `timestamp` | number | Unix timestamp in seconds |
| `string` | string | Date string (ISO 8601, RFC 3339, or common formats) |
| `year` | number | Year (e.g. 2024) |
| `month` | number | Month (1-12) |
| `day` | number | Day of month (1-31) |
| `hour` | number | Hour (0-23), default `0` |
| `min` | number | Minute (0-59), default `0` |
| `sec` | number | Second (0-59), default `0` |
| `ms` | number | Millisecond (0-999), default `0` |

**Returns:** DateTime object

**Raises:** error if arguments are invalid

```lua
local now = time.date()
local d = time.date(2024, 6, 15, 14, 30, 0)
local d = time.date("2024-06-15T14:30:00+02:00")
local d = time.date(1718458200)
```

### `time.utc(...)`

Create a DateTime in UTC. Same signatures as `time.date`.

When parsing strings without timezone information, UTC is assumed instead of local time.

```lua
local now = time.utc()
local d = time.utc(2024, 6, 15, 14, 30, 0)
local d = time.utc("2024-06-15T14:30:00")
```

## DateTime Getters

### `d:year()`

Get the year.

**Returns:** number

```lua
time.date(2024, 6, 15):year()  -- 2024
```

### `d:month()`

Get the month (1-12).

**Returns:** number

```lua
time.date(2024, 6, 15):month()  -- 6
```

### `d:day()`

Get the day of the month (1-31).

**Returns:** number

```lua
time.date(2024, 6, 15):day()  -- 15
```

### `d:hour()`

Get the hour (0-23).

**Returns:** number

```lua
time.date(2024, 6, 15, 14, 30):hour()  -- 14
```

### `d:minute()`

Get the minute (0-59).

**Returns:** number

```lua
time.date(2024, 6, 15, 14, 30):minute()  -- 30
```

### `d:second()`

Get the second (0-59).

**Returns:** number

```lua
time.date(2024, 6, 15, 14, 30, 45):second()  -- 45
```

### `d:milli()`

Get the millisecond (0-999).

**Returns:** number

```lua
time.date(2024, 6, 15, 14, 30, 45, 123):milli()  -- 123
```

### `d:weekday()`

Get the day of the week. ISO 8601: 1 = Monday, 7 = Sunday.

**Returns:** number (1-7)

```lua
time.date(2024, 6, 15):weekday()  -- 6 (Saturday)
time.date(2024, 6, 10):weekday()  -- 1 (Monday)
```

### `d:yearday()`

Get the day of the year (1-366).

**Returns:** number

```lua
time.date(2024, 1, 1):yearday()   -- 1
time.date(2024, 12, 31):yearday() -- 366 (leap year)
```

### `d:timestamp()`

Get the Unix timestamp in seconds as a float (with sub-second precision).

**Returns:** number (float)

```lua
time.date(2024, 6, 15, 14, 30, 0):timestamp()  -- 1718458200.0
```

### `d:timestamp_ms()`

Get the Unix timestamp in milliseconds as an integer.

**Returns:** number (integer)

```lua
time.date(2024, 6, 15, 14, 30, 0):timestamp_ms()  -- 1718458200000
```

### `d:offset()`

Get the UTC offset in hours.

**Returns:** number (float)

```lua
time.date():offset()   -- 1.0 (for UTC+1)
time.utc():offset()    -- 0.0
```

### `d:isUTC()`

Check if the DateTime is in UTC (offset is zero).

**Returns:** boolean

```lua
time.date():isUTC()   -- false (usually)
time.utc():isUTC()    -- true
```

## DateTime Setters

### `d:set(fields)`

Create a new DateTime with updated fields. Unspecified fields keep their original value. The original DateTime is unchanged.

| Parameter | Type | Description |
|-----------|------|-------------|
| `fields` | table | Fields to update |

**Available fields:** `year`, `month`, `day`, `hour`, `minute`, `second`, `milli`

**Returns:** DateTime (new instance)

```lua
local d = time.date(2024, 6, 15, 14, 30, 0)
local d2 = d:set({ year = 2025, month = 12 })
-- d2 = 2025-12-15T14:30:00 (d is unchanged)
```

## DateTime Arithmetic

### `d:add(amount, unit)` / `d:add(table)`

Add time to a DateTime. Returns a new DateTime.

**Signature 1: Amount + Unit**

| Parameter | Type | Description |
|-----------|------|-------------|
| `amount` | number | Amount to add |
| `unit` | string | Time unit |

**Signature 2: Table**

| Parameter | Type | Description |
|-----------|------|-------------|
| `table` | table | Fields with amounts to add |

**Accepted units:** `years` / `year` / `y`, `months` / `month` / `M`, `weeks` / `week` / `w`, `days` / `day` / `d`, `hours` / `hour` / `h`, `minutes` / `minute` / `m`, `seconds` / `second` / `s`, `milliseconds` / `millisecond` / `ms`

**Returns:** DateTime (new instance)

```lua
d:add(7, "days")
d:add(3, "months")
d:add(1, "year")
d:add({ years = 1, months = 2, days = 3 })
d:add({ hours = 5, minutes = 30 })
```

### `d:sub(amount, unit)` / `d:sub(table)`

Subtract time from a DateTime. Returns a new DateTime. Same signatures as `add`.

**Returns:** DateTime (new instance)

```lua
d:sub(1, "day")
d:sub(2, "weeks")
d:sub({ months = 3, days = 10 })
```

## DateTime Formatting

### `d:format(pattern?)`

Format the DateTime using Moment.js-style tokens. Without a pattern, uses `YYYY-MM-DDTHH:mm:ssZ`.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `pattern` | string | `"YYYY-MM-DDTHH:mm:ssZ"` | Format pattern with tokens |

**Returns:** string

Use `[text]` to escape literal characters that would otherwise be interpreted as tokens.

```lua
d:format("YYYY-MM-DD")               -- "2024-06-15"
d:format("dddd, MMMM DD YYYY")       -- "Saturday, June 15 2024"
d:format("hh:mm A")                  -- "02:30 PM"
d:format("[Date:] YYYY-MM-DD")       -- "Date: 2024-06-15"
```

**Tokens:**

| Token | Description | Example |
|-------|-------------|---------|
| `YYYY` | 4-digit year | `2024` |
| `YY` | 2-digit year | `24` |
| `MMMM` | Full month name | `January` |
| `MMM` | Short month name | `Jan` |
| `MM` | Month zero-padded | `01` |
| `M` | Month | `1` |
| `DD` | Day zero-padded | `05` |
| `D` | Day | `5` |
| `dddd` | Full weekday | `Monday` |
| `ddd` | Short weekday | `Mon` |
| `dd` | Min weekday | `Mo` |
| `d` | Weekday number (1=Mon) | `1` |
| `HH` | Hour 24h zero-padded | `09` |
| `H` | Hour 24h | `9` |
| `hh` | Hour 12h zero-padded | `02` |
| `h` | Hour 12h | `2` |
| `mm` | Minute zero-padded | `05` |
| `m` | Minute | `5` |
| `ss` | Second zero-padded | `03` |
| `s` | Second | `3` |
| `SSS` | Milliseconds | `042` |
| `A` | AM/PM uppercase | `PM` |
| `a` | am/pm lowercase | `pm` |
| `Z` | UTC offset | `+01:00` |
| `ZZ` | UTC offset compact | `+0100` |
| `X` | Unix timestamp (seconds) | `1718458200` |
| `x` | Unix timestamp (ms) | `1718458200000` |

### `d:toISO()`

Format as ISO 8601 with milliseconds: `YYYY-MM-DDTHH:mm:ss.SSSZ`

**Returns:** string

```lua
d:toISO()  -- "2024-06-15T14:30:00.000+01:00"
```

### `d:toDate()`

Format as date string: `YYYY-MM-DD`

**Returns:** string

```lua
d:toDate()  -- "2024-06-15"
```

### `d:toTime()`

Format as time string: `HH:mm:ss`

**Returns:** string

```lua
d:toTime()  -- "14:30:00"
```

## DateTime Comparison

### `d:isBefore(other)`

Check if this DateTime is before another.

| Parameter | Type | Description |
|-----------|------|-------------|
| `other` | DateTime | DateTime to compare against |

**Returns:** boolean

```lua
a:isBefore(b)  -- true if a is earlier than b
```

### `d:isAfter(other)`

Check if this DateTime is after another.

| Parameter | Type | Description |
|-----------|------|-------------|
| `other` | DateTime | DateTime to compare against |

**Returns:** boolean

```lua
b:isAfter(a)  -- true if b is later than a
```

### `d:isSame(other)`

Check if this DateTime is the same instant as another.

| Parameter | Type | Description |
|-----------|------|-------------|
| `other` | DateTime | DateTime to compare against |

**Returns:** boolean

```lua
a:isSame(a:clone())  -- true
```

### `d:isBetween(start, finish)`

Check if this DateTime falls strictly between two others (exclusive bounds). The order of `start` and `finish` doesn't matter — the lower and upper bounds are determined automatically.

| Parameter | Type | Description |
|-----------|------|-------------|
| `start` | DateTime | First boundary |
| `finish` | DateTime | Second boundary |

**Returns:** boolean

```lua
local mid = time.date(2024, 6, 15)
mid:isBetween(time.date(2024, 1, 1), time.date(2024, 12, 31))  -- true
```

## DateTime Diff

### `d:diff(other, unit?)`

Calculate the difference between two DateTimes. Result is `self - other`.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `other` | DateTime | | DateTime to diff against |
| `unit` | string | `"seconds"` | Unit for the result |

**Accepted units:** `years`, `months`, `weeks`, `days`, `hours`, `minutes`, `seconds`, `milliseconds`

**Returns:** number (float). Positive if `self` is after `other`, negative if before.

```lua
local a = time.date(2024, 1, 1)
local b = time.date(2024, 6, 15)

b:diff(a, "days")     -- 166.0
b:diff(a, "months")   -- 5.0
b:diff(a, "hours")    -- 3984.0
b:diff(a)             -- 14342400.0 (seconds)
a:diff(b, "days")     -- -166.0
```

## DateTime Periods

### `d:startOf(unit)`

Get the start of a time period. Returns a new DateTime set to the earliest moment of the specified unit.

| Parameter | Type | Description |
|-----------|------|-------------|
| `unit` | string | Period unit |

**Accepted units:** `year` / `years`, `month` / `months`, `week` / `weeks`, `day` / `days`, `hour` / `hours`, `minute` / `minutes`, `second` / `seconds`

**Returns:** DateTime (new instance)

Weeks start on Monday (ISO 8601).

```lua
d:startOf("year")    -- Jan 1, 00:00:00.000
d:startOf("month")   -- 1st of month, 00:00:00.000
d:startOf("week")    -- Monday, 00:00:00.000
d:startOf("day")     -- 00:00:00.000
d:startOf("hour")    -- XX:00:00.000
d:startOf("minute")  -- XX:XX:00.000
```

### `d:endOf(unit)`

Get the end of a time period. Returns a new DateTime set to the latest moment of the specified unit (23:59:59.999).

| Parameter | Type | Description |
|-----------|------|-------------|
| `unit` | string | Period unit |

**Accepted units:** same as `startOf`

**Returns:** DateTime (new instance)

```lua
d:endOf("year")    -- Dec 31, 23:59:59.999
d:endOf("month")   -- last day of month, 23:59:59.999
d:endOf("week")    -- Sunday, 23:59:59.999
d:endOf("day")     -- 23:59:59.999
d:endOf("hour")    -- XX:59:59.999
d:endOf("minute")  -- XX:XX:59.999
```

## DateTime Utilities

### `d:isLeapYear()`

Check if the DateTime's year is a leap year.

**Returns:** boolean

```lua
time.date(2024, 1, 1):isLeapYear()  -- true
time.date(2023, 1, 1):isLeapYear()  -- false
```

### `d:daysInMonth()`

Get the number of days in the DateTime's month.

**Returns:** number

```lua
time.date(2024, 2, 1):daysInMonth()  -- 29 (leap year February)
time.date(2024, 6, 1):daysInMonth()  -- 30
```

### `d:clone()`

Create an independent copy of the DateTime.

**Returns:** DateTime (new instance)

```lua
local copy = d:clone()
```

### `d:toUTC()`

Convert to UTC. Returns a new DateTime with the same instant but offset 0.

**Returns:** DateTime (new instance)

```lua
local utc = d:toUTC()
print(utc:isUTC())    -- true
print(utc:offset())   -- 0.0
```

### `d:toLocal()`

Convert to the system's local timezone. Returns a new DateTime with the same instant but the local UTC offset.

**Returns:** DateTime (new instance)

```lua
local local_dt = utc_dt:toLocal()
print(local_dt:offset())  -- system UTC offset in hours
```

## DateTime Relative Time

### `d:fromNow()`

Get a human-readable string describing the time from this DateTime to now.

**Returns:** string

```lua
time.utc():sub(3, "hours"):fromNow()   -- "3 hours ago"
time.utc():add(2, "days"):fromNow()    -- "in 2 days"
time.utc():sub(30, "seconds"):fromNow() -- "a few seconds ago"
```

### `d:toNow()`

Get a human-readable string describing the time from now to this DateTime (inverse of `fromNow`).

**Returns:** string

```lua
time.utc():sub(3, "hours"):toNow()   -- "in 3 hours"
time.utc():add(2, "days"):toNow()    -- "2 days ago"
```

### `d:from(other)`

Get a human-readable string describing the time from this DateTime relative to another.

| Parameter | Type | Description |
|-----------|------|-------------|
| `other` | DateTime | Reference DateTime |

**Returns:** string

```lua
local a = time.date(2024, 1, 1)
local b = time.date(2024, 7, 15)
a:from(b)  -- "6 months ago" (a is 6 months before b)
```

### `d:to(other)`

Get a human-readable string describing the time from this DateTime to another (inverse of `from`).

| Parameter | Type | Description |
|-----------|------|-------------|
| `other` | DateTime | Target DateTime |

**Returns:** string

```lua
local a = time.date(2024, 1, 1)
local b = time.date(2024, 7, 15)
a:to(b)  -- "in 6 months" (from a to b is 6 months forward)
```

## DateTime Metamethods

### `tostring(d)`

Returns the ISO 8601 representation (same as `d:toISO()`).

```lua
print(d)  -- "2024-06-15T14:30:00.000+01:00"
```

### `d1 == d2`

Equality: true if both represent the same instant in time.

```lua
d == d:clone()  -- true
```

### `d1 < d2`, `d1 <= d2`

Ordering: compares chronologically.

```lua
time.date(2024, 1, 1) < time.date(2024, 12, 31)  -- true
```

### `d1 - d2`

Subtraction: returns the difference in seconds as a float.

```lua
local seconds = b - a  -- 14342400.0
```

## Static Functions

### `time.isLeapYear(year)`

Check if a year is a leap year.

| Parameter | Type | Description |
|-----------|------|-------------|
| `year` | number | Year to check |

**Returns:** boolean

```lua
time.isLeapYear(2024)  -- true
time.isLeapYear(1900)  -- false
time.isLeapYear(2000)  -- true
```

### `time.daysInMonth(year, month)`

Get the number of days in a month.

| Parameter | Type | Description |
|-----------|------|-------------|
| `year` | number | Year |
| `month` | number | Month (1-12) |

**Returns:** number

**Raises:** error if month is invalid

```lua
time.daysInMonth(2024, 2)  -- 29
time.daysInMonth(2023, 2)  -- 28
time.daysInMonth(2024, 7)  -- 31
```

## Timestamp Functions

### `time.now()`

Get the current Unix timestamp in seconds.

**Returns:** number (float)

```lua
local ts = time.now()  -- 1718458200.123
```

### `time.now_ms()`

Get the current Unix timestamp in milliseconds.

**Returns:** number (integer)

```lua
local ms = time.now_ms()  -- 1718458200123
```

### `time.sleep(ms)`

Sleep for a specified number of milliseconds. Blocks the current execution.

| Parameter | Type | Description |
|-----------|------|-------------|
| `ms` | number | Milliseconds to sleep |

```lua
time.sleep(1000)  -- sleep 1 second
```

### `time.monotonic()`

Get monotonic elapsed time in seconds since process start. Monotonic time is unaffected by system clock changes, making it ideal for measuring durations.

**Returns:** number (float)

```lua
local start = time.monotonic()
-- ... work ...
print(time.monotonic() - start)  -- elapsed seconds
```

### `time.monotonic_ms()`

Get monotonic elapsed time in milliseconds.

**Returns:** number (integer)

```lua
local start = time.monotonic_ms()
```

### `time.format(timestamp, format?)`

Format a Unix timestamp using strftime-style `%` tokens.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `timestamp` | number | | Unix timestamp in seconds |
| `format` | string | `"%Y-%m-%dT%H:%M:%SZ"` | strftime format string |

**Returns:** string

```lua
time.format(time.now())                          -- "2024-06-15T14:30:00Z"
time.format(time.now(), "%Y-%m-%d %H:%M:%S")    -- "2024-06-15 14:30:00"
time.format(time.now(), "%A, %B %d %Y")          -- "Saturday, June 15 2024"
```

> For new code, prefer `time.date():format()` with Moment.js-style tokens.

### `time.parse(string, format?)`

Parse a date string into a Unix timestamp.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `string` | string | | Date string to parse |
| `format` | string | auto-detect | strftime format string |

**Returns:** number (Unix timestamp in seconds)

**Raises:** error if string cannot be parsed

Without a format, auto-detects ISO 8601, RFC 3339, and common date/time formats.

```lua
time.parse("2024-06-15T14:30:00Z")                        -- 1718458200.0
time.parse("2024-06-15 14:30:00", "%Y-%m-%d %H:%M:%S")   -- 1718458200.0
time.parse("2024-06-15")                                   -- 1718409600.0
```

> For new code, prefer `time.date(string)` which returns a full DateTime object.

## Global Timer Functions

### `setTimeout(fn, ms)`

Execute a function after a delay.

| Parameter | Type | Description |
|-----------|------|-------------|
| `fn` | function | Callback to execute |
| `ms` | number | Delay in milliseconds |

**Returns:** number (timer ID)

```lua
local id = setTimeout(function()
    print("Executed after 1 second")
end, 1000)
```

### `setInterval(fn, ms)`

Execute a function repeatedly at an interval.

| Parameter | Type | Description |
|-----------|------|-------------|
| `fn` | function | Callback to execute |
| `ms` | number | Interval in milliseconds |

**Returns:** number (timer ID)

```lua
local id = setInterval(function()
    print("Tick")
end, 500)
```

### `clearTimeout(id)` / `clearInterval(id)`

Cancel a scheduled timeout or interval.

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | number | Timer ID returned by setTimeout/setInterval |

```lua
clearTimeout(id)
clearInterval(id)
```
