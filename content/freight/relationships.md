# Relationships

Freight supports four types of relationships between models: hasOne, hasMany, belongsTo, and belongsToMany.

## hasMany

A one-to-many relationship. A User has many Posts.

### Definition

```lua
User:hasMany(Post, {
    foreignKey = "user_id",    -- Column in posts table
    as = "posts",              -- Relation name
})
```

| Option | Default | Description |
|--------|---------|-------------|
| `foreignKey` | `{parent_table}_id` | Foreign key column in the child table |
| `localKey` | `"id"` | Primary key in the parent table |
| `as` | child table name | Name used to access the relation |

### Usage

```lua
-- Lazy load (separate query)
local user = User:find(1)
local posts = user:posts()

-- Eager load (single query)
local users = User:include("posts"):all()
for _, user in ipairs(users) do
    local posts = user._loaded_relations.posts
end
```

## belongsTo

The inverse of hasMany. A Post belongs to a User.

### Definition

```lua
Post:belongsTo(User, {
    foreignKey = "user_id",    -- Column in posts table
    as = "author",             -- Relation name
})
```

| Option | Default | Description |
|--------|---------|-------------|
| `foreignKey` | `{parent_table}_id` | Foreign key column in this table |
| `ownerKey` | `"id"` | Primary key in the parent table |
| `as` | parent table name (singular) | Name used to access the relation |

### Usage

```lua
-- Lazy load
local post = Post:find(1)
local author = post:author()
print(author.name)

-- Eager load
local posts = Post:include("author"):all()
```

## hasOne

A one-to-one relationship. A User has one Profile.

### Definition

```lua
User:hasOne(Profile, {
    foreignKey = "user_id",
    as = "profile",
})
```

| Option | Default | Description |
|--------|---------|-------------|
| `foreignKey` | `{parent_table}_id` | Foreign key in the child table |
| `localKey` | `"id"` | Primary key in the parent table |
| `as` | child table name | Relation name |

### Usage

```lua
local user = User:find(1)
local profile = user:profile()
print(profile.avatar_url)
```

## belongsToMany

A many-to-many relationship through a pivot (junction) table. A Post has many Tags, and a Tag has many Posts.

### Pivot Table

Create a junction table to connect the two models:

```lua
local PostTag = db:model("post_tags", {
    id = { type = "integer", primaryKey = true, autoIncrement = true },
    post_id = { type = "integer", notNull = true, references = "posts.id" },
    tag_id = { type = "integer", notNull = true, references = "tags.id" },
})
```

### Definition

Define the relationship on both sides:

```lua
Post:belongsToMany(Tag, {
    through = "post_tags",        -- Pivot table name
    foreignPivotKey = "post_id",  -- This model's key in pivot
    relatedPivotKey = "tag_id",   -- Related model's key in pivot
    as = "tags",
})

Tag:belongsToMany(Post, {
    through = "post_tags",
    foreignPivotKey = "tag_id",
    relatedPivotKey = "post_id",
    as = "posts",
})
```

| Option | Default | Description |
|--------|---------|-------------|
| `through` | Auto-generated | Pivot table name |
| `foreignPivotKey` | `{this_table}_id` | This model's foreign key in pivot |
| `relatedPivotKey` | `{related_table}_id` | Related model's foreign key in pivot |
| `localKey` | `"id"` | Primary key in this model |
| `relatedKey` | `"id"` | Primary key in related model |
| `as` | related table name | Relation name |

### Usage

```lua
-- Get tags for a post
local post = Post:find(1)
local tags = post:tags()

-- Get posts for a tag
local tag = Tag:findBySlug("lua")
local posts = tag:posts()

-- Eager load
local posts = Post:include("tags"):all()
```

### Pivot Table Operations

#### Attach

Link records through the pivot table:

```lua
local relation = Post._relations.tags

-- Attach a single tag
relation:attach(post, tagId)

-- Attach multiple tags
relation:attach(post, {1, 2, 3})
```

#### Detach

Remove links:

```lua
-- Detach specific tags
relation:detach(post, {1, 2})

-- Detach all tags
relation:detach(post)
```

#### Sync

Replace all links with a new set:

```lua
-- Post will have exactly these tags (removes others, adds missing)
relation:sync(post, {1, 3, 5})
```

## Eager Loading

Eager loading prevents the N+1 query problem by loading related records in advance.

### Without eager loading (N+1 problem)

```lua
local users = User:all()
for _, user in ipairs(users) do
    local posts = user:posts()       -- One query per user!
end
```

### With eager loading

```lua
local users = User:include("posts"):all()
for _, user in ipairs(users) do
    local posts = user._loaded_relations.posts   -- Already loaded
end
```

### Multiple relations

```lua
local users = User:include("posts", "profile"):all()
```

### Alternative syntax

`with()` and `preload()` are aliases for `include()`:

```lua
User:with("posts"):all()
User:preload("posts", "comments"):all()
```

## Complete Example

### Model definitions

```lua
local freight = require("freight")
local db = freight.open("sqlite", { database = "./data/blog.db" })

local User = db:model("users", {
    id = freight.primaryKey(),
    name = freight.string(100, { notNull = true }),
    email = freight.string(255, { unique = true }),
})

local Post = db:model("posts", {
    id = freight.primaryKey(),
    user_id = freight.foreignKey("users"),
    title = freight.string(255, { notNull = true }),
    content = freight.text(),
    status = freight.string(20, { default = "draft" }),
})

local Comment = db:model("comments", {
    id = freight.primaryKey(),
    post_id = freight.foreignKey("posts"),
    user_id = freight.foreignKey("users"),
    content = freight.text({ notNull = true }),
})

local Tag = db:model("tags", {
    id = freight.primaryKey(),
    name = freight.string(50, { unique = true }),
    slug = freight.string(50, { unique = true }),
})

local PostTag = db:model("post_tags", {
    id = freight.primaryKey(),
    post_id = freight.foreignKey("posts"),
    tag_id = freight.foreignKey("tags"),
})
```

### Relationship definitions

```lua
-- User has many posts
User:hasMany(Post, { foreignKey = "user_id", as = "posts" })

-- Post belongs to user
Post:belongsTo(User, { foreignKey = "user_id", as = "author" })

-- Post has many comments
Post:hasMany(Comment, { foreignKey = "post_id", as = "comments" })

-- Comment belongs to post
Comment:belongsTo(Post, { foreignKey = "post_id", as = "post" })

-- Comment belongs to user
Comment:belongsTo(User, { foreignKey = "user_id", as = "user" })

-- Post has many tags (through post_tags)
Post:belongsToMany(Tag, {
    through = "post_tags",
    foreignPivotKey = "post_id",
    relatedPivotKey = "tag_id",
    as = "tags",
})

-- Tag has many posts (through post_tags)
Tag:belongsToMany(Post, {
    through = "post_tags",
    foreignPivotKey = "tag_id",
    relatedPivotKey = "post_id",
    as = "posts",
})
```

### Querying with relationships

```lua
-- Get a user's published posts with their tags
local user = User:find(1)
local posts = Post:where({ user_id = user.id, status = "published" })
    :include("tags")
    :orderBy("created_at", "DESC")
    :all()

for _, post in ipairs(posts) do
    print(post.title)
    local tags = post._loaded_relations.tags
    if tags then
        for _, tag in ipairs(tags) do
            print("  Tag: " .. tag.name)
        end
    end
end

-- Get a post with its author and comments
local post = Post:where({ id = 1 })
    :include("author", "comments")
    :first()

print("By: " .. post:author().name)
print("Comments: " .. #post:comments())
```
