# Regex

The `re` module provides regular expression matching, searching, replacing, and splitting using Rust's high-performance `regex` engine. It's available as a global — no `require()` needed.

## Quick Start

### Test if a pattern matches

```lua
if re.test("\\d+", "abc123") then
    print("contains numbers")
end
```

### Extract match info

```lua
local m = re.match("(\\w+)@(\\w+\\.\\w+)", "user@example.com")
print(m.match)      -- "user@example.com"
print(m.groups[1])  -- "user"
print(m.groups[2])  -- "example.com"
```

### Named captures

```lua
local m = re.match("(?P<year>\\d{4})-(?P<month>\\d{2})-(?P<day>\\d{2})", "2025-03-15")
print(m.named.year)   -- "2025"
print(m.named.month)  -- "03"
print(m.named.day)    -- "15"
```

### Find all matches

```lua
local matches = re.findAll("\\d+", "a1 b22 c333")
for _, m in ipairs(matches) do
    print(m.match)  -- "1", "22", "333"
end
```

### Replace

```lua
local result = re.replaceAll("\\d+", "a1b2c3", "X")
print(result)  -- "aXbXcX"
```

### Split

```lua
local parts = re.split("[,;\\s]+", "a, b; c  d")
-- parts = {"a", "b", "c", "d"}
```

## Compiled Patterns

For repeated use, compile a pattern once with `re.compile()`. This avoids re-parsing the regex on each call:

```lua
local email = re.compile("[\\w.+-]+@[\\w-]+\\.[\\w.]+")

-- Reuse it many times
if email:test(input) then
    print("valid email")
end

local all = email:findAll(text)
for _, m in ipairs(all) do
    print(m.match)
end
```

A compiled `Pattern` object has the same methods as the module-level functions: `test`, `match`, `find`, `findAll`, `replace`, `replaceAll`, `split`, and `source`.

```lua
local p = re.compile("\\d+")
print(p:source())     -- "\\d+"
print(tostring(p))    -- "Pattern(\\d+)"
```

## Flags

Both module functions and `re.compile` accept an optional flags string as the last argument:

```lua
-- Case-insensitive match
re.test("hello", "HELLO WORLD", "i")  -- true

-- Compiled with flags
local p = re.compile("^start.*end$", "is")
```

| Flag | Description |
|------|-------------|
| `i` | Case-insensitive matching |
| `m` | Multiline — `^` and `$` match line boundaries |
| `s` | Dotall — `.` matches `\n` |
| `x` | Extended — ignore whitespace and `#` comments in pattern |
| `U` | Ungreedy — swap meaning of greedy/lazy quantifiers |

Flags can be combined: `"ims"` enables all three at once.

## Match Result Table

All match functions (`match`, `find`, `findAll`) return a table with:

| Field | Type | Description |
|-------|------|-------------|
| `match` | string | The full matched text |
| `start` | number | Start position (1-indexed) |
| `end` | number | End position (1-indexed, inclusive) |
| `groups` | table | Numbered capture groups (1-indexed array) |
| `named` | table | Named capture groups (only present if the pattern has named groups) |

```lua
local m = re.match("(\\w+)@(\\w+)", "user@host in text")
print(m.match)      -- "user@host"
print(m.start)      -- 1
print(m["end"])     -- 9
print(m.groups[1])  -- "user"
print(m.groups[2])  -- "host"
```

Groups that didn't participate in the match are `nil`:

```lua
local m = re.match("(a)|(b)", "b")
print(m.groups[1])  -- nil
print(m.groups[2])  -- "b"
```

## Escaping Metacharacters

Use `re.escape()` to safely include user input in a pattern:

```lua
local user_input = "price is $9.99"
local pattern = re.escape(user_input)
-- pattern = "price is \\$9\\.99"
re.test(pattern, user_input)  -- true
```

## Practical Examples

### Validate an email

```lua
local email_pattern = re.compile("^[\\w.+-]+@[\\w-]+\\.[\\w.]+$")

local function validate_email(email)
    return email_pattern:test(email)
end
```

### Parse a log line

```lua
local log = re.compile("^\\[(?P<level>\\w+)\\] (?P<time>[\\d:.-]+) (?P<msg>.+)$")

local m = log:match("[ERROR] 2025-03-15:10:30:00 Connection refused")
if m then
    print(m.named.level)  -- "ERROR"
    print(m.named.time)   -- "2025-03-15:10:30:00"
    print(m.named.msg)    -- "Connection refused"
end
```

### Replace with back-references

```lua
-- Swap first and last name
local result = re.replaceAll("(\\w+) (\\w+)", "John Doe", "$2 $1")
print(result)  -- "Doe John"
```

### Extract all URLs from text

```lua
local url_pattern = re.compile("https?://[\\w./-]+")
local urls = url_pattern:findAll(html)

for _, m in ipairs(urls) do
    print(m.match)
end
```

### Clean up whitespace

```lua
-- Collapse multiple spaces into one
local clean = re.replaceAll("\\s+", "  hello   world  ", " ")
print(clean)  -- " hello world "
```

## Regex Syntax

CopperMoon uses the Rust `regex` crate syntax, which is similar to Perl/PCRE but without backtracking (guaranteed linear-time matching).

### Common patterns

| Pattern | Matches |
|---------|---------|
| `.` | Any character (except `\n` unless `s` flag) |
| `\d` | Digit (`[0-9]`) |
| `\w` | Word character (`[a-zA-Z0-9_]`) |
| `\s` | Whitespace |
| `\D`, `\W`, `\S` | Negated versions |
| `[abc]` | Character class |
| `[^abc]` | Negated character class |
| `a*` | Zero or more |
| `a+` | One or more |
| `a?` | Zero or one |
| `a{3}` | Exactly 3 |
| `a{2,5}` | Between 2 and 5 |
| `^` | Start of string (or line with `m` flag) |
| `$` | End of string (or line with `m` flag) |
| `(...)` | Capture group |
| `(?P<name>...)` | Named capture group |
| `(?:...)` | Non-capturing group |
| `a\|b` | Alternation |

### Escaping in Lua strings

Since Lua uses `\` for its own escape sequences, you need to double backslashes in regex patterns:

```lua
-- Match a digit
re.test("\\d+", "123")       -- correct
-- re.test("\d+", "123")     -- wrong! Lua interprets \d first

-- Match a literal backslash
re.test("\\\\", "a\\b")      -- correct (4 backslashes → regex \\)
```

## Next Steps

- [API Reference](/docs/regex/api) — Complete function and method reference
- [Buffer](/docs/buffer/overview) — Binary data manipulation
- [File System](/docs/fs/overview) — Reading and writing files
