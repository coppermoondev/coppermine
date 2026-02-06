# Freight ORM

Freight is the Object-Relational Mapping library for CopperMoon. It provides a clean, chainable API for database operations with support for SQLite, MySQL/MariaDB, and PostgreSQL.

## Features

- **Model definitions** with typed columns and constraints
- **Query builder** with chainable methods
- **Relationships** - hasOne, hasMany, belongsTo, belongsToMany
- **Auto-migrations** - create and update tables automatically
- **Hooks** - beforeCreate, afterUpdate, etc.
- **Transactions** - with automatic commit/rollback
- **Eager loading** - load related records efficiently
- **Field helpers** - `freight.string()`, `freight.integer()`, etc.

## Quick Start

```lua
local freight = require("freight")

-- Connect to SQLite database
local db = freight.open("sqlite", {
    database = "./data/app.db"
})

-- Define a model
local User = db:model("users", {
    id = { type = "integer", primaryKey = true, autoIncrement = true },
    name = { type = "string", size = 100, notNull = true },
    email = { type = "string", size = 255, unique = true },
    age = { type = "integer" },
    created_at = { type = "datetime", default = "CURRENT_TIMESTAMP" },
})

-- Create tables
db:autoMigrate(User)

-- Create a record
local user = User:create({
    name = "Alice",
    email = "alice@example.com",
    age = 30,
})

-- Query records
local users = User:where("age > ?", 18):orderBy("name"):all()

-- Find by ID
local user = User:find(1)

-- Update
user.name = "Bob"
user:save()

-- Delete
user:deleteInstance()

-- Close connection
db:close()
```

## Connecting to a Database

### SQLite

```lua
local db = freight.open("sqlite", {
    database = "./data/app.db"
})

-- In-memory database
local db = freight.open("sqlite", {
    database = ":memory:"
})
```

### MySQL / MariaDB

```lua
local db = freight.open("mysql", {
    host = "localhost",
    port = 3306,
    user = "root",
    password = "password",
    database = "myapp",
})
```

### PostgreSQL

```lua
local db = freight.open("postgres", {
    host = "localhost",
    port = 5432,
    user = "postgres",
    password = "password",
    database = "myapp",
})
```

## Field Type Helpers

Freight provides helper functions for common field definitions:

```lua
local User = db:model("users", {
    id = freight.primaryKey(),
    name = freight.string(100, { notNull = true }),
    email = freight.string(255, { unique = true }),
    bio = freight.text(),
    age = freight.integer(),
    score = freight.float(),
    is_active = freight.boolean({ default = 1 }),
    avatar = freight.blob(),
    settings = freight.json(),
    birthday = freight.date(),
    created_at = freight.datetime({ default = "CURRENT_TIMESTAMP" }),
    user_id = freight.foreignKey("users"),
})
```

| Helper | Type | Default size |
|--------|------|-------------|
| `freight.primaryKey()` | integer, PK, autoIncrement | - |
| `freight.string(size?, opts?)` | string | 255 |
| `freight.text(opts?)` | text | - |
| `freight.integer(opts?)` | integer | - |
| `freight.float(opts?)` | float | - |
| `freight.boolean(opts?)` | boolean (stored as INT) | - |
| `freight.datetime(opts?)` | datetime | - |
| `freight.date(opts?)` | date | - |
| `freight.blob(opts?)` | blob | - |
| `freight.json(opts?)` | json (stored as TEXT) | - |
| `freight.foreignKey(table, col?, opts?)` | integer with references | - |

## Raw Queries

Execute raw SQL when the ORM doesn't cover your use case:

```lua
-- Execute (INSERT, UPDATE, DELETE) - returns affected rows
local affected = db:execute("UPDATE users SET active = ? WHERE age < ?", true, 18)

-- Query (SELECT) - returns array of rows
local rows = db:query("SELECT * FROM users WHERE age > ?", 18)

-- Query single row
local row = db:query_row("SELECT COUNT(*) as total FROM users")
print(row.total)

-- Last inserted ID
local id = db:last_insert_id()

-- Rows changed by last statement
local n = db:changes()
```

## Transactions

```lua
-- Automatic transaction
db:transaction(function()
    local user = User:create({ name = "Alice", email = "alice@example.com" })
    Post:create({ user_id = user.id, title = "First Post" })
    -- Commits automatically. Rolls back if any error occurs.
end)

-- Manual transaction
db:begin()
local ok, err = pcall(function()
    User:create({ name = "Bob" })
    Post:create({ user_id = 999 })  -- might fail
end)
if ok then
    db:commit()
else
    db:rollback()
    print("Error:", err)
end
```

## Table Utilities

```lua
db:tableExists("users")     -- true/false
db:tables()                 -- {"users", "posts", "comments"}
db:tableInfo("users")       -- column definitions
db:ping()                   -- check connection
db:close()                  -- close connection
```

## Next Steps

- [Models](/docs/freight/models) - Define models, field types, hooks, CRUD operations
- [Query Builder](/docs/freight/queries) - Build complex queries with chainable methods
- [Relationships](/docs/freight/relationships) - hasMany, belongsTo, and more
- [Migrations](/docs/freight/migrations) - Auto-migrate and custom migrations
