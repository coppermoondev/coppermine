# Validation

HoneyMoon includes a schema-based validation system for validating request data with type coercion, sanitization, and detailed error messages.

## Defining a Schema

Use `honeymoon.schema()` to define validation rules:

```lua
local userSchema = honeymoon.schema({
    username = {
        type = "string",
        required = true,
        min = 3,
        max = 32,
        trim = true,
        lowercase = true,
        pattern = "^[%w_]+$",
        patternMessage = "must contain only letters, numbers, and underscores",
    },
    email = {
        type = "email",
        required = true,
        lowercase = true,
        trim = true,
    },
    age = {
        type = "integer",
        minValue = 0,
        maxValue = 150,
    },
    website = {
        type = "url",
    },
    role = {
        type = "string",
        enum = { "user", "admin", "moderator" },
        default = "user",
    },
    agreed = {
        type = "boolean",
        required = true,
    },
})
```

## Field Types

| Type | Description | Coercion |
|------|-------------|----------|
| `string` | String value | No |
| `number` | Numeric value | Yes (`tonumber`) |
| `integer` | Integer (no decimals) | Yes (`tonumber`, floored) |
| `boolean` | Boolean value | Yes (`"true"`, `"1"`, `1` → `true`) |
| `email` | Valid email address | Must be a string |
| `url` | Valid HTTP/HTTPS URL | Must be a string |
| `uuid` | Valid UUID format | Must be a string |
| `array` | Table with sequential keys | No |
| `object` | Table | No |
| `any` | Any non-nil value | No |

## Validation Options

### Presence

| Option | Type | Description |
|--------|------|-------------|
| `required` | boolean | Field must be present and non-empty |
| `default` | any | Default value if field is missing or empty |

### String Constraints

| Option | Type | Description |
|--------|------|-------------|
| `min` | number | Minimum string length |
| `max` | number | Maximum string length |
| `length` | number | Exact string length |
| `pattern` | string | Lua pattern to match |
| `patternMessage` | string | Custom error message for pattern failure |
| `enum` | table | Array of allowed values |

### Numeric Constraints

| Option | Type | Description |
|--------|------|-------------|
| `minValue` | number | Minimum numeric value |
| `maxValue` | number | Maximum numeric value |

### Array Constraints

| Option | Type | Description |
|--------|------|-------------|
| `minItems` | number | Minimum array length |
| `maxItems` | number | Maximum array length |

### Transformations

| Option | Type | Description |
|--------|------|-------------|
| `trim` | boolean | Remove leading/trailing whitespace |
| `lowercase` | boolean | Convert to lowercase |
| `uppercase` | boolean | Convert to uppercase |
| `transform` | function | Custom transform: `function(value) return value end` |

### Custom Validation

| Option | Type | Description |
|--------|------|-------------|
| `validate` | function | Custom validator: `function(value) return ok, message end` |

```lua
local schema = honeymoon.schema({
    password = {
        type = "string",
        required = true,
        min = 8,
        validate = function(value)
            if not value:match("[%d]") then
                return false, "must contain at least one digit"
            end
            if not value:match("[%u]") then
                return false, "must contain at least one uppercase letter"
            end
            return true
        end,
    },
})
```

## Validating Data

### schema:validate(data)

Validate a data table against the schema:

```lua
local valid, sanitized, errors = schema:validate(data)
```

| Return | Type | Description |
|--------|------|-------------|
| `valid` | boolean | Whether validation passed |
| `sanitized` | table or nil | Cleaned data on success |
| `errors` | table or nil | Error details on failure |

```lua
local valid, sanitized, errors = userSchema:validate({
    username = "  Alice  ",
    email = "ALICE@EXAMPLE.COM",
    age = "25",
})

if valid then
    -- sanitized = { username = "alice", email = "alice@example.com", age = 25, role = "user" }
    print(sanitized.username)  -- "alice" (trimmed + lowercased)
    print(sanitized.age)       -- 25 (coerced to integer)
    print(sanitized.role)      -- "user" (default applied)
else
    -- errors = { fieldName = { "error message 1", "error message 2" } }
    for field, messages in pairs(errors) do
        for _, msg in ipairs(messages) do
            print(field .. ": " .. msg)
        end
    end
end
```

## Using with Requests

### req:validate(schema)

Validate the request body. Throws a `ValidationError` automatically on failure, which HoneyMoon catches and returns as a 422 response:

```lua
app:post("/api/users", function(req, res)
    local data = req:validate(userSchema)
    -- If we get here, data is valid and sanitized
    local user = User:create(data)
    res:status(201):json({ user = user })
end)
```

### req:validateQuery(schema)

Validate query parameters:

```lua
local paginationSchema = honeymoon.schema({
    page = { type = "integer", default = 1, minValue = 1 },
    limit = { type = "integer", default = 25, minValue = 1, maxValue = 100 },
    sort = { type = "string", enum = { "name", "created_at", "email" }, default = "created_at" },
    order = { type = "string", enum = { "asc", "desc" }, default = "desc", lowercase = true },
})

app:get("/api/users", function(req, res)
    local query = req:validateQuery(paginationSchema)
    local users = User:orderBy(query.sort, query.order)
        :paginate(query.page, query.limit)
        :all()
    res:json({ users = users })
end)
```

### req:validateParams(schema)

Validate route parameters:

```lua
local idSchema = honeymoon.schema({
    id = { type = "integer", required = true, minValue = 1 },
})

app:get("/api/users/:id", function(req, res)
    local params = req:validateParams(idSchema)
    local user = User:find(params.id)
    if not user then
        return res:status(404):json({ error = "User not found" })
    end
    res:json({ user = user })
end)
```

### Manual Validation

For more control over error responses:

```lua
app:post("/api/users", function(req, res)
    local valid, sanitized, errors = userSchema:validate(req:json())
    if not valid then
        return res:status(422):json({
            error = {
                status = 422,
                message = "Validation failed",
                code = "VALIDATION_ERROR",
                details = errors,
            }
        })
    end
    local user = User:create(sanitized)
    res:status(201):json({ user = user })
end)
```

## Schema Manipulation

### schema:partial()

Create a new schema where all fields are optional (useful for PATCH updates):

```lua
local updateSchema = userSchema:partial()

app:patch("/api/users/:id", function(req, res)
    local data = req:validate(updateSchema)
    -- Only provided fields are validated
end)
```

### schema:extend(fields)

Add additional fields to a schema:

```lua
local registrationSchema = userSchema:extend({
    password = { type = "string", required = true, min = 8 },
    confirmPassword = { type = "string", required = true },
})
```

### schema:pick(fields)

Create a schema with only specified fields:

```lua
local loginSchema = userSchema:pick({ "email" }):extend({
    password = { type = "string", required = true },
})
```

### schema:omit(fields)

Create a schema without specified fields:

```lua
local publicSchema = userSchema:omit({ "password", "secretToken" })
```

## Schema Presets

HoneyMoon provides common field presets:

```lua
local schema = honeymoon.schema({
    email = honeymoon.preset("email"),
    password = honeymoon.preset("password"),
    username = honeymoon.preset("username"),
    id = honeymoon.preset("uuid"),
    count = honeymoon.preset("positiveInt"),
    limit = honeymoon.preset("limit"),
    offset = honeymoon.preset("offset"),
    website = honeymoon.preset("url"),
    name = honeymoon.preset("nonEmptyString"),
})
```

| Preset | Equivalent |
|--------|------------|
| `email` | `{ type = "email", lowercase = true, trim = true }` |
| `password` | `{ type = "string", required = true, min = 8, max = 128 }` |
| `username` | `{ type = "string", required = true, min = 3, max = 32, trim = true, lowercase = true, pattern = "^[%w_]+$" }` |
| `uuid` | `{ type = "uuid", required = true }` |
| `positiveInt` | `{ type = "integer", minValue = 1 }` |
| `limit` | `{ type = "integer", default = 20, minValue = 1, maxValue = 100 }` |
| `offset` | `{ type = "integer", default = 0, minValue = 0 }` |
| `url` | `{ type = "url", trim = true }` |
| `nonEmptyString` | `{ type = "string", required = true, min = 1, trim = true }` |

## Validation Error Format

When `req:validate()` throws a `ValidationError`, HoneyMoon returns:

```json
{
    "error": {
        "status": 422,
        "message": "Validation failed",
        "code": "VALIDATION_ERROR",
        "details": {
            "username": ["must be at least 3 characters"],
            "email": ["must be a valid email address"],
            "age": ["must be an integer"]
        }
    }
}
```

## Complete Example

```lua
local honeymoon = require("honeymoon")
local app = honeymoon.new()

app:use(honeymoon.json())

-- Define schemas
local createUserSchema = honeymoon.schema({
    username = honeymoon.preset("username"),
    email = honeymoon.preset("email"),
    password = honeymoon.preset("password"),
    age = { type = "integer", minValue = 13 },
    bio = { type = "string", max = 500, trim = true },
})

local updateUserSchema = createUserSchema:partial():omit({ "password" })

local querySchema = honeymoon.schema({
    page = honeymoon.preset("offset"),
    limit = honeymoon.preset("limit"),
    search = { type = "string", trim = true },
})

-- Routes
app:post("/api/users", function(req, res)
    local data = req:validate(createUserSchema)
    local user = User:create(data)
    res:status(201):json({ user = user })
end)

app:patch("/api/users/:id", function(req, res)
    local data = req:validate(updateUserSchema)
    local user = User:findOrFail(req.params.id)
    for key, value in pairs(data) do
        user[key] = value
    end
    user:save()
    res:json({ user = user })
end)

app:get("/api/users", function(req, res)
    local query = req:validateQuery(querySchema)
    local users = User:paginate(query.page, query.limit):all()
    res:json({ users = users })
end)

app:listen(3000)
```
