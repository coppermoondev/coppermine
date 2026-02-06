# API Reference

Complete API reference for the CopperMoon `sentinel` package.

## Module

```lua
local s = require("sentinel")
```

### `s.string()`

Create a new string validator.

**Returns:** StringRule

```lua
local rule = s.string():email():required()
```

### `s.number()`

Create a new number validator.

**Returns:** NumberRule

```lua
local rule = s.number():integer():min(0)
```

### `s.boolean()`

Create a new boolean validator with automatic coercion.

**Returns:** BooleanRule

```lua
local rule = s.boolean()
```

### `s.array()`

Create a new array validator.

**Returns:** ArrayRule

```lua
local rule = s.array():items(s.string()):min(1)
```

### `s.object(fields)`

Create a new object/schema validator.

| Parameter | Type | Description |
|---|---|---|
| `fields` | table | Map of field names to Rule instances |

**Returns:** ObjectRule

```lua
local schema = s.object({
    name = s.string():required(),
    age  = s.number():integer(),
})
```

### `s.any()`

Create a rule that accepts any type.

**Returns:** Rule

```lua
local rule = s.any():required()
```

### `s._VERSION`

Module version string.

```lua
print(s._VERSION)  -- "0.1.0"
```

## Common Methods (All Rules)

These methods are available on every rule type.

### `:required()`

Mark the value as required. Validation fails if the value is `nil` or `""`.

**Returns:** self

```lua
s.string():required()
```

### `:optional()`

Mark the value as optional (default behavior). `nil` values pass validation.

**Returns:** self

```lua
s.string():optional()
```

### `:nullable()`

Explicitly allow `nil` values, even when required.

**Returns:** self

```lua
s.string():nullable()
```

### `:default(value)`

Use `value` when the input is `nil`.

| Parameter | Type | Description |
|---|---|---|
| `value` | any | Default value to use |

**Returns:** self

```lua
s.string():default("unknown")
s.number():default(0)
s.array():default({})
```

### `:label(name)`

Set a human-readable label for error messages. Used instead of "value" in errors like `"value is required"`.

| Parameter | Type | Description |
|---|---|---|
| `name` | string | Human-readable field name |

**Returns:** self

```lua
s.string():label("Email address"):required()
-- Error: "Email address is required" instead of "value is required"
```

### `:message(msg)`

Override the error message of the last added constraint.

| Parameter | Type | Description |
|---|---|---|
| `msg` | string | Custom error message |

**Returns:** self

```lua
s.string():email():message("Please enter a valid email")
```

### `:custom(fn)`

Add a custom validation function.

| Parameter | Type | Description |
|---|---|---|
| `fn` | function | `fn(value) -> boolean, string?` |

**Returns:** self

```lua
s.string():custom(function(val)
    if val:match("%d") then
        return true
    end
    return false, "must contain at least one digit"
end)
```

### `:transform(fn)`

Add a custom transform function. Transforms run before constraints.

| Parameter | Type | Description |
|---|---|---|
| `fn` | function | `fn(value) -> new_value` |

**Returns:** self

```lua
s.string():transform(function(val)
    return val:gsub("%s+", " ")  -- collapse whitespace
end)
```

### `:validate(value)`

Run all transforms and constraints against a value.

| Parameter | Type | Description |
|---|---|---|
| `value` | any | The value to validate |

**Returns:** `ok` (boolean), `sanitized` (any), `errors` (table|nil)

```lua
local ok, val, errs = s.string():email():validate("user@example.com")
-- ok = true, val = "user@example.com", errs = nil

local ok, val, errs = s.string():email():validate("bad")
-- ok = false, val = nil, errs = { "must be a valid email address" }
```

### `:test(value)`

Quick boolean check. Returns `true` if validation passes, `false` otherwise.

| Parameter | Type | Description |
|---|---|---|
| `value` | any | The value to test |

**Returns:** boolean

```lua
if s.string():email():test(input) then
    -- valid
end
```

## StringRule Methods

All StringRule methods return `self` for chaining.

### Length Constraints

#### `:min(n)`

Minimum string length.

| Parameter | Type | Description |
|---|---|---|
| `n` | number | Minimum length |

```lua
s.string():min(3)
```

#### `:max(n)`

Maximum string length.

| Parameter | Type | Description |
|---|---|---|
| `n` | number | Maximum length |

```lua
s.string():max(100)
```

#### `:length(n)`

Exact string length.

| Parameter | Type | Description |
|---|---|---|
| `n` | number | Required length |

```lua
s.string():length(6)  -- e.g. PIN code
```

#### `:notEmpty()`

Must not be an empty string.

```lua
s.string():notEmpty()
```

### Format Validators

#### `:email()`

Must be a valid email address.

```lua
s.string():email()
-- "user@example.com" -> true
-- "not-an-email" -> false
```

#### `:url()`

Must be a valid HTTP or HTTPS URL.

```lua
s.string():url()
-- "https://example.com/path" -> true
```

#### `:ip()`

Must be a valid IPv4 or IPv6 address.

```lua
s.string():ip()
```

#### `:ipv4()`

Must be a valid IPv4 address.

```lua
s.string():ipv4()
-- "192.168.1.1" -> true
```

#### `:ipv6()`

Must be a valid IPv6 address.

```lua
s.string():ipv6()
-- "::1" -> true
```

#### `:uuid()`

Must be a valid UUID (v1-v5).

```lua
s.string():uuid()
-- "550e8400-e29b-41d4-a716-446655440000" -> true
```

#### `:json()`

Must be a valid JSON string.

```lua
s.string():json()
-- '{"key":"value"}' -> true
```

#### `:hostname()`

Must be a valid hostname.

```lua
s.string():hostname()
-- "example.com" -> true
```

#### `:date()`

Must be a valid date in `YYYY-MM-DD` format.

```lua
s.string():date()
-- "2024-01-15" -> true
```

#### `:creditCard()`

Must be a valid credit card number (Luhn algorithm).

```lua
s.string():creditCard()
```

#### `:hex()`

Must contain only hexadecimal characters.

```lua
s.string():hex()
-- "deadbeef" -> true
```

#### `:base64()`

Must be a valid base64 string.

```lua
s.string():base64()
-- "aGVsbG8=" -> true
```

#### `:slug()`

Must be a valid URL slug (lowercase letters, digits, hyphens).

```lua
s.string():slug()
-- "my-blog-post" -> true
```

#### `:semver()`

Must be a valid semantic version.

```lua
s.string():semver()
-- "1.2.3" -> true
-- "1.0.0-beta.1" -> true
```

#### `:macAddress()`

Must be a valid MAC address.

```lua
s.string():macAddress()
-- "AA:BB:CC:DD:EE:FF" -> true
```

### Character Sets

#### `:alpha()`

Must contain only letters (a-z, A-Z).

```lua
s.string():alpha()
```

#### `:alphanum()`

Must contain only letters and digits.

```lua
s.string():alphanum()
```

#### `:numeric()`

Must contain only digits (0-9).

```lua
s.string():numeric()
```

#### `:ascii()`

Must contain only ASCII characters (0-127).

```lua
s.string():ascii()
```

### Pattern Matching

#### `:pattern(pat, msg?)`

Must match a Lua pattern.

| Parameter | Type | Description |
|---|---|---|
| `pat` | string | Lua pattern |
| `msg` | string | Custom error message (optional) |

```lua
s.string():pattern("^%d+$")
s.string():pattern("^%u", "must start with an uppercase letter")
```

### Content Checks

#### `:startsWith(prefix)`

Must start with the given prefix.

| Parameter | Type | Description |
|---|---|---|
| `prefix` | string | Required prefix |

```lua
s.string():startsWith("http")
```

#### `:endsWith(suffix)`

Must end with the given suffix.

| Parameter | Type | Description |
|---|---|---|
| `suffix` | string | Required suffix |

```lua
s.string():endsWith(".lua")
```

#### `:contains(sub)`

Must contain the given substring.

| Parameter | Type | Description |
|---|---|---|
| `sub` | string | Required substring |

```lua
s.string():contains("@")
```

#### `:oneOf(values)`

Must be one of the allowed values (enum).

| Parameter | Type | Description |
|---|---|---|
| `values` | table | Array of allowed strings |

```lua
s.string():oneOf({"red", "green", "blue"})
```

### Transforms

Transforms sanitize the value before validation constraints run.

#### `:trim()`

Strip leading and trailing whitespace.

```lua
s.string():trim()
-- "  hello  " -> "hello"
```

#### `:lowercase()`

Convert to lowercase.

```lua
s.string():lowercase()
-- "HELLO" -> "hello"
```

#### `:uppercase()`

Convert to uppercase.

```lua
s.string():uppercase()
-- "hello" -> "HELLO"
```

## NumberRule Methods

Numbers are automatically coerced from strings: `"42"` becomes `42`.

### `:min(n)`

Minimum value (inclusive).

| Parameter | Type | Description |
|---|---|---|
| `n` | number | Minimum value |

```lua
s.number():min(0)  -- >= 0
```

### `:max(n)`

Maximum value (inclusive).

| Parameter | Type | Description |
|---|---|---|
| `n` | number | Maximum value |

```lua
s.number():max(100)  -- <= 100
```

### `:integer()`

Must be a whole number.

```lua
s.number():integer()
-- 42 -> true, 3.14 -> false
```

### `:positive()`

Must be greater than 0.

```lua
s.number():positive()
-- 1 -> true, 0 -> false, -1 -> false
```

### `:negative()`

Must be less than 0.

```lua
s.number():negative()
-- -1 -> true, 0 -> false
```

### `:nonNegative()`

Must be greater than or equal to 0.

```lua
s.number():nonNegative()
-- 0 -> true, 1 -> true, -1 -> false
```

### `:divisibleBy(n)`

Must be evenly divisible by `n`.

| Parameter | Type | Description |
|---|---|---|
| `n` | number | Divisor |

```lua
s.number():divisibleBy(5)
-- 10 -> true, 7 -> false
```

### `:precision(n)`

At most `n` decimal places.

| Parameter | Type | Description |
|---|---|---|
| `n` | number | Maximum decimal places |

```lua
s.number():precision(2)
-- 3.14 -> true, 3.141 -> false
```

### `:port()`

Must be a valid port number (1-65535).

```lua
s.number():port()
-- 80 -> true, 0 -> false, 70000 -> false
```

### `:oneOf(values)`

Must be one of the allowed values.

| Parameter | Type | Description |
|---|---|---|
| `values` | table | Array of allowed numbers |

```lua
s.number():oneOf({1, 2, 3})
```

## BooleanRule Methods

Booleans are automatically coerced from strings and numbers:
- Truthy: `true`, `1`, `"true"`, `"yes"`, `"on"`, `"1"`
- Falsy: `false`, `0`, `"false"`, `"no"`, `"off"`, `"0"`

### `:truthy(values)`

Add custom truthy values (in addition to defaults).

| Parameter | Type | Description |
|---|---|---|
| `values` | table | Array of strings to treat as `true` |

```lua
s.boolean():truthy({"oui", "si", "ja"})
```

### `:falsy(values)`

Add custom falsy values (in addition to defaults).

| Parameter | Type | Description |
|---|---|---|
| `values` | table | Array of strings to treat as `false` |

```lua
s.boolean():falsy({"non", "nein"})
```

## ArrayRule Methods

### `:min(n)`

Minimum number of items.

| Parameter | Type | Description |
|---|---|---|
| `n` | number | Minimum item count |

```lua
s.array():min(1)
```

### `:max(n)`

Maximum number of items.

| Parameter | Type | Description |
|---|---|---|
| `n` | number | Maximum item count |

```lua
s.array():max(10)
```

### `:length(n)`

Exact number of items.

| Parameter | Type | Description |
|---|---|---|
| `n` | number | Required item count |

```lua
s.array():length(3)
```

### `:nonempty()`

Must have at least one item. Shortcut for `:min(1)`.

```lua
s.array():nonempty()
```

### `:unique()`

All items must be unique (no duplicates).

```lua
s.array():unique()
-- {"a", "b", "c"} -> true
-- {"a", "b", "a"} -> false
```

### `:items(rule)`

Validate each item against a rule. Items are also sanitized through the rule's transforms.

| Parameter | Type | Description |
|---|---|---|
| `rule` | Rule | Rule to validate each item against |

```lua
-- Every item must be a valid email
s.array():items(s.string():email())

-- Items are sanitized
s.array():items(s.string():trim():lowercase())
-- {"  HELLO  ", "  WORLD  "} -> {"hello", "world"}
```

## ObjectRule Methods

### `:validate(data)`

Validate a table against the schema. Runs each field's rule, applies defaults, and collects errors.

| Parameter | Type | Description |
|---|---|---|
| `data` | table | The object to validate |

**Returns:** `ok` (boolean), `sanitized` (table), `errors` (table|nil)

On failure, `errors` is a table keyed by field name. Each value is an array of error strings:

```lua
local ok, data, errors = schema:validate(input)
-- errors = {
--     email = { "must be a valid email address" },
--     age   = { "must be at least 18" },
-- }
```

### `:strict()`

Reject unknown keys. Any field not defined in the schema produces an error.

**Returns:** self

```lua
local schema = s.object({
    name = s.string():required(),
}):strict()

schema:validate({ name = "Alice", extra = "oops" })
-- errors = { extra = { "unknown field" } }
```

### `:unknown()`

Allow unknown keys (default behavior). Unknown fields are passed through to the sanitized output.

**Returns:** self

### `:partial()`

Create a new schema where all fields are optional. Useful for update/patch operations.

**Returns:** new ObjectRule

```lua
local createSchema = s.object({
    name  = s.string():required(),
    email = s.string():email():required(),
})

local updateSchema = createSchema:partial()
-- Both name and email are now optional
updateSchema:validate({})  -- ok = true
```

### `:pick(fields)`

Create a new schema with only the specified fields.

| Parameter | Type | Description |
|---|---|---|
| `fields` | table | Array of field names to keep |

**Returns:** new ObjectRule

```lua
local loginSchema = schema:pick({"email", "password"})
```

### `:omit(fields)`

Create a new schema without the specified fields.

| Parameter | Type | Description |
|---|---|---|
| `fields` | table | Array of field names to remove |

**Returns:** new ObjectRule

```lua
local publicSchema = schema:omit({"password", "secret"})
```

### `:extend(fields)`

Create a new schema with additional fields merged in.

| Parameter | Type | Description |
|---|---|---|
| `fields` | table | Map of new field names to Rule instances |

**Returns:** new ObjectRule

```lua
local adminSchema = schema:extend({
    permissions = s.array():items(s.string()):required(),
    department  = s.string():required(),
})
```

## Standalone Validators

Pure boolean functions for quick checks. No chaining, no error messages.

| Function | Description |
|---|---|
| `s.isEmail(str)` | Valid email address |
| `s.isURL(str)` | Valid HTTP/HTTPS URL |
| `s.isIP(str)` | Valid IPv4 or IPv6 |
| `s.isIPv4(str)` | Valid IPv4 address |
| `s.isIPv6(str)` | Valid IPv6 address |
| `s.isUUID(str)` | Valid UUID |
| `s.isJSON(str)` | Valid JSON string |
| `s.isAlpha(str)` | Letters only |
| `s.isAlphanum(str)` | Letters and digits only |
| `s.isNumeric(str)` | Digits only |
| `s.isAscii(str)` | ASCII characters only |
| `s.isHex(str)` | Hexadecimal characters |
| `s.isBase64(str)` | Valid base64 |
| `s.isCreditCard(str)` | Valid credit card (Luhn) |
| `s.isHostname(str)` | Valid hostname |
| `s.isEmpty(str)` | Empty string |
| `s.isDate(str)` | Valid date (YYYY-MM-DD) |
| `s.isSlug(str)` | Valid URL slug |
| `s.isSemver(str)` | Valid semantic version |
| `s.isMACAddress(str)` | Valid MAC address |

```lua
if s.isEmail(input) then
    print("Valid email!")
end

if s.isUUID(id) then
    -- safe to use as identifier
end
```
