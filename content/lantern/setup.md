# Setup

Lantern integrates with HoneyMoon in one line. It automatically adds middleware that collects request data and injects the debug panel into HTML responses.

## Basic Setup

```lua
local honeymoon = require("honeymoon")
local lantern = require("lantern")
local app = honeymoon.new()

lantern.setup(app)
```

This enables Lantern with default settings. The panel is automatically injected before `</body>` in all HTML responses.

## Configuration

### lantern.setup(app, options?)

```lua
lantern.setup(app, {
    enabled = true,
    htmlOnly = true,
    vein = app.views.engine,
    ignorePaths = { "/api/", "/public/" },
    condition = function(req)
        return not req.path:match("^/health")
    end,
})
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `true` in dev | Enable or disable the toolbar |
| `htmlOnly` | boolean | `true` | Only inject into HTML responses |
| `vein` | table | `nil` | Vein engine instance for template metrics |
| `ignorePaths` | table | `{}` | Array of path prefixes to skip |
| `condition` | function | `nil` | Custom function `(req) → boolean` to decide injection |

### Environment Detection

When `enabled` is not specified, Lantern checks the `NODE_ENV` environment variable and auto-enables in non-production environments:

```lua
-- Auto-detected: enabled in development
lantern.setup(app)

-- Explicit control
lantern.setup(app, {
    enabled = os_ext.env("NODE_ENV") ~= "production",
})
```

## Vein Integration

To capture template rendering metrics, pass the Vein engine to Lantern:

```lua
-- Setup Vein with metrics
app.views:use("vein")
app.views:set("metrics", true)

-- Pass engine to Lantern
lantern.setup(app, {
    vein = app.views.engine,
})
```

When the Vein engine is provided, Lantern automatically enables metrics on it and collects:

- Total renders and render time
- Cache hit/miss rate
- Per-template render statistics
- Template errors
- Filter usage

If `app.views.engine` exists, Lantern detects it automatically even without explicit configuration.

## Freight Integration

To track database queries, wrap your Freight database instance:

```lua
local freight = require("freight")
local db = freight.open("sqlite", { database = "./data/app.db" })

-- Wrap database for query logging
lantern.freight(db)

-- Add per-request middleware
app:use(lantern.freightMiddleware(db))
```

See [Freight Integration](/docs/lantern/freight-integration) for details.

## Manual Middleware

Instead of `lantern.setup()`, you can add the middleware manually:

```lua
app:use(lantern.middleware({
    enabled = true,
    vein = veinEngine,
    htmlOnly = true,
    ignorePaths = { "/api" },
}))
```

This gives you full control over middleware ordering.

## Ignoring Paths

Skip Lantern injection for specific route prefixes:

```lua
lantern.setup(app, {
    ignorePaths = {
        "/api/",       -- API routes (JSON responses)
        "/public/",    -- Static files
        "/health",     -- Health check endpoint
        "/webhooks/",  -- Webhook endpoints
    },
})
```

## Custom Condition

Use a function for fine-grained control over when Lantern runs:

```lua
lantern.setup(app, {
    condition = function(req)
        -- Only show for admin users
        if req.session and req.session.role == "admin" then
            return true
        end
        return false
    end,
})
```

## Complete Example

```lua
local honeymoon = require("honeymoon")
local lantern = require("lantern")
local freight = require("freight")

local app = honeymoon.new()
app:set("env", os_ext.env("NODE_ENV") or "development")

-- View engine
app.views:use("vein")
app.views:set("views", "./views")
app.views:set("metrics", true)

-- Database
local db = freight.open("sqlite", { database = "./data/app.db" })

-- Lantern setup
lantern.setup(app, {
    enabled = app:get_setting("env") ~= "production",
    vein = app.views.engine,
    ignorePaths = { "/api/", "/public/" },
})

-- Freight query tracking
lantern.freight(db)
app:use(lantern.freightMiddleware(db))

-- Middleware
app:use(honeymoon.logger())
app:use(honeymoon.json())
app:use(honeymoon.session({ secret = "dev-secret" }))
app:use("/public", honeymoon.static("./public"))

-- Routes
app:get("/", function(req, res)
    req.lantern:info("Rendering homepage")
    local users = User:all()
    res:render("index", { users = users })
end)

app:listen(3000)
```
