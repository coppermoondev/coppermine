# Routing

HoneyMoon provides Express-style routing with support for all HTTP methods, route parameters, wildcards, multiple handlers, and modular routers.

## HTTP Methods

Define routes for any HTTP method:

```lua
app:get("/users", handler)
app:post("/users", handler)
app:put("/users/:id", handler)
app:delete("/users/:id", handler)
app:patch("/users/:id", handler)
app:options("/users", handler)
app:head("/users", handler)
```

### app:all(path, handler)

Match any HTTP method:

```lua
app:all("/api/*", function(req, res)
    print("API request: " .. req.method .. " " .. req.path)
end)
```

## Route Handlers

A route handler receives the request, response, and a `next` function:

```lua
app:get("/hello", function(req, res, next)
    res:send("Hello!")
end)
```

| Parameter | Description |
|-----------|-------------|
| `req` | Request object with headers, params, body, etc. |
| `res` | Response object with send, json, render, etc. |
| `next` | Call to pass control to the next handler |

## Route Parameters

### Named Parameters

Capture segments of the URL path with `:name`:

```lua
app:get("/users/:id", function(req, res)
    local userId = req.params.id
    res:json({ userId = userId })
end)
```

### Multiple Parameters

```lua
app:get("/users/:userId/posts/:postId", function(req, res)
    local userId = req.params.userId
    local postId = req.params.postId
    res:json({ userId = userId, postId = postId })
end)
```

### Wildcard Routes

Capture everything after a path with `*`:

```lua
app:get("/files/*", function(req, res)
    local filepath = req.params["*"]
    -- or
    local filepath = req.params.wildcard
    res:send("File: " .. filepath)
end)
```

A request to `/files/images/photo.png` sets `req.params["*"]` to `"images/photo.png"`.

## Multiple Handlers

Pass multiple handler functions to a route. Each calls `next()` to continue:

```lua
local function authenticate(req, res, next)
    if not req.session.userId then
        return res:status(401):json({ error = "Unauthorized" })
    end
    next()
end

local function authorize(req, res, next)
    if req.user.role ~= "admin" then
        return res:status(403):json({ error = "Forbidden" })
    end
    next()
end

app:delete("/users/:id", authenticate, authorize, function(req, res)
    -- Only reached if both checks pass
    res:json({ deleted = true })
end)
```

## Routers

Break your application into modular route groups using `honeymoon.Router`.

### Creating a Router

```lua
local router = honeymoon.Router.new()

router:get("/", function(req, res)
    res:json({ users = {} })
end)

router:get("/:id", function(req, res)
    res:json({ userId = req.params.id })
end)

router:post("/", function(req, res)
    local data = req:json()
    res:status(201):json({ created = true })
end)
```

### Mounting a Router

Mount a router at a base path with `app:mount()`:

```lua
app:mount("/api/users", router)
```

Now the router's routes are available at:
- `GET /api/users/` → list users
- `GET /api/users/:id` → get user
- `POST /api/users/` → create user

### Multiple Routers

Organize a large application into separate route modules:

```lua
-- routes/users.lua
local router = honeymoon.Router.new()
router:get("/", listUsers)
router:post("/", createUser)
router:get("/:id", getUser)
router:put("/:id", updateUser)
router:delete("/:id", deleteUser)
return router

-- routes/posts.lua
local router = honeymoon.Router.new()
router:get("/", listPosts)
router:post("/", createPost)
return router

-- app.lua
local users = require("routes.users")
local posts = require("routes.posts")

app:mount("/api/users", users)
app:mount("/api/posts", posts)
```

## Route Patterns

Routes are compiled into patterns internally:

| Pattern | Matches | Example |
|---------|---------|---------|
| `/users` | Exact path | `/users` |
| `/users/:id` | Named parameter | `/users/42` |
| `/users/:id/posts` | Mixed | `/users/42/posts` |
| `/files/*` | Wildcard | `/files/any/nested/path` |

Special regex characters in paths are automatically escaped. Parameters become capture groups, and patterns are anchored to match the full path.

## Complete Example

### REST API

```lua
local honeymoon = require("honeymoon")
local app = honeymoon.new()

app:use(honeymoon.json())

-- Health check
app:get("/health", function(req, res)
    res:json({ status = "ok" })
end)

-- User routes
app:get("/api/users", function(req, res)
    local page = tonumber(req.query.page) or 1
    local limit = tonumber(req.query.limit) or 25
    local users = User:paginate(page, limit):all()
    res:json({ users = users, page = page })
end)

app:get("/api/users/:id", function(req, res)
    local user = User:find(req.params.id)
    if not user then
        return res:status(404):json({ error = "User not found" })
    end
    res:json({ user = user })
end)

app:post("/api/users", function(req, res)
    local data = req:json()
    local user = User:create(data)
    res:status(201):json({ user = user })
end)

app:put("/api/users/:id", function(req, res)
    local user = User:find(req.params.id)
    if not user then
        return res:status(404):json({ error = "User not found" })
    end
    local data = req:json()
    user.name = data.name or user.name
    user.email = data.email or user.email
    user:save()
    res:json({ user = user })
end)

app:delete("/api/users/:id", function(req, res)
    local user = User:find(req.params.id)
    if not user then
        return res:status(404):json({ error = "User not found" })
    end
    user:deleteInstance()
    res:json({ deleted = true })
end)

app:listen(3000)
```
