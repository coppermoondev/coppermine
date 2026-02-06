# Database Integration

CopperMoon supports SQLite, MySQL, PostgreSQL, and Redis out of the box. This guide covers common patterns for backend services.

## SQLite

SQLite is built into CopperMoon with no external dependencies. Ideal for single-server applications, development, and embedded databases.

### Setup

```lua
local db = sqlite.open("app.db")

-- Create tables
db:exec([[
    CREATE TABLE IF NOT EXISTS posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        author_id INTEGER REFERENCES users(id),
        published BOOLEAN DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now'))
    )
]])
```

### Parameterized Queries

Always use parameterized queries to prevent SQL injection:

```lua
-- Safe - parameters are escaped
local user = db:query_row("SELECT * FROM users WHERE email = ?", email)
db:execute("INSERT INTO users (name, email) VALUES (?, ?)", name, email)

-- NEVER do this - vulnerable to SQL injection
-- db:query("SELECT * FROM users WHERE email = '" .. email .. "'")
```

### Transactions

Wrap multiple operations in a transaction for atomicity:

```lua
db:transaction(function()
    db:execute("INSERT INTO orders (user_id, total) VALUES (?, ?)", user_id, total)
    local order_id = db:last_insert_id()

    for _, item in ipairs(items) do
        db:execute(
            "INSERT INTO order_items (order_id, product_id, qty) VALUES (?, ?, ?)",
            order_id, item.product_id, item.qty
        )
    end

    db:execute(
        "UPDATE users SET order_count = order_count + 1 WHERE id = ?",
        user_id
    )
end)
```

If any statement fails, the entire transaction is rolled back.

### Query Helpers

```lua
-- Get all rows
local posts = db:query("SELECT * FROM posts WHERE published = 1 ORDER BY created_at DESC")

-- Get single row (nil if not found)
local post = db:query_row("SELECT * FROM posts WHERE id = ?", post_id)

-- Get change count
db:execute("UPDATE posts SET published = 1 WHERE author_id = ?", author_id)
local updated = db:changes()

-- Check table existence
if db:table_exists("migrations") then
    -- run migrations
end
```

## MySQL

MySQL support is built-in for production databases and larger applications.

### Connection

```lua
-- With options table
local db = mysql.connect({
    host = "localhost",
    port = 3306,
    user = "root",
    password = "secret",
    database = "myapp",
})

-- With URL
local db = mysql.open("mysql://root:secret@localhost:3306/myapp")
```

### Usage

MySQL uses the same query API as SQLite:

```lua
local users = db:query("SELECT * FROM users LIMIT ?", 10)
local user = db:query_row("SELECT * FROM users WHERE id = ?", id)
db:execute("INSERT INTO users (name, email) VALUES (?, ?)", name, email)
db:transaction(function()
    -- atomic operations
end)
```

## PostgreSQL

PostgreSQL support is built-in for production databases requiring advanced features like JSONB, arrays, and native UUID types.

### Connection

```lua
-- With options table
local db = postgresql.connect({
    host = "localhost",
    port = 5432,
    user = "postgres",
    password = "secret",
    database = "myapp",
})

-- With URL
local db = postgresql.open("postgres://postgres:secret@localhost:5432/myapp")
```

### Usage

PostgreSQL uses the same query API as SQLite and MySQL. Use `?` placeholders — they are automatically converted to `$1, $2, ...`:

```lua
local users = db:query("SELECT * FROM users LIMIT ?", 10)
local user = db:query_row("SELECT * FROM users WHERE id = ?", id)
db:execute("INSERT INTO users (name, email) VALUES (?, ?)", name, email)
db:transaction(function()
    -- atomic operations
end)
```

### PostgreSQL-specific Types

```lua
-- JSONB columns
db:exec("CREATE TABLE settings (id SERIAL PRIMARY KEY, data JSONB)")
db:execute("INSERT INTO settings (data) VALUES (?)", json.encode({ theme = "dark" }))

-- UUID columns
db:exec("CREATE TABLE tokens (id UUID DEFAULT gen_random_uuid(), value TEXT)")

-- Arrays and advanced types work through string representation
```

## Redis

Redis is available as a native module for caching, sessions, queues, and pub/sub.

### Setup

```lua
local redis = require("redis")
local client = redis.connect("127.0.0.1", 6379)

-- With authentication
client:auth("password")

-- Select database
client:select(1)
```

### Caching

Cache expensive query results in Redis:

```lua
local function get_user(id)
    -- Check cache first
    local cached = client:get("user:" .. id)
    if cached then
        return json.decode(cached)
    end

    -- Query database
    local user = db:query_row("SELECT * FROM users WHERE id = ?", id)
    if user then
        -- Cache for 5 minutes
        client:setex("user:" .. id, 300, json.encode(user))
    end

    return user
end

-- Invalidate cache on update
local function update_user(id, data)
    db:execute("UPDATE users SET name = ? WHERE id = ?", data.name, id)
    client:del("user:" .. id)
end
```

### Session Storage

Store user sessions in Redis:

```lua
local function create_session(user_id)
    local session_id = crypto.uuid()
    local session = {
        user_id = user_id,
        created_at = time.now(),
    }
    client:setex("session:" .. session_id, 3600, json.encode(session))
    return session_id
end

local function get_session(session_id)
    local data = client:get("session:" .. session_id)
    if data then
        return json.decode(data)
    end
    return nil
end

local function destroy_session(session_id)
    client:del("session:" .. session_id)
end
```

### Job Queues

Simple job queue pattern using Redis lists:

```lua
-- Producer: push jobs
local function enqueue(queue_name, job_data)
    client:rpush("queue:" .. queue_name, json.encode(job_data))
end

enqueue("emails", {
    to = "user@example.com",
    subject = "Welcome!",
    template = "welcome",
})

-- Worker: process jobs
local function process_queue(queue_name, handler)
    while true do
        local raw = client:lpop("queue:" .. queue_name)
        if raw then
            local job = json.decode(raw)
            local ok, err = pcall(handler, job)
            if not ok then
                -- Push to dead letter queue
                client:rpush("queue:" .. queue_name .. ":failed", json.encode({
                    job = job,
                    error = tostring(err),
                    failed_at = time.now(),
                }))
            end
        else
            time.sleep(1000) -- poll interval
        end
    end
end

process_queue("emails", function(job)
    send_email(job.to, job.subject, job.template)
end)
```

### Counters and Rate Limiting

```lua
-- Increment page views
client:incr("views:page:" .. page_id)

-- Rate limiting with Redis
local function check_rate_limit(key, max_requests, window)
    local current = tonumber(client:get(key)) or 0
    if current >= max_requests then
        return false
    end
    local count = client:incr(key)
    if count == 1 then
        client:expire(key, window)
    end
    return true
end

-- 100 requests per minute per IP
local allowed = check_rate_limit("rate:" .. client_ip, 100, 60)
```

## Freight ORM

For structured data access, use the Freight ORM:

```lua
local freight = require("freight")
freight.init(db)

-- Define model
local User = freight.model("users", {
    fields = {
        name = { type = "text", required = true },
        email = { type = "text", required = true, unique = true },
        role = { type = "text", default = "user" },
    }
})

-- CRUD operations
local user = User:create({ name = "Alice", email = "alice@example.com" })
local users = User:all()
local admin = User:find_by("role", "admin")
user:update({ role = "admin" })
user:delete()
```

See the [Freight documentation](/docs/freight/overview) for the full ORM guide.

## Database Connection Patterns

### Connection at Startup

Open the connection once and reuse it:

```lua
-- config.lua
local db = sqlite.open(os_ext.env("DATABASE_PATH") or "app.db")
return { db = db }
```

```lua
-- app.lua
local config = require("config")
local db = config.db

app:get("/api/users", function(req, res)
    local users = db:query("SELECT * FROM users")
    res:json({ data = users })
end)
```

### Health Checks

Add a health check endpoint that verifies database connectivity:

```lua
app:get("/health", function(req, res)
    local checks = {}

    -- SQLite
    local ok, err = pcall(function()
        db:query_row("SELECT 1")
    end)
    checks.database = ok and "ok" or tostring(err)

    -- Redis
    local ok2, err2 = pcall(function()
        client:ping()
    end)
    checks.redis = ok2 and "ok" or tostring(err2)

    local all_ok = checks.database == "ok" and checks.redis == "ok"
    res:status(all_ok and 200 or 503):json({
        status = all_ok and "healthy" or "degraded",
        checks = checks,
    })
end)
```

## Next Steps

- [REST APIs](/docs/backend-services/rest-api) - Use databases in API routes
- [Middleware Patterns](/docs/backend-services/middleware-patterns) - Auth and rate limiting
- [Freight ORM](/docs/freight/overview) - Full ORM documentation
- [Redis](/docs/redis/overview) - Complete Redis reference
