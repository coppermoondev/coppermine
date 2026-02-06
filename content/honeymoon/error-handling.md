# Error Handling

HoneyMoon provides structured error handling with error classes, custom error handlers, and automatic error responses for both API and HTML contexts.

## Error Classes

### HttpError

A general HTTP error with a status code, message, and optional error code:

```lua
local HttpError = honeymoon.HttpError

-- Throw an HTTP error
error(HttpError.new(404, "User not found", "USER_NOT_FOUND"))
```

| Property | Type | Description |
|----------|------|-------------|
| `status` | number | HTTP status code |
| `message` | string | Error message |
| `code` | string | Machine-readable error code |

### ValidationError

A 422 validation error with field-level error details:

```lua
local ValidationError = honeymoon.ValidationError

error(ValidationError.new({
    email = { "must be a valid email address" },
    name = { "is required", "must be at least 2 characters" },
}))
```

| Property | Type | Description |
|----------|------|-------------|
| `status` | number | Always `422` |
| `message` | string | `"Validation failed"` |
| `errors` | table | Field-level error messages |

### Error Factory Functions

Create common HTTP errors:

```lua
honeymoon.errors.badRequest(message)          -- 400
honeymoon.errors.unauthorized(message)        -- 401
honeymoon.errors.forbidden(message)           -- 403
honeymoon.errors.notFound(message)            -- 404
honeymoon.errors.methodNotAllowed(message)    -- 405
honeymoon.errors.conflict(message)            -- 409
honeymoon.errors.unprocessable(message)       -- 422
honeymoon.errors.tooManyRequests(message)     -- 429
honeymoon.errors.internal(message)            -- 500
```

Usage:

```lua
app:get("/api/users/:id", function(req, res)
    local user = User:find(req.params.id)
    if not user then
        error(honeymoon.errors.notFound("User not found"))
    end
    res:json({ user = user })
end)
```

## Error Handling Flow

When an error occurs in a route handler or middleware:

1. The error is caught by HoneyMoon's error handler
2. If it's a `ValidationError`, a 422 JSON response is returned
3. If it's an `HttpError`, the appropriate status and message are used
4. Custom error handlers run in the order they were registered
5. If no custom handler sends a response, the default handler runs

## Custom Error Handlers

### app:error(handler)

Register a custom error handler:

```lua
app:error(function(err, req, res, stack)
    -- err: the error object or message
    -- req: request object
    -- res: response object
    -- stack: stack trace string
end)
```

### Logging Errors

```lua
app:error(function(err, req, res, stack)
    -- Log to console
    print("[ERROR] " .. req.method .. " " .. req.path)
    print("  Message: " .. tostring(err))
    if stack then
        print("  Stack: " .. stack)
    end
end)
```

### JSON API Error Handler

```lua
app:error(function(err, req, res, stack)
    if res:sent() then return end

    local status = 500
    local message = "Internal Server Error"
    local code = "INTERNAL_ERROR"

    if type(err) == "table" and err.status then
        status = err.status
        message = err.message or message
        code = err.code or code
    end

    -- Hide internal details in production
    if app:get_setting("env") == "production" and status == 500 then
        message = "Internal Server Error"
    end

    res:status(status):json({
        error = {
            status = status,
            message = message,
            code = code,
        }
    })
end)
```

### HTML Error Handler

```lua
app:error(function(err, req, res, stack)
    if res:sent() then return end

    local status = 500
    local message = "Internal Server Error"

    if type(err) == "table" and err.status then
        status = err.status
        message = err.message or message
    end

    res:status(status):render("error", {
        status = status,
        message = message,
        stack = app:get_setting("env") == "development" and stack or nil,
    })
end)
```

### Multiple Error Handlers

Register multiple handlers. They run in order:

```lua
-- First: log all errors
app:error(function(err, req, res, stack)
    logToFile(err, req, stack)
end)

-- Second: send response
app:error(function(err, req, res, stack)
    if not res:sent() then
        res:status(500):json({ error = "Something went wrong" })
    end
end)
```

## Response Error Methods

### res:error(status, message, code?)

Send a JSON error response:

```lua
res:error(404, "User not found", "USER_NOT_FOUND")
```

Returns:

```json
{
    "error": {
        "status": 404,
        "message": "User not found",
        "code": "USER_NOT_FOUND"
    }
}
```

### res:validationError(errors)

Send a 422 validation error response:

```lua
res:validationError({
    email = { "must be a valid email address" },
    password = { "must be at least 8 characters" },
})
```

Returns:

```json
{
    "error": {
        "status": 422,
        "message": "Validation failed",
        "code": "VALIDATION_ERROR",
        "details": {
            "email": ["must be a valid email address"],
            "password": ["must be at least 8 characters"]
        }
    }
}
```

### res:errorPage(status, message, stack?)

Render an HTML error page. In development mode, the page includes the stack trace with syntax highlighting. In production, the stack trace is hidden:

```lua
res:errorPage(500, "Something went wrong", debug.traceback())
```

## Error Patterns

### Guard Clauses

Return early on errors to keep handlers clean:

```lua
app:get("/api/users/:id", function(req, res)
    local user = User:find(req.params.id)
    if not user then
        return res:status(404):json({ error = "User not found" })
    end

    local posts = user:posts()
    if #posts == 0 then
        return res:json({ user = user, posts = {} })
    end

    res:json({ user = user, posts = posts })
end)
```

### Throwing Errors

Throw `HttpError` to let the error handler deal with it:

```lua
app:get("/api/users/:id", function(req, res)
    local user = User:find(req.params.id)
    if not user then
        error(honeymoon.errors.notFound("User not found"))
    end
    res:json({ user = user })
end)
```

### Validation Errors

Using `req:validate()` automatically throws validation errors:

```lua
app:post("/api/users", function(req, res)
    -- Throws ValidationError if invalid → returns 422 automatically
    local data = req:validate(userSchema)
    local user = User:create(data)
    res:status(201):json({ user = user })
end)
```

### Checking Response State

Always check `res:sent()` before sending in error handlers to avoid double responses:

```lua
app:error(function(err, req, res, stack)
    if res:sent() then
        return  -- Response already sent, nothing to do
    end
    res:status(500):json({ error = "Internal Server Error" })
end)
```

## 404 Not Found

Handle unmatched routes with a catch-all at the end of your route definitions:

```lua
-- Define all routes first
app:get("/", homeHandler)
app:get("/about", aboutHandler)
app:use("/api", apiRouter)

-- Then add a 404 catch-all
app:all("*", function(req, res)
    res:status(404):json({
        error = {
            status = 404,
            message = "Route not found: " .. req.method .. " " .. req.path,
        }
    })
end)
```

For HTML applications:

```lua
app:all("*", function(req, res)
    res:status(404):render("404", {
        path = req.path,
    })
end)
```

## Complete Example

```lua
local honeymoon = require("honeymoon")
local app = honeymoon.new()

app:use(honeymoon.json())

-- Routes
app:get("/api/users", function(req, res)
    local users = User:all()
    res:json({ users = users })
end)

app:get("/api/users/:id", function(req, res)
    local user = User:find(req.params.id)
    if not user then
        error(honeymoon.errors.notFound("User not found"))
    end
    res:json({ user = user })
end)

app:post("/api/users", function(req, res)
    local data = req:validate(honeymoon.schema({
        name = { type = "string", required = true, min = 2 },
        email = { type = "email", required = true },
    }))
    local user = User:create(data)
    res:status(201):json({ user = user })
end)

app:delete("/api/users/:id", function(req, res)
    local user = User:find(req.params.id)
    if not user then
        error(honeymoon.errors.notFound("User not found"))
    end
    user:deleteInstance()
    res:json({ deleted = true })
end)

-- 404 handler
app:all("*", function(req, res)
    res:status(404):json({
        error = {
            status = 404,
            message = "Not found",
        }
    })
end)

-- Error handler
app:error(function(err, req, res, stack)
    -- Log
    print(string.format("[%s] ERROR %s %s: %s",
        os.date(), req.method, req.path, tostring(err)))

    if res:sent() then return end

    local status = 500
    local message = "Internal Server Error"
    local code = "INTERNAL_ERROR"

    if type(err) == "table" then
        if err.errors then
            -- Validation error
            return res:status(422):json({
                error = {
                    status = 422,
                    message = "Validation failed",
                    code = "VALIDATION_ERROR",
                    details = err.errors,
                }
            })
        end
        status = err.status or 500
        message = err.message or message
        code = err.code or code
    end

    res:status(status):json({
        error = {
            status = status,
            message = message,
            code = code,
        }
    })
end)

app:listen(3000)
```
