# Query Builder

Freight's query builder provides a chainable API for constructing database queries. All query methods return the query object, allowing you to chain calls fluently.

## Starting a Query

Every model method that accepts conditions returns a query:

```lua
User:where("age > ?", 18)
User:select("id", "name")
User:orderBy("name")
User:limit(10)
```

## WHERE Conditions

### Table syntax

Pass a table of key-value pairs for equality checks:

```lua
User:where({ name = "Alice" }):first()
User:where({ role = "admin", is_active = true }):all()
```

### String syntax

Pass a SQL condition with `?` placeholders:

```lua
User:where("age > ?", 18):all()
User:where("name LIKE ?", "%alice%"):all()
User:where("age BETWEEN ? AND ?", 18, 65):all()
User:where("created_at > ?", "2025-01-01"):all()
```

### orWhere

Add an OR condition:

```lua
User:where({ role = "admin" }):orWhere({ role = "moderator" }):all()
User:where("age < ?", 18):orWhere("age > ?", 65):all()
```

### whereIn / whereNotIn

Match against a list of values:

```lua
User:whereIn("id", {1, 2, 3, 4, 5}):all()
User:whereNotIn("status", {"banned", "suspended"}):all()
```

### whereNull / whereNotNull

Check for NULL values:

```lua
User:whereNull("deleted_at"):all()
User:whereNotNull("email"):all()
```

### whereBetween

Range check:

```lua
User:whereBetween("age", 18, 65):all()
```

### whereLike

Pattern matching:

```lua
User:whereLike("name", "%alice%"):all()
```

## SELECT

Choose which columns to return:

```lua
User:select("id", "name", "email"):all()
```

### distinct

Return unique rows only:

```lua
User:select("role"):distinct():all()
```

## ORDER BY

```lua
User:orderBy("name"):all()                     -- ASC (default)
User:orderBy("name", "ASC"):all()
User:orderBy("created_at", "DESC"):all()
User:orderByDesc("created_at"):all()
```

Chain multiple order clauses:

```lua
User:orderBy("role"):orderBy("name"):all()
```

## LIMIT and OFFSET

```lua
User:limit(10):all()                   -- First 10 records
User:limit(10):offset(20):all()        -- Records 21-30
```

### Pagination

Paginate with 1-based page numbers:

```lua
User:paginate(1, 25):all()   -- Page 1, 25 per page
User:paginate(3, 25):all()   -- Page 3, 25 per page
```

## GROUP BY and HAVING

```lua
-- Count users per role
User:select("role"):groupBy("role"):all()

-- Only roles with more than 5 users
User:select("role")
    :groupBy("role")
    :having("COUNT(*) > ?", 5)
    :all()
```

## JOINs

```lua
-- INNER JOIN
User:join("posts", "users.id = posts.user_id"):all()

-- LEFT JOIN
User:leftJoin("posts", "users.id = posts.user_id"):all()

-- RIGHT JOIN
User:rightJoin("posts", "users.id = posts.user_id"):all()
```

With select to avoid column conflicts:

```lua
User:select("users.*", "posts.title as post_title")
    :leftJoin("posts", "users.id = posts.user_id")
    :all()
```

## Executing Queries

### all() / findAll() / get()

Execute the query and return all matching records:

```lua
local users = User:where("age > ?", 18):all()
```

### first()

Return the first matching record, or `nil`:

```lua
local user = User:where({ email = "alice@example.com" }):first()
```

### firstOrFail()

Return the first matching record, or throw an error:

```lua
local user = User:where({ email = "alice@example.com" }):firstOrFail()
```

### exists()

Check if any matching records exist:

```lua
if User:where({ email = "alice@example.com" }):exists() then
    print("Email already taken")
end
```

## Aggregates

### count(column?)

```lua
local total = User:count()
local active = User:where({ is_active = true }):count()
```

### sum(column)

```lua
local totalAge = User:sum("age")
```

### avg(column)

```lua
local averageAge = User:avg("age")
```

### min(column)

```lua
local youngest = User:min("age")
```

### max(column)

```lua
local oldest = User:max("age")
```

## Bulk Update

Update all matching records:

```lua
-- Deactivate all users who haven't logged in for 90 days
User:where("last_login < ?", cutoffDate):update({
    is_active = false
})

-- Returns: number of affected rows
```

## Bulk Delete

Delete all matching records:

```lua
-- Delete old logs
Log:where("created_at < ?", cutoffDate):delete()

-- Returns: number of affected rows
```

## Eager Loading

Load related records in a single query to avoid N+1 problems:

```lua
-- Load users with their posts
local users = User:include("posts"):all()

-- Load with multiple relations
local users = User:include("posts", "comments"):all()

-- Alternative syntax
local users = User:with("posts"):all()
```

See [Relationships](/docs/freight/relationships) for details on defining relations.

## Debugging

### toSql()

Get the generated SQL and parameters without executing:

```lua
local sql, params = User:where("age > ?", 18)
    :orderBy("name")
    :limit(10)
    :toSql()

print(sql)      -- "SELECT * FROM users WHERE age > ? ORDER BY name ASC LIMIT 10"
print(params)   -- {18}
```

## Complete Examples

### Paginated list with filters

```lua
local function getUsers(page, role, search)
    local query = User:where({ is_active = true })

    if role then
        query = query:where({ role = role })
    end

    if search then
        query = query:whereLike("name", "%" .. search .. "%")
    end

    return query:orderBy("name"):paginate(page, 25):all()
end
```

### Dashboard statistics

```lua
local stats = {
    totalUsers = User:count(),
    activeUsers = User:where({ is_active = true }):count(),
    averageAge = User:avg("age"),
    newestUser = User:orderByDesc("created_at"):first(),
    postsByStatus = {},
}

for _, status in ipairs({"draft", "published", "archived"}) do
    stats.postsByStatus[status] = Post:where({ status = status }):count()
end
```

### Complex query with joins

```lua
local popularAuthors = User
    :select("users.id", "users.name")
    :join("posts", "users.id = posts.user_id")
    :where("posts.status = ?", "published")
    :groupBy("users.id")
    :having("COUNT(posts.id) > ?", 10)
    :orderByDesc("COUNT(posts.id)")
    :limit(10)
    :all()
```
