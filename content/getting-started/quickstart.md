# Quick Start

Build your first CopperMoon web application in minutes. This guide walks you through creating a simple web server with routing, templating, and static files.

## Prerequisites

Make sure you have CopperMoon installed. See the [Installation](/docs/getting-started/installation) guide if needed.

```bash
coppermoon --version
shipyard --version
```

## Create a New Project

Use Shipyard to scaffold a new project:

```bash
shipyard new my-app
cd my-app
```

This creates a project with the following files:

```
my-app/
├── Shipyard.toml     # Project configuration
├── harbor.toml       # Package dependencies
├── app.lua           # Application entry point
├── views/            # Template files
│   └── layouts/
│       └── base.vein
├── public/           # Static assets (CSS, JS, images)
└── .env              # Environment variables
```

## Install Dependencies

Fetch the packages declared in `harbor.toml`:

```bash
harbor install
```

## Your First App

Open `app.lua` and replace the contents:

```lua
local honeymoon = require("honeymoon")
local app = honeymoon.new()

-- A simple route
app:get("/", function(req, res)
    res:send("Hello from CopperMoon!")
end)

-- JSON API endpoint
app:get("/api/greet/:name", function(req, res)
    res:json({
        message = "Hello, " .. req.params.name .. "!",
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    })
end)

app:listen(3000)
```

## Run the Server

Start the development server with Shipyard:

```bash
shipyard dev
```

Or run the app directly:

```bash
coppermoon app.lua
```

Visit `http://localhost:3000` in your browser. Try `http://localhost:3000/api/greet/World` to see the JSON response.

## Add Templating

CopperMoon uses **Vein** as its templating engine. Create a layout and a page template.

### Layout Template

Create `views/layouts/base.vein`:

```html
<!DOCTYPE html>
<html>
<head>
    <title>{{ title }}</title>
</head>
<body>
    <header>
        <h1>My App</h1>
        <nav>
            <a href="/">Home</a>
            <a href="/about">About</a>
        </nav>
    </header>

    <main>
        {! content !}
    </main>

    <footer>
        <p>Built with CopperMoon</p>
    </footer>
</body>
</html>
```

### Page Template

Create `views/pages/home.vein`:

```html
{% extends "layouts/base" %}

{! content !}
    <h2>Welcome</h2>
    <p>Hello, {{ name }}!</p>

    {% if items %}
        <ul>
        {% for item in items %}
            <li>{{ item }}</li>
        {% end %}
        </ul>
    {% end %}
{! end !}
```

### Configure Vein in Your App

Update `app.lua` to use Vein:

```lua
local honeymoon = require("honeymoon")
local vein = require("vein")

local app = honeymoon.new()

-- Setup Vein templating
app.views:use("vein")
app.views:set("views", "./views")

-- Home page with template
app:get("/", function(req, res)
    res:render("pages/home", {
        title = "Home",
        name = "CopperMoon",
        items = { "Fast", "Simple", "Powerful" }
    })
end)

app:listen(3000)
```

## Add Middleware

HoneyMoon provides built-in middleware for common needs:

```lua
-- Logging
app:use(honeymoon.logger())

-- Response time header
app:use(honeymoon.responseTime())

-- Security headers
app:use(honeymoon.helmet())

-- CORS
app:use(honeymoon.cors())

-- Serve static files from /public
app:use("/public", honeymoon.static("./public"))
```

## Add a Database

Use **Freight** ORM to work with SQLite databases:

```lua
local freight = require("freight")

-- Open a database
local db = freight.open("sqlite", {
    database = "./data/app.db"
})

-- Define a model
local User = db:model("users", {
    id = { type = "integer", primaryKey = true, autoIncrement = true },
    name = { type = "string", size = 100, notNull = true },
    email = { type = "string", size = 255, unique = true },
    created_at = { type = "datetime", default = "CURRENT_TIMESTAMP" },
})

-- Auto-create the table
db:autoMigrate(User)

-- Use in routes
app:get("/users", function(req, res)
    local users = User:all()
    res:json(users)
end)

app:post("/users", function(req, res)
    local user = User:create({
        name = req.body.name,
        email = req.body.email,
    })
    res:status(201):json(user)
end)
```

## Environment Variables

Use **Dotenv** to manage configuration. Create a `.env` file:

```bash
APP_NAME="My App"
APP_ENV=development
PORT=3000
DATABASE_PATH=./data/app.db
SESSION_SECRET=change-me-in-production
```

Load it in your app:

```lua
local dotenv = require("dotenv")
dotenv.load()

local port = tonumber(dotenv.get("PORT", "3000"))
app:listen(port)
```

## Custom Scripts

Define scripts in `harbor.toml` for common tasks:

```toml
[scripts]
start = "coppermoon app.lua"
dev = "coppermoon --watch app.lua"
seed = "coppermoon seed.lua"
test = "coppermoon tests/init.lua"
```

Run them with:

```bash
shipyard script dev
shipyard script seed
shipyard script test
```

## Error Handling

Add a global error handler:

```lua
app:error(function(err, req, res, stack)
    print("[Error]", tostring(err))

    if app:get_setting("env") ~= "production" then
        res:status(500):json({
            error = tostring(err),
            stack = stack
        })
    else
        res:status(500):send("Internal Server Error")
    end
end)
```

## Next Steps

- [Project Structure](/docs/getting-started/project-structure) - Understand how CopperMoon projects are organized
- [HoneyMoon Framework](/docs/honeymoon/overview) - Deep dive into routing, middleware, and more
- [Vein Templating](/docs/vein/overview) - Master the template engine
- [Freight ORM](/docs/guides/web-app) - Build data-driven applications
