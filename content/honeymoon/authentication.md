# Authentication

HoneyMoon provides built-in middleware for common authentication strategies: Basic Auth, Bearer Token, API Key, and JWT. It also includes authorization helpers for role-based access control.

## Basic Authentication

HTTP Basic Authentication with username and password.

### Static Credentials

```lua
app:use("/admin", honeymoon.basicAuth({
    realm = "Admin Area",
    users = {
        admin = "secret123",
        moderator = "mod456",
    },
    message = "Authentication required",
}))
```

| Option | Default | Description |
|--------|---------|-------------|
| `realm` | `"Restricted"` | Realm shown in the browser prompt |
| `users` | `nil` | Table of `username = password` pairs |
| `validate` | `nil` | Custom validation function |
| `message` | `"Authentication required"` | Error message on failure |

### Custom Validation

Use a `validate` function to check credentials against a database:

```lua
app:use("/admin", honeymoon.basicAuth({
    realm = "Admin",
    validate = function(username, password, req)
        local user = User:where({ username = username }):first()
        if user and verifyPassword(password, user.password_hash) then
            return { id = user.id, username = user.username, role = user.role }
        end
        return nil
    end,
}))
```

The value returned by `validate` is set as `req.user`:

```lua
app:get("/admin/dashboard", function(req, res)
    print("Logged in as: " .. req.user.username)
    res:render("admin/dashboard", { user = req.user })
end)
```

## Bearer Token Authentication

Authenticate using a token in the `Authorization: Bearer <token>` header.

```lua
app:use("/api", honeymoon.bearerAuth({
    validate = function(token, req)
        -- Verify the token and return user data or nil
        local payload = verifyToken(token)
        if payload then
            return { id = payload.sub, scope = payload.scope }
        end
        return nil
    end,
    message = "Invalid or expired token",
}))
```

| Option | Default | Description |
|--------|---------|-------------|
| `validate` | required | Function receiving `(token, req)`, returns user or nil |
| `message` | `"Invalid token"` | Error message on failure |

```lua
app:get("/api/profile", function(req, res)
    -- req.user is set by bearerAuth
    res:json({ user = req.user })
end)
```

## API Key Authentication

Authenticate using an API key sent as a header or query parameter.

### Static Keys

```lua
app:use("/api", honeymoon.apiKeyAuth({
    header = "x-api-key",
    query = "api_key",
    keys = {
        ["key-abc-123"] = { id = "app1", name = "Mobile App" },
        ["key-def-456"] = { id = "app2", name = "Web App" },
    },
}))
```

| Option | Default | Description |
|--------|---------|-------------|
| `header` | `"x-api-key"` | Header name to check |
| `query` | `"api_key"` | Query parameter name to check |
| `keys` | `nil` | Table mapping keys to user data |
| `validate` | `nil` | Custom validation function |

The middleware checks the header first, then the query parameter.

### Simple Key List

Pass an array of valid keys (without user data):

```lua
app:use("/api", honeymoon.apiKeyAuth({
    keys = { "key-abc-123", "key-def-456" },
}))
```

### Custom Validation

```lua
app:use("/api", honeymoon.apiKeyAuth({
    validate = function(key, req)
        local apiKey = ApiKey:where({ key = key, is_active = true }):first()
        if apiKey then
            return { id = apiKey.user_id, name = apiKey.name, scope = apiKey.scope }
        end
        return nil
    end,
}))
```

## JWT Authentication

JSON Web Token authentication:

```lua
app:use("/api", honeymoon.jwtAuth({
    secret = os_ext.env("JWT_SECRET"),
    validate = function(payload, req)
        -- payload is the decoded JWT
        if payload.exp and payload.exp < os.time() then
            return nil  -- Token expired
        end
        return { id = payload.sub, role = payload.role }
    end,
}))
```

| Option | Default | Description |
|--------|---------|-------------|
| `secret` | required | Secret key for verification |
| `validate` | required | Function receiving `(payload, req)`, returns user or nil |

## Authorization

After authentication, use authorization middleware to control access.

### honeymoon.requireAuth(options?)

Require any authenticated user:

```lua
app:use("/account", honeymoon.requireAuth({
    message = "Please log in to continue",
}))
```

Checks that `req.user` is set. Returns 401 if not.

### honeymoon.requireRoles(roles)

Require specific user roles:

```lua
-- Single role
app:use("/admin", honeymoon.requireRoles("admin"))

-- Multiple roles (any match)
app:use("/staff", honeymoon.requireRoles({ "admin", "moderator" }))
```

Checks `req.user.role` against the specified roles. Returns 403 if the role doesn't match.

### honeymoon.requirePermission(check, message?)

Custom permission check:

```lua
app:use("/billing", honeymoon.requirePermission(
    function(req)
        return req.user and req.user.plan == "premium"
    end,
    "Premium plan required"
))
```

## Combining Authentication Methods

### honeymoon.auth.any(methods)

Try multiple authentication methods. The first one that succeeds is used:

```lua
local auth = honeymoon.auth.any({
    honeymoon.bearerAuth({
        validate = function(token, req)
            return verifyJWT(token)
        end,
    }),
    honeymoon.apiKeyAuth({
        keys = validApiKeys,
    }),
    honeymoon.basicAuth({
        users = { admin = "secret" },
    }),
})

app:use("/api", auth)
```

## Protecting Routes

### Middleware on Specific Routes

Apply auth to individual routes using multiple handlers:

```lua
local requireAdmin = honeymoon.requireRoles("admin")

app:get("/admin/users", requireAdmin, function(req, res)
    local users = User:all()
    res:json({ users = users })
end)

app:delete("/admin/users/:id", requireAdmin, function(req, res)
    User:findOrFail(req.params.id):deleteInstance()
    res:json({ deleted = true })
end)
```

### Route Groups

Protect a group of routes by mounting auth on a path prefix:

```lua
-- Public routes
app:get("/api/status", function(req, res)
    res:json({ status = "ok" })
end)

-- Protected API routes
app:use("/api", honeymoon.bearerAuth({
    validate = validateToken,
}))

app:get("/api/profile", function(req, res)
    res:json({ user = req.user })
end)

app:get("/api/settings", function(req, res)
    -- req.user is available
end)
```

## Complete Example

```lua
local honeymoon = require("honeymoon")
local app = honeymoon.new()

app:use(honeymoon.json())
app:use(honeymoon.session({ secret = "secret" }))

-- Public routes
app:get("/", function(req, res)
    res:render("index")
end)

app:post("/auth/login", function(req, res)
    local data = req:json()
    local user = User:where({ email = data.email }):first()

    if not user or not verifyPassword(data.password, user.password_hash) then
        return res:status(401):json({ error = "Invalid credentials" })
    end

    local token = generateJWT({ sub = user.id, role = user.role })
    res:json({ token = token, user = { id = user.id, name = user.name } })
end)

-- API authentication
app:use("/api", honeymoon.bearerAuth({
    validate = function(token, req)
        local payload = verifyJWT(token)
        if not payload then return nil end
        local user = User:find(payload.sub)
        if not user then return nil end
        return { id = user.id, name = user.name, role = user.role }
    end,
}))

-- Regular user routes
app:get("/api/profile", function(req, res)
    res:json({ user = req.user })
end)

app:put("/api/profile", function(req, res)
    local data = req:validate(profileSchema)
    local user = User:find(req.user.id)
    user.name = data.name or user.name
    user.bio = data.bio or user.bio
    user:save()
    res:json({ user = user })
end)

-- Admin routes
app:use("/api/admin", honeymoon.requireRoles("admin"))

app:get("/api/admin/users", function(req, res)
    local users = User:all()
    res:json({ users = users })
end)

app:delete("/api/admin/users/:id", function(req, res)
    User:findOrFail(req.params.id):deleteInstance()
    res:json({ deleted = true })
end)

-- API key authentication for external integrations
app:use("/webhooks", honeymoon.apiKeyAuth({
    header = "x-webhook-secret",
    validate = function(key, req)
        return Webhook:where({ secret = key, is_active = true }):first()
    end,
}))

app:post("/webhooks/payment", function(req, res)
    local data = req:json()
    processPayment(data)
    res:json({ received = true })
end)

app:listen(3000)
```
