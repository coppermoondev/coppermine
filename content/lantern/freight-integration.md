# Freight Integration

Lantern can automatically capture and display all database queries made through the Freight ORM. Every query shows the SQL, parameters, execution time, and results — directly in the Queries panel.

## Setup

Two steps are required: wrap the database instance and add the per-request middleware.

```lua
local freight = require("freight")
local lantern = require("lantern")

local db = freight.open("sqlite", { database = "./data/app.db" })

-- 1. Wrap the database instance
lantern.freight(db)

-- 2. Add per-request middleware
app:use(lantern.freightMiddleware(db))
```

### lantern.freight(db, options?)

Wraps Freight's `query()`, `query_row()`, and `execute()` methods to intercept all database operations.

```lua
lantern.freight(db, {
    captureResults = true,
    maxResultRows = 50,
    maxColumnWidth = 200,
})
```

| Option | Default | Description |
|--------|---------|-------------|
| `captureResults` | `true` | Capture SELECT result sets for viewing |
| `maxResultRows` | `50` | Max rows to capture per query (prevents memory issues) |
| `maxColumnWidth` | `200` | Truncate long column values at this length |

### lantern.freightMiddleware(db)

Creates middleware that connects query logging to individual requests. Without this, queries appear in global stats but not in the per-request panel.

```lua
app:use(lantern.freightMiddleware(db))
```

The middleware:
1. Creates a per-request query listener
2. Attaches it to the Freight logger
3. Removes the listener when the response is sent
4. Prevents query leakage between concurrent requests

## What Gets Captured

For each query, Lantern records:

| Field | Description |
|-------|-------------|
| `type` | Query type: SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER |
| `sql` | The full SQL string |
| `params` | Query parameters (bound values) |
| `duration` | Execution time in milliseconds |
| `rowCount` | Rows returned (SELECT) or affected (INSERT/UPDATE/DELETE) |
| `timestamp` | When the query was executed |
| `results` | Result set for SELECT queries (if `captureResults` enabled) |
| `lastInsertId` | Auto-generated ID for INSERT queries |

## Query Type Detection

Lantern automatically detects the query type from the SQL:

| Prefix | Detected Type |
|--------|---------------|
| `SELECT` | SELECT |
| `INSERT` | INSERT |
| `UPDATE` | UPDATE |
| `DELETE` | DELETE |
| `CREATE` | CREATE |
| `DROP` | DROP |
| `ALTER` | ALTER |
| Other | EXECUTE |

## Results Viewer

For SELECT queries, the Queries panel provides an expandable results viewer:

- Click **View** to expand the result table
- Columns are sorted alphabetically
- Rows are limited to `maxResultRows` (default 50)
- Long values are truncated to `maxColumnWidth` (default 200)
- If results were truncated, a "Showing X of Y rows" indicator appears

For INSERT queries, the panel shows the **last insert ID**.

For UPDATE/DELETE queries, the panel shows the **affected row count**.

## Slow Query Detection

Queries are highlighted as slow when:
- Duration exceeds 2x the average query time
- AND duration exceeds 10ms

This prevents false positives on fast queries.

## Global Statistics

Track query statistics across all requests:

```lua
-- Get global stats
local stats = lantern.getFreightStats()
print(stats.totalQueries)      -- Total queries since startup
print(stats.totalDuration)     -- Total execution time (ms)
print(stats.queryTypes.SELECT) -- Count by type

-- Reset counters
lantern.resetFreightStats()
```

## Using with ORM Queries

All Freight ORM operations are captured automatically — there is no difference between raw queries and ORM queries:

```lua
app:get("/users", function(req, res)
    -- These are all captured in the Queries panel:

    -- ORM queries
    local users = User:where({ is_active = true }):orderBy("name"):all()
    local count = User:count()
    local admin = User:where({ role = "admin" }):first()

    -- Raw queries
    local stats = db:query("SELECT role, COUNT(*) as c FROM users GROUP BY role")

    res:render("users", { users = users, count = count })
end)
```

## Manual Query Recording

Record queries from non-Freight sources:

```lua
app:get("/external", function(req, res)
    local startTime = os.clock()
    -- ... execute query with external driver ...
    local duration = (os.clock() - startTime) * 1000

    req.lantern:recordQuery(
        "SELECT * FROM external_table WHERE id = ?",  -- SQL
        { 42 },       -- Parameters
        duration,      -- Duration in ms
        1,             -- Row count
        "SELECT",      -- Query type (auto-detected if omitted)
        results,       -- Optional: result set
        nil            -- Optional: lastInsertId
    )

    res:json({ data = results })
end)
```

## Complete Example

```lua
local honeymoon = require("honeymoon")
local lantern = require("lantern")
local freight = require("freight")

local app = honeymoon.new()

-- Database
local db = freight.open("sqlite", { database = "./data/blog.db" })

-- Models
local User = db:model("users", {
    id = freight.primaryKey(),
    name = freight.string(100),
    email = freight.string(255, { unique = true }),
})

local Post = db:model("posts", {
    id = freight.primaryKey(),
    user_id = freight.foreignKey("users"),
    title = freight.string(255),
    content = freight.text(),
})

db:autoMigrate(User, Post)

-- Lantern with Freight
lantern.setup(app, { enabled = true })
lantern.freight(db, {
    captureResults = true,
    maxResultRows = 25,
})
app:use(lantern.freightMiddleware(db))

-- Middleware
app:use(honeymoon.json())
app.views:use("vein")

-- Routes
app:get("/", function(req, res)
    req.lantern:info("Loading dashboard")

    local users = User:all()
    local posts = Post:include("author"):orderBy("created_at", "DESC"):limit(10):all()
    local stats = {
        users = User:count(),
        posts = Post:count(),
        published = Post:where({ status = "published" }):count(),
    }

    -- All queries above appear in the Lantern Queries panel

    res:render("dashboard", {
        users = users,
        posts = posts,
        stats = stats,
    })
end)

app:listen(3000)
```
