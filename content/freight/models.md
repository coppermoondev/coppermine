# Models

A model represents a database table. It defines the table's columns, constraints, and provides methods for creating, reading, updating, and deleting records.

## Defining a Model

Use `db:model(table_name, fields)` to define a model:

```lua
local User = db:model("users", {
    id = { type = "integer", primaryKey = true, autoIncrement = true },
    name = { type = "string", size = 100, notNull = true },
    email = { type = "string", size = 255, unique = true, notNull = true },
    age = { type = "integer" },
    bio = { type = "text" },
    is_active = { type = "boolean", default = 1 },
    created_at = { type = "datetime", default = "CURRENT_TIMESTAMP" },
    updated_at = { type = "datetime" },
})
```

## Field Definition

Each field is a table with a `type` and optional constraints:

```lua
{
    type = "string",            -- Required: column type
    size = 255,                 -- Column size (for string)
    primaryKey = true,          -- PRIMARY KEY
    autoIncrement = true,       -- AUTO INCREMENT (requires primaryKey)
    notNull = true,             -- NOT NULL constraint
    unique = true,              -- UNIQUE constraint
    index = true,               -- Create an index
    default = "value",          -- Default value
    references = "users.id",    -- Foreign key (shorthand)
    comment = "description",    -- Column comment (MySQL only)
}
```

### Column Types

| Type | SQLite | MySQL | Description |
|------|--------|-------|-------------|
| `integer` | INTEGER | INT | Whole numbers |
| `string` | VARCHAR(n) | VARCHAR(n) | Short text (default size: 255) |
| `text` | TEXT | TEXT | Long text |
| `float` | REAL | FLOAT | Decimal numbers |
| `boolean` | INTEGER | TINYINT(1) | True/false (stored as 0/1) |
| `datetime` | TEXT | DATETIME | Date and time |
| `date` | TEXT | DATE | Date only |
| `blob` | BLOB | BLOB | Binary data |
| `json` | TEXT | JSON | JSON data |

### Foreign Key Reference

```lua
-- Shorthand
user_id = { type = "integer", notNull = true, references = "users.id" },

-- Detailed
user_id = {
    type = "integer",
    notNull = true,
    references = {
        table = "users",
        column = "id",
        onDelete = "CASCADE",
        onUpdate = "CASCADE",
    }
},
```

### Using Field Helpers

The helper functions are a shorter way to define fields:

```lua
local Post = db:model("posts", {
    id = freight.primaryKey(),
    user_id = freight.foreignKey("users"),
    title = freight.string(200, { notNull = true }),
    slug = freight.string(200, { unique = true }),
    content = freight.text(),
    views = freight.integer({ default = 0 }),
    published = freight.boolean({ default = 0 }),
    metadata = freight.json(),
    published_at = freight.datetime(),
    created_at = freight.datetime({ default = "CURRENT_TIMESTAMP" }),
})
```

## Creating Records

### create(data)

Create a new record and insert it into the database. Returns the created instance.

```lua
local user = User:create({
    name = "Alice",
    email = "alice@example.com",
    age = 30,
})

print(user.id)      -- Auto-generated ID
print(user.name)    -- "Alice"
```

### firstOrCreate(search, create)

Find a record matching `search` criteria, or create one if not found:

```lua
local user, was_created = User:firstOrCreate(
    { email = "alice@example.com" },          -- Search by this
    { name = "Alice", age = 30 }              -- Use this data if creating
)

if was_created then
    print("New user created")
else
    print("Existing user found")
end
```

### firstOrNew(search, data)

Same as `firstOrCreate` but does not save to the database. Call `save()` to persist:

```lua
local user, is_new = User:firstOrNew(
    { email = "bob@example.com" },
    { name = "Bob" }
)

if is_new then
    user.age = 25
    user:save()
end
```

## Reading Records

### find(id)

Find a record by primary key. Returns the instance or `nil`.

```lua
local user = User:find(1)
if user then
    print(user.name)
end
```

### findOrFail(id)

Find a record by primary key. Throws an error if not found.

```lua
local user = User:findOrFail(1)
```

### all() / findAll()

Get all records from the table.

```lua
local users = User:all()
for _, user in ipairs(users) do
    print(user.name)
end
```

### first()

Get the first record (by primary key order).

```lua
local user = User:first()
```

### last()

Get the last record (by primary key, descending).

```lua
local user = User:last()
```

### count()

Count all records.

```lua
local total = User:count()
print("Total users: " .. total)
```

### where(...)

Query with conditions. See the [Query Builder](/docs/freight/queries) page for the full API.

```lua
local admins = User:where({ role = "admin" }):all()
local adults = User:where("age >= ?", 18):orderBy("name"):all()
```

## Updating Records

### Instance save()

Modify an instance and save it:

```lua
local user = User:find(1)
user.name = "Updated Name"
user.age = 31
user:save()
```

### Bulk update via query

Update multiple records at once:

```lua
User:where("age < ?", 18):update({ is_active = false })
```

## Deleting Records

### Instance delete

```lua
local user = User:find(1)
user:deleteInstance()
```

### Bulk delete via query

```lua
User:where("is_active = ?", false):delete()
```

## Instance Methods

Each record returned by Freight is an instance with these methods:

| Method | Description |
|--------|-------------|
| `instance:save()` | Save changes to the database (create or update) |
| `instance:reload()` | Refresh data from the database |
| `instance:deleteInstance()` | Delete from the database |

Access column values directly as properties:

```lua
local user = User:find(1)
print(user.id)
print(user.name)
print(user.email)
user.name = "New Name"
user:save()
```

## Hooks

Hooks run custom code at specific points in the model lifecycle:

```lua
User:beforeCreate(function(data)
    data.created_at = os.date("!%Y-%m-%dT%H:%M:%SZ")
end)

User:afterCreate(function(instance)
    print("User created: " .. instance.name)
end)

User:beforeUpdate(function(instance)
    instance._data.updated_at = os.date("!%Y-%m-%dT%H:%M:%SZ")
end)

User:afterUpdate(function(instance)
    print("User updated: " .. instance.name)
end)

User:beforeDelete(function(instance)
    print("Deleting user: " .. instance.name)
end)

User:afterDelete(function(instance)
    print("User deleted")
end)

User:beforeSave(function(instance)
    -- Runs before both create and update
end)

User:afterSave(function(instance)
    -- Runs after both create and update
end)
```

| Hook | When | Receives |
|------|------|----------|
| `beforeCreate` | Before INSERT | data table |
| `afterCreate` | After INSERT | instance |
| `beforeUpdate` | Before UPDATE | instance |
| `afterUpdate` | After UPDATE | instance |
| `beforeDelete` | Before DELETE | instance |
| `afterDelete` | After DELETE | instance |
| `beforeSave` | Before INSERT or UPDATE | instance |
| `afterSave` | After INSERT or UPDATE | instance |

### Practical Hook Example

Auto-generate slugs and timestamps:

```lua
local Post = db:model("posts", {
    id = freight.primaryKey(),
    title = freight.string(200, { notNull = true }),
    slug = freight.string(200, { unique = true }),
    content = freight.text(),
    created_at = freight.datetime(),
    updated_at = freight.datetime(),
})

Post:beforeCreate(function(data)
    data.created_at = os.date("!%Y-%m-%dT%H:%M:%SZ")
    if not data.slug and data.title then
        data.slug = data.title:lower()
            :gsub("[^%w%s-]", "")
            :gsub("%s+", "-")
    end
end)

Post:beforeUpdate(function(instance)
    instance._data.updated_at = os.date("!%Y-%m-%dT%H:%M:%SZ")
end)
```

## Custom Model Methods

Add custom query methods to a model:

```lua
function User:active()
    return self:where({ is_active = true })
end

function User:findByEmail(email)
    return self:where({ email = email }):first()
end

function Post:published()
    return self:where({ status = "published" }):orderBy("published_at", "DESC")
end

function Post:findBySlug(slug)
    return self:where({ slug = slug }):first()
end
```

Usage:

```lua
local activeUsers = User:active():orderBy("name"):all()
local user = User:findByEmail("alice@example.com")
local posts = Post:published():limit(10):all()
local post = Post:findBySlug("hello-world")
```
