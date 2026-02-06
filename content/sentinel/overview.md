# Sentinel

Sentinel is a data validation library for CopperMoon with a fluent, chainable API inspired by Joi. Define rules for strings, numbers, booleans, arrays, and objects -- validate individual values or full schemas, sanitize data with built-in transforms, and compose schemas with `partial`, `pick`, `omit`, and `extend`.

## Installation

```bash
harbor add sentinel
```

## Quick Start

```lua
local s = require("sentinel")

-- Validate a single value
local ok, val, errs = s.string():email():required():validate("user@example.com")
-- ok = true, val = "user@example.com"

-- Validate an object (form, API input, etc.)
local schema = s.object({
    email    = s.string():email():trim():lowercase():required(),
    password = s.string():min(8):max(128):required(),
    age      = s.number():integer():min(18):optional(),
    role     = s.string():oneOf({"admin", "user"}):default("user"),
})

local ok, data, errors = schema:validate({
    email = "  Alice@Example.COM  ",
    password = "supersecret",
    age = 25,
})
-- ok = true
-- data = { email = "alice@example.com", password = "supersecret", age = 25, role = "user" }
```

## Type Builders

Every builder returns a chainable rule. Call `:validate(value)` to run it.

```lua
s.string()      -- string validator
s.number()      -- number validator
s.boolean()     -- boolean validator (with coercion)
s.array()       -- array validator
s.object({})    -- object/schema validator
s.any()         -- accepts any type
```

## String Validation

### Length Constraints

```lua
s.string():min(3)          -- at least 3 characters
s.string():max(100)        -- at most 100 characters
s.string():length(6)       -- exactly 6 characters
s.string():notEmpty()      -- must not be ""
```

### Format Validators

```lua
s.string():email()         -- valid email address
s.string():url()           -- valid HTTP/HTTPS URL
s.string():ip()            -- valid IPv4 or IPv6
s.string():ipv4()          -- valid IPv4
s.string():ipv6()          -- valid IPv6
s.string():uuid()          -- valid UUID
s.string():json()          -- valid JSON string
s.string():hostname()      -- valid hostname
s.string():date()          -- valid date (YYYY-MM-DD)
s.string():creditCard()    -- valid credit card (Luhn)
s.string():hex()           -- hexadecimal characters
s.string():base64()        -- valid base64
s.string():slug()          -- lowercase slug (my-post)
s.string():semver()        -- semantic version (1.2.3)
s.string():macAddress()    -- MAC address
```

### Character Sets

```lua
s.string():alpha()         -- letters only
s.string():alphanum()      -- letters and digits
s.string():numeric()       -- digits only
s.string():ascii()         -- ASCII only
```

### Pattern Matching

```lua
s.string():pattern("^%d+$")                       -- Lua pattern
s.string():pattern("^%u", "must start uppercase")  -- custom error
```

### Content Checks

```lua
s.string():startsWith("http")
s.string():endsWith(".lua")
s.string():contains("@")
s.string():oneOf({"red", "green", "blue"})     -- enum
```

### Transforms

Transforms sanitize the value before constraints are checked:

```lua
s.string():trim()          -- strip leading/trailing whitespace
s.string():lowercase()     -- convert to lowercase
s.string():uppercase()     -- convert to uppercase

-- Chain them
s.string():trim():lowercase()
```

## Number Validation

```lua
s.number():min(0)              -- >= 0
s.number():max(100)            -- <= 100
s.number():integer()           -- must be a whole number
s.number():positive()          -- > 0
s.number():negative()          -- < 0
s.number():nonNegative()       -- >= 0
s.number():divisibleBy(5)      -- must divide evenly
s.number():precision(2)        -- at most 2 decimal places
s.number():port()              -- valid port (1-65535)
s.number():oneOf({1, 2, 3})    -- enum
```

Numbers are coerced from strings automatically: `"42"` becomes `42`.

## Boolean Validation

```lua
s.boolean()
```

Automatically coerces common values:
- Truthy: `true`, `1`, `"true"`, `"yes"`, `"on"`, `"1"`
- Falsy: `false`, `0`, `"false"`, `"no"`, `"off"`, `"0"`

Custom truthy/falsy:

```lua
s.boolean():truthy({"oui", "si"}):falsy({"non", "no"})
```

## Array Validation

```lua
s.array():min(1)               -- at least 1 item
s.array():max(10)              -- at most 10 items
s.array():length(3)            -- exactly 3 items
s.array():nonempty()           -- shortcut for min(1)
s.array():unique()             -- all items must be unique
```

### Per-Item Validation

```lua
-- Every item must be a valid email
s.array():items(s.string():email())

-- Every item is trimmed and lowercased
s.array():items(s.string():trim():lowercase())
```

## Object Validation

Define a schema mapping field names to rules:

```lua
local schema = s.object({
    username = s.string():alphanum():min(3):max(32):trim():lowercase():required(),
    email    = s.string():email():trim():lowercase():required(),
    password = s.string():min(8):max(128):required(),
    bio      = s.string():max(500):optional(),
    age      = s.number():integer():min(13):max(120):optional(),
    role     = s.string():oneOf({"user", "admin", "mod"}):default("user"),
    tags     = s.array():items(s.string():max(20)):max(5),
})

local ok, data, errors = schema:validate(input)
```

On success: `ok = true`, `data` contains sanitized values with defaults applied.

On failure: `ok = false`, `errors` is a table keyed by field name, each value is an array of error strings.

### Strict Mode

By default, unknown keys are passed through. Use `:strict()` to reject them:

```lua
local schema = s.object({
    name = s.string():required(),
}):strict()

schema:validate({ name = "Alice", extra = "rejected" })
-- ok = false, errors = { extra = { "unknown field" } }
```

### Schema Composition

```lua
-- All fields become optional
local partial = schema:partial()

-- Select specific fields
local login = schema:pick({"email", "password"})

-- Remove sensitive fields
local public = schema:omit({"password"})

-- Add new fields
local admin = schema:extend({
    permissions = s.array():items(s.string()):required(),
})
```

## Common Methods

Every rule supports these chainable methods:

| Method | Description |
|---|---|
| `:required()` | Value must be present |
| `:optional()` | Value can be nil (default) |
| `:nullable()` | Explicitly allow nil |
| `:default(val)` | Use `val` when nil |
| `:custom(fn)` | Custom validator: `fn(val) -> bool, err?` |
| `:transform(fn)` | Custom transform: `fn(val) -> new_val` |
| `:message(msg)` | Override error for the previous constraint |
| `:label(name)` | Human-readable name for errors |

## Execution Methods

| Method | Returns | Description |
|---|---|---|
| `:validate(value)` | `ok, sanitized, errors` | Full validation result |
| `:test(value)` | `boolean` | Quick pass/fail check |

## Standalone Validators

Pure boolean functions, no chaining needed:

```lua
s.isEmail("user@example.com")   -- true
s.isURL("https://example.com")  -- true
s.isIP("127.0.0.1")             -- true
s.isIPv4("192.168.1.1")         -- true
s.isIPv6("::1")                 -- true
s.isUUID("550e8400-...")        -- true
s.isJSON('{"a":1}')             -- true
s.isAlpha("hello")              -- true
s.isAlphanum("abc123")          -- true
s.isNumeric("42")               -- true
s.isAscii("hello")              -- true
s.isHex("deadbeef")             -- true
s.isBase64("aGVsbG8=")          -- true
s.isCreditCard("4111...")       -- true
s.isHostname("example.com")     -- true
s.isEmpty("")                   -- true
s.isDate("2024-01-15")          -- true
s.isSlug("my-post")             -- true
s.isSemver("1.2.3")             -- true
s.isMACAddress("AA:BB:CC:...")  -- true
```

## Real-World Examples

### User Registration

```lua
local s = require("sentinel")

local schema = s.object({
    username = s.string():alphanum():min(3):max(32):trim():lowercase():required(),
    email    = s.string():email():trim():lowercase():required(),
    password = s.string():min(8):custom(function(val)
        if not val:match("%d") then
            return false, "must contain at least one digit"
        end
        return true
    end):required(),
    terms    = s.boolean():custom(function(val)
        return val == true, "you must accept the terms"
    end):required(),
})

local ok, data, errors = schema:validate(req.body)
if not ok then
    return res:status(422):json({ errors = errors })
end
-- data is sanitized and ready
```

### API Query Parameters

```lua
local query_schema = s.object({
    page   = s.number():integer():min(1):default(1),
    limit  = s.number():integer():min(1):max(100):default(20),
    sort   = s.string():oneOf({"created", "updated", "name"}):default("created"),
    order  = s.string():oneOf({"asc", "desc"}):default("desc"),
    search = s.string():trim():max(200):optional(),
})

local ok, params = query_schema:validate(req.query)
```

### Config Validation

```lua
local config_schema = s.object({
    host     = s.string():hostname():required(),
    port     = s.number():port():default(3000),
    database = s.string():notEmpty():required(),
    debug    = s.boolean():default(false),
    workers  = s.number():integer():positive():default(4),
    origins  = s.array():items(s.string():url()):default({}),
})
```

### Nested Validation

```lua
local address = s.object({
    street = s.string():required(),
    city   = s.string():required(),
    zip    = s.string():pattern("^%d%d%d%d%d$"):required(),
})

local order = s.object({
    items    = s.array():items(s.object({
        id    = s.string():uuid():required(),
        qty   = s.number():integer():positive():required(),
    })):nonempty():required(),
    shipping = address:required(),
    billing  = address:optional(),
})
```

### HoneyMoon Integration

Sentinel works great as middleware for validating request bodies and query parameters in [HoneyMoon](/docs/honeymoon/overview) routes:

```lua
local app = require("honeymoon").new()
local s = require("sentinel")

local createUserSchema = s.object({
    email    = s.string():email():trim():lowercase():required(),
    password = s.string():min(8):max(128):required(),
    name     = s.string():trim():min(1):max(100):required(),
})

app:post("/api/users", function(req, res)
    local ok, data, errors = createUserSchema:validate(req.body)
    if not ok then
        return res:status(422):json({ errors = errors })
    end

    -- data.email is trimmed and lowercased
    -- data.password is validated (8-128 chars)
    local user = User:create(data)
    res:status(201):json(user)
end)
```

## Error Handling

Validation never throws. It always returns a structured result:

```lua
local ok, data, errors = schema:validate(input)

if not ok then
    -- errors is a table keyed by field name
    -- each value is an array of error strings
    for field, errs in pairs(errors) do
        for _, msg in ipairs(errs) do
            print(field .. ": " .. msg)
        end
    end
end
```

For single values, errors is a flat array:

```lua
local ok, val, errs = s.string():email():min(10):validate("bad")
-- ok = false
-- errs = { "must be a valid email address", "must be at least 10 characters" }
```

## Next Steps

- [API Reference](/docs/sentinel/api) -- Complete method reference for all types
- [HoneyMoon Validation](/docs/honeymoon/validation) -- Framework-level validation
- [Assay Testing](/docs/assay/overview) -- Test your validation schemas
