# Project Structure

This page explains how a CopperMoon project is organized, using **CopperBlog** (a full-stack blog application) as a concrete example.

## Overview

A typical CopperMoon project follows this structure:

```
my-project/
├── Shipyard.toml         # Server & build configuration
├── harbor.toml           # Package dependencies
├── app.lua               # Application entry point
├── .env                  # Environment variables
├── models/               # Database models (Freight ORM)
│   └── init.lua
├── views/                # Templates (Vein)
│   ├── layouts/
│   │   └── base.vein
│   └── pages/
│       ├── home.vein
│       └── ...
├── public/               # Static assets
│   ├── css/
│   ├── js/
│   └── images/
├── data/                 # Database files (SQLite)
├── tests/                # Test files (Assay)
│   └── init.lua
└── seed.lua              # Database seeding script
```

Each file and directory has a specific role. Let's go through them.

## Configuration Files

### Shipyard.toml

`Shipyard.toml` is the main project configuration file. It tells CopperMoon how to run your application.

```toml
name = "copper-blog"
version = "0.1.0"
description = ""

[server]
port = 3000
workers = 16
host = "127.0.0.1"

[lua]
version = "5.4"
entry = "app.lua"

[scripts]
test = "coppermoon tests/init.lua"
```

Key sections:

- **Root** - Project name, version, description
- **[server]** - HTTP server settings: port, number of worker threads, bind address
- **[lua]** - Lua runtime version and the entry point file
- **[scripts]** - Custom scripts you can run with `shipyard script <name>`

### harbor.toml

`harbor.toml` declares your package dependencies. Harbor (the package manager) reads this file to install the modules your project needs.

```toml
[package]
name = "copper-blog"
version = "0.1.0"
description = "Demo blog application showcasing CopperMoon ecosystem"
author = "CopperMoon Team"
license = "MIT"
main = "app.lua"

[dependencies.honeymoon]
path = "../../packages/honeymoon"

[dependencies.vein]
path = "../../packages/vein"

[dependencies.freight]
path = "../../packages/freight"

[dependencies.lantern]
path = "../../packages/lantern"

[dependencies.dotenv]
path = "../../packages/dotenv"

[dependencies.tailwind]
path = "../../packages/tailwind"

[scripts]
start = "coppermoon app.lua"
dev = "coppermoon --watch app.lua"
seed = "coppermoon seed.lua"
```

CopperBlog depends on six packages:

| Package | Role |
|---------|------|
| **honeymoon** | Web framework (routing, middleware, request/response) |
| **vein** | Templating engine |
| **freight** | ORM for database access |
| **lantern** | Debug toolbar for development |
| **dotenv** | Environment variable loading |
| **tailwind** | Tailwind CSS integration |

### .env

The `.env` file stores environment-specific configuration. It is loaded at startup by the Dotenv package and keeps secrets out of your code.

```bash
# Application
APP_NAME="Copper Blog"
APP_ENV=development
APP_DEBUG=true
APP_URL=http://localhost:3000

# Server
PORT=3005
HOST=localhost

# Database
DATABASE_PATH=./data/blog.db

# Session
SESSION_SECRET=dev-secret-key-change-in-production
SESSION_NAME=copper_session
SESSION_MAX_AGE=86400

# Blog Settings
POSTS_PER_PAGE=10
ALLOW_COMMENTS=true
```

> Never commit `.env` files containing real secrets to version control. Use `.env.example` as a template for other developers.

## Entry Point: app.lua

`app.lua` is where your application starts. It initializes the framework, configures middleware, defines routes, and starts the HTTP server.

A typical `app.lua` follows this pattern:

```lua
local honeymoon = require("honeymoon")
local vein = require("vein")
local dotenv = require("dotenv")

-- Load environment variables
dotenv.load()

local app = honeymoon.new()

-- 1. Configuration
app:set("env", os_ext.env("APP_ENV") or "development")
app.views:use("vein")
app.views:set("views", "./views")

-- 2. Middleware
app:use(honeymoon.logger())
app:use(honeymoon.responseTime())
app:use(honeymoon.helmet())
app:use(honeymoon.cors())
app:use("/public", honeymoon.static("./public"))

-- 3. Database setup
local models = require("models")
models.init()
models.migrate()

-- 4. Routes
app:get("/", function(req, res)
    local posts = models.Post:published():all()
    res:render("pages/home", {
        title = "Home",
        posts = posts,
    })
end)

app:get("/post/:slug", function(req, res)
    local post = models.Post:findBySlug(req.params.slug)
    if not post then
        return res:status(404):render("pages/404")
    end
    res:render("pages/post", {
        title = post.title,
        post = post,
    })
end)

-- 5. Error handling
app:error(function(err, req, res, stack)
    print("[Error]", tostring(err))
end)

-- 6. Start server
local port = tonumber(os_ext.env("PORT")) or 3000
app:listen(port)
```

The order matters: configure first, add middleware, set up your database, define routes, then start listening.

## Models Directory

The `models/` directory contains your database models defined with Freight ORM. By convention, `models/init.lua` exports all models and handles database initialization.

```
models/
└── init.lua        # Model definitions & database setup
```

A model defines a database table, its columns, relationships, and custom query methods:

```lua
local freight = require("freight")

local models = {}

function models.init(dbPath)
    local db = freight.open("sqlite", {
        database = dbPath or "./data/blog.db"
    })

    models.db = db

    -- Define models
    models.User = db:model("users", {
        id = { type = "integer", primaryKey = true, autoIncrement = true },
        username = { type = "string", size = 50, unique = true, notNull = true },
        email = { type = "string", size = 255, unique = true, notNull = true },
        display_name = { type = "string", size = 100 },
        created_at = { type = "datetime", default = "CURRENT_TIMESTAMP" },
    })

    models.Post = db:model("posts", {
        id = { type = "integer", primaryKey = true, autoIncrement = true },
        user_id = { type = "integer", notNull = true, references = "users.id" },
        title = { type = "string", size = 255, notNull = true },
        slug = { type = "string", size = 255, unique = true },
        content = { type = "text", notNull = true },
        status = { type = "string", size = 20, default = "draft" },
        published_at = { type = "datetime" },
    })

    -- Relationships
    models.User:hasMany(models.Post, { foreignKey = "user_id", as = "posts" })
    models.Post:belongsTo(models.User, { foreignKey = "user_id", as = "author" })

    return db
end

function models.migrate()
    models.db:autoMigrate(models.User, models.Post)
end

return models
```

CopperBlog defines five models with relationships:

- **User** hasMany **Post**
- **Post** belongsTo **User**, hasMany **Comment**, belongsToMany **Tag**
- **Comment** belongsTo **Post**, belongsTo **User**
- **Tag** belongsToMany **Post** (through PostTag junction table)

Freight automatically creates and updates tables when you call `db:autoMigrate()`.

## Views Directory

The `views/` directory contains your Vein templates. The conventional structure separates layouts from page templates:

```
views/
├── layouts/
│   └── base.vein       # Master layout (HTML shell)
└── pages/
    ├── home.vein       # Home page
    ├── blog.vein       # Blog listing
    ├── post.vein       # Single post
    ├── about.vein      # About page
    ├── 404.vein        # Not found
    └── error.vein      # Error page
```

### Layouts

A layout defines the common HTML structure shared by all pages. Pages extend the layout and fill in content blocks.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>{{ title }} - {{ site.name }}</title>
</head>
<body>
    <nav>
        <a href="/">Home</a>
        <a href="/blog">Blog</a>
        <a href="/about">About</a>
    </nav>

    <main>
        {! content !}
    </main>

    <footer>&copy; 2025 {{ site.name }}</footer>
</body>
</html>
```

### Pages

A page template extends a layout and defines the content for each block:

```html
{% extends "layouts/base" %}

{! content !}
    <h1>{{ post.title }}</h1>
    <p>By {{ post.author.display_name }} on {{ post.published_at | date }}</p>

    <article>
        {{ post.content }}
    </article>

    {% if post.tags %}
        <div>
        {% for tag in post.tags %}
            <a href="/tag/{{ tag.slug }}">{{ tag.name }}</a>
        {% end %}
        </div>
    {% end %}
{! end !}
```

### Vein Syntax Summary

| Syntax | Purpose | Example |
|--------|---------|---------|
| `{{ expr }}` | Output a value (escaped) | `{{ user.name }}` |
| `{% ... %}` | Control flow (if, for, extends) | `{% if logged_in %}` |
| `{! name !}` | Define/fill content blocks | `{! content !}` |
| `{# comment #}` | Template comments (not rendered) | `{# TODO #}` |

## Public Directory

The `public/` directory contains static assets served directly by the HTTP server. Files here are accessible at the `/public` URL path.

```
public/
├── css/
│   └── style.css
├── js/
│   └── app.js
└── images/
    └── logo.png
```

Serve them with the static middleware:

```lua
app:use("/public", honeymoon.static("./public"))
```

In templates, reference them as:

```html
<link rel="stylesheet" href="/public/css/style.css">
<script src="/public/js/app.js"></script>
```

## Tests Directory

The `tests/` directory contains your test files using the Assay testing framework:

```
tests/
├── init.lua            # Test runner entry point
├── models_test.lua     # Model tests
└── routes_test.lua     # Route tests
```

The `tests/init.lua` file loads and runs all test files:

```lua
local Assay = require("assay")

Assay.configure({
    bail = false,
    verbose = true,
    colors = true,
})

-- Load test files
require("tests.models_test")
require("tests.routes_test")

-- Run and return results
return Assay.run()
```

Run tests with:

```bash
shipyard script test
```

## Data Directory

The `data/` directory stores SQLite database files. It is created automatically when Freight opens a database for the first time.

```
data/
└── blog.db     # SQLite database
```

This directory should typically be added to `.gitignore`.

## Seed Script

`seed.lua` is an optional script that populates your database with initial or sample data. This is useful for development and testing.

```lua
local models = require("models")
local dotenv = require("dotenv")

dotenv.load()
models.init()
models.migrate()

-- Create sample data
local admin = models.User:create({
    username = "admin",
    email = "admin@example.com",
    display_name = "Admin",
})

models.Post:create({
    user_id = admin.id,
    title = "First Post",
    slug = "first-post",
    content = "Welcome to the blog!",
    status = "published",
    published_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
})

print("Seed data created!")
```

Run it with:

```bash
shipyard script seed
```

## Putting It All Together

Here is the complete CopperBlog project structure for reference:

```
copper-blog/
├── Shipyard.toml         # Port 3000, 16 workers, entry: app.lua
├── harbor.toml           # Depends on honeymoon, vein, freight, lantern, dotenv, tailwind
├── .env                  # APP_ENV, PORT, DATABASE_PATH, SESSION_SECRET, etc.
├── app.lua               # Routes, middleware, Vein config, server startup
├── seed.lua              # Sample data creation script
├── models/
│   └── init.lua          # User, Post, Comment, Tag, PostTag models + relationships
├── views/
│   ├── layouts/
│   │   └── base.vein     # Master HTML layout with navigation
│   └── pages/
│       ├── home.vein     # Home page with recent posts
│       ├── blog.vein     # Paginated post listing
│       ├── post.vein     # Single post with comments
│       ├── tag.vein      # Posts filtered by tag
│       ├── about.vein    # Static about page
│       ├── 404.vein      # Not found page
│       └── error.vein    # Error page
├── public/               # Static CSS, JS, images
├── data/
│   └── blog.db           # SQLite database (auto-created)
└── tests/
    └── init.lua          # Test runner
```

The flow of a request through a CopperMoon application:

1. **CopperMoon** receives the HTTP request and passes it to HoneyMoon
2. **Middleware** runs in order (logger, security headers, CORS, static files)
3. **Router** matches the URL to a route handler
4. **Route handler** uses **models** to query/mutate data via Freight
5. **`res:render()`** compiles a **Vein** template with the data
6. The rendered HTML is sent back to the client

## Next Steps

- [HoneyMoon Framework](/docs/honeymoon/overview) - Learn routing, middleware, and the request/response API
- [Vein Templating](/docs/vein/overview) - Template syntax, filters, layouts, and components
- [Shipyard CLI](/docs/shipyard/overview) - All available commands and configuration
