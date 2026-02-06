# Regex API Reference

Complete reference for the `re` module. All functions are available globally.

## Module Functions

### re.compile(pattern, flags?)

Compile a regex pattern into a reusable `Pattern` object.

```lua
local p = re.compile("\\d+")
local p = re.compile("hello", "i")
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pattern` | string | Yes | Regex pattern |
| `flags` | string | No | Flag characters (`i`, `m`, `s`, `x`, `U`) |

**Returns:** `Pattern` object

**Errors:** If the pattern is invalid.

### re.test(pattern, text, flags?)

Test whether a pattern matches anywhere in the text.

```lua
re.test("\\d+", "abc123")     -- true
re.test("^\\d+$", "abc123")   -- false
re.test("hello", "HELLO", "i") -- true
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pattern` | string | Yes | Regex pattern |
| `text` | string | Yes | Text to search |
| `flags` | string | No | Flag characters |

**Returns:** `boolean`

### re.match(pattern, text, flags?)

Find the first match and return detailed info with captures.

```lua
local m = re.match("(\\w+)@(\\w+)", "user@host")
-- m.match = "user@host"
-- m.start = 1
-- m["end"] = 9
-- m.groups = {"user", "host"}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pattern` | string | Yes | Regex pattern |
| `text` | string | Yes | Text to search |
| `flags` | string | No | Flag characters |

**Returns:** Match result table or `nil` if no match.

#### Match result table

| Field | Type | Description |
|-------|------|-------------|
| `match` | string | Full matched text |
| `start` | number | Start position (1-indexed) |
| `end` | number | End position (1-indexed, inclusive) |
| `groups` | table | Array of numbered capture groups (1-indexed) |
| `named` | table | Map of named captures (only if pattern has named groups) |

### re.find(pattern, text, flags?)

Alias for `re.match()`. Returns the same result.

```lua
local m = re.find("\\d+", "abc123")
```

### re.findAll(pattern, text, flags?)

Find all non-overlapping matches in the text.

```lua
local matches = re.findAll("\\d+", "a1 b22 c333")
-- #matches = 3
-- matches[1].match = "1"
-- matches[2].match = "22"
-- matches[3].match = "333"
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pattern` | string | Yes | Regex pattern |
| `text` | string | Yes | Text to search |
| `flags` | string | No | Flag characters |

**Returns:** Array table of match result tables. Empty table if no matches.

### re.replace(pattern, text, replacement, flags?)

Replace the first match in the text.

```lua
re.replace("\\d+", "a1b2c3", "X")  -- "aXb2c3"
```

Back-references use `$1`, `$2`, etc.:

```lua
re.replace("(\\w+) (\\w+)", "John Doe", "$2 $1")  -- "Doe John"
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pattern` | string | Yes | Regex pattern |
| `text` | string | Yes | Text to search |
| `replacement` | string | Yes | Replacement string (supports `$1`, `$2`, `$name`) |
| `flags` | string | No | Flag characters |

**Returns:** `string` with the first match replaced.

### re.replaceAll(pattern, text, replacement, flags?)

Replace all matches in the text.

```lua
re.replaceAll("\\d+", "a1b2c3", "X")  -- "aXbXcX"
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pattern` | string | Yes | Regex pattern |
| `text` | string | Yes | Text to search |
| `replacement` | string | Yes | Replacement string (supports `$1`, `$2`, `$name`) |
| `flags` | string | No | Flag characters |

**Returns:** `string` with all matches replaced.

### re.split(pattern, text, flags?)

Split the text on every occurrence of the pattern.

```lua
re.split(",\\s*", "a, b, c")       -- {"a", "b", "c"}
re.split("[,;\\s]+", "a, b; c  d") -- {"a", "b", "c", "d"}
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pattern` | string | Yes | Regex pattern (used as delimiter) |
| `text` | string | Yes | Text to split |
| `flags` | string | No | Flag characters |

**Returns:** Array table of strings.

### re.escape(text)

Escape all regex metacharacters in a string so it can be used as a literal pattern.

```lua
re.escape("hello.world")   -- "hello\\.world"
re.escape("price: $9.99")  -- "price: \\$9\\.99"
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | string | Yes | String to escape |

**Returns:** `string` with metacharacters escaped.

## Pattern Object

A compiled `Pattern` object created by `re.compile()`. Avoids re-parsing the regex on each call.

### pattern:test(text)

```lua
local p = re.compile("\\d+")
p:test("abc123")  -- true
p:test("abcdef")  -- false
```

**Returns:** `boolean`

### pattern:match(text)

```lua
local p = re.compile("(\\w+)@(\\w+)")
local m = p:match("user@host")
```

**Returns:** Match result table or `nil`.

### pattern:find(text)

Alias for `pattern:match()`.

### pattern:findAll(text)

```lua
local p = re.compile("\\d+")
local matches = p:findAll("a1b22c333")
```

**Returns:** Array table of match result tables.

### pattern:replace(text, replacement)

```lua
local p = re.compile("\\d+")
p:replace("a1b2c3", "X")  -- "aXb2c3"
```

**Returns:** `string` with first match replaced.

### pattern:replaceAll(text, replacement)

```lua
local p = re.compile("\\d+")
p:replaceAll("a1b2c3", "X")  -- "aXbXcX"
```

**Returns:** `string` with all matches replaced.

### pattern:split(text)

```lua
local p = re.compile("[,;\\s]+")
p:split("a, b; c  d")  -- {"a", "b", "c", "d"}
```

**Returns:** Array table of strings.

### pattern:source()

Get the original pattern string.

```lua
local p = re.compile("\\d+")
p:source()  -- "\\d+"
```

**Returns:** `string`

### tostring(pattern)

```lua
local p = re.compile("\\d+")
print(tostring(p))  -- "Pattern(\\d+)"
```

## Flags Reference

| Flag | Name | Description |
|------|------|-------------|
| `i` | Case-insensitive | `a` matches both `a` and `A` |
| `m` | Multiline | `^` and `$` match at line boundaries, not just start/end of string |
| `s` | Dotall | `.` matches `\n` (newline) |
| `x` | Extended | Ignore whitespace and `#` comments in the pattern |
| `U` | Ungreedy | Quantifiers (`*`, `+`, `?`) are lazy by default; add `?` to make them greedy |

```lua
-- Case-insensitive
re.test("hello", "HELLO", "i")  -- true

-- Multiline
re.test("^world", "hello\nworld", "m")  -- true

-- Dotall
re.test("hello.world", "hello\nworld", "s")  -- true

-- Combined flags
re.test("^hello.world$", "HELLO\nWORLD", "ims")  -- true
```

## Replacement Syntax

In replacement strings:

| Syntax | Description |
|--------|-------------|
| `$1`, `$2`, ... | Numbered capture group |
| `$name` | Named capture group |
| `$0` | Entire match |
| `$$` | Literal `$` |

```lua
-- Numbered groups
re.replaceAll("(\\w+) (\\w+)", "John Doe", "$2, $1")  -- "Doe, John"

-- Named groups
re.replaceAll("(?P<first>\\w+) (?P<last>\\w+)", "John Doe", "$last, $first")
-- "Doe, John"

-- Entire match
re.replaceAll("\\w+", "hello world", "[$0]")  -- "[hello] [world]"
```
