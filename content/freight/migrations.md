# Migrations

Migrations manage your database schema. Freight provides automatic migrations that create and update tables based on your model definitions, and custom migrations for more complex changes.

## Auto-Migration

### db:autoMigrate(...)

Pass your models to `autoMigrate()` to automatically create tables and add missing columns:

```lua
local result = db:autoMigrate(User, Post, Comment, Tag, PostTag)
```

Auto-migrate performs these operations:

- **Creates tables** that don't exist yet
- **Adds columns** that are missing from existing tables
- **Creates indexes** defined in model fields
- **Creates unique constraints** for fields marked `unique = true`

It does **not** drop columns, change column types, or remove tables. This makes it safe to run repeatedly.

### Return Value

`autoMigrate()` returns a result table:

```lua
local result = db:autoMigrate(User, Post)

print(result.success)              -- true/false

-- Tables that were created
for _, name in ipairs(result.created_tables) do
    print("Created table: " .. name)
end

-- Columns that were added
for _, col in ipairs(result.added_columns) do
    print("Added column: " .. col.table .. "." .. col.column)
end

-- Indexes that were created
for _, name in ipairs(result.created_indexes) do
    print("Created index: " .. name)
end

-- Errors (if any)
for _, err in ipairs(result.errors) do
    print("Error in " .. err.model .. ": " .. err.error)
end
```

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | Whether all operations succeeded |
| `changes` | table | Detailed list of changes |
| `errors` | table | Array of `{model, error}` |
| `created_tables` | table | Array of table names created |
| `added_columns` | table | Array of `{table, column}` |
| `created_indexes` | table | Array of index names created |

### Typical Usage

Run migrations at application startup:

```lua
local freight = require("freight")
local db = freight.open("sqlite", { database = "./data/app.db" })

-- Define models
local User = db:model("users", { ... })
local Post = db:model("posts", { ... })

-- Migrate
local result = db:autoMigrate(User, Post)
if not result.success then
    for _, err in ipairs(result.errors) do
        print("[Migration Error] " .. err.model .. ": " .. err.error)
    end
end

-- Continue with application
```

## Custom Migrations

For changes that auto-migrate can't handle (renaming columns, adding indexes with custom names, data migrations), use custom migrations.

### db:migrate(name, up, down)

```lua
db:migrate("add_fulltext_index_to_posts", function(db)
    db:execute("CREATE INDEX idx_posts_title ON posts(title)")
end, function(db)
    db:execute("DROP INDEX idx_posts_title")
end)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | string | Unique migration identifier |
| `up` | function | Migration function (receives db) |
| `down` | function (optional) | Rollback function (receives db) |

Each migration runs only once. Freight tracks which migrations have been applied in a `_freight_migrations` table.

### Examples

#### Add a column

```lua
db:migrate("add_bio_to_users", function(db)
    db:execute("ALTER TABLE users ADD COLUMN bio TEXT")
end, function(db)
    -- SQLite doesn't support DROP COLUMN easily
    -- For MySQL: db:execute("ALTER TABLE users DROP COLUMN bio")
end)
```

#### Create a custom index

```lua
db:migrate("create_users_email_index", function(db)
    db:execute("CREATE UNIQUE INDEX idx_users_email ON users(email)")
end, function(db)
    db:execute("DROP INDEX idx_users_email")
end)
```

#### Data migration

```lua
db:migrate("set_default_role", function(db)
    db:execute("UPDATE users SET role = 'user' WHERE role IS NULL")
end)
```

#### Rename a table

```lua
db:migrate("rename_posts_to_articles", function(db)
    db:execute("ALTER TABLE posts RENAME TO articles")
end, function(db)
    db:execute("ALTER TABLE articles RENAME TO posts")
end)
```

## Migration Status

Check which migrations have been applied:

```lua
local status = db:migrationStatus()

print("Current batch: " .. status.current_batch)
print("Total migrations: " .. status.total_migrations)

for _, m in ipairs(status.migrations) do
    print(m.name .. " (batch " .. m.batch .. ", " .. m.executed_at .. ")")
end
```

## Rollback

Roll back the most recent batch of migrations:

```lua
local migrations = {
    add_bio_to_users = {
        up = function(db) db:execute("ALTER TABLE users ADD COLUMN bio TEXT") end,
        down = function(db) print("Cannot drop column in SQLite") end,
    },
}

local ok, err = db:rollbackMigrations(migrations)
if not ok then
    print("Rollback failed: " .. err)
end
```

Rollback executes the `down` function of each migration in the last batch, in reverse order.

## Reset

Drop all tables and clear migration history:

```lua
local ok, err = db:reset(true)   -- Must pass true to confirm
```

This is destructive and should only be used in development.

## Drop Tables

Drop specific model tables:

```lua
db:dropTables(User, Post, Comment)
```

## Migration Workflow

### Development

During development, `autoMigrate()` is the simplest approach. Define your models and let Freight handle the schema:

```lua
-- models.lua
local User = db:model("users", {
    id = freight.primaryKey(),
    name = freight.string(100),
    email = freight.string(255, { unique = true }),
})

-- Later, add a new field to the model:
local User = db:model("users", {
    id = freight.primaryKey(),
    name = freight.string(100),
    email = freight.string(255, { unique = true }),
    role = freight.string(20, { default = "user" }),    -- New field
})

-- autoMigrate will add the 'role' column automatically
db:autoMigrate(User)
```

### Production

For production, combine auto-migrate with custom migrations for precise control:

```lua
-- 1. Auto-migrate creates tables and adds new columns
db:autoMigrate(User, Post, Comment)

-- 2. Custom migrations handle everything else
db:migrate("create_search_index", function(db)
    db:execute("CREATE INDEX idx_posts_search ON posts(title, content)")
end)

db:migrate("populate_slugs", function(db)
    local posts = db:query("SELECT id, title FROM posts WHERE slug IS NULL")
    for _, post in ipairs(posts) do
        local slug = post.title:lower():gsub("%s+", "-"):gsub("[^%w-]", "")
        db:execute("UPDATE posts SET slug = ? WHERE id = ?", slug, post.id)
    end
end)
```

## Table Utilities

Inspect the database schema:

```lua
-- Check if a table exists
if db:tableExists("users") then
    print("Users table exists")
end

-- List all tables
local tables = db:tables()
for _, name in ipairs(tables) do
    print(name)
end

-- Get column information
local columns = db:tableInfo("users")
for _, col in ipairs(columns) do
    print(col.name, col.type)
end

-- Get index information
local indexes = db:indexList("users")
```
