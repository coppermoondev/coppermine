# Backend Services

CopperMoon is a complete platform for building backend services: REST APIs, microservices, background workers, and CLI tools. With built-in HTTP, JSON, databases, networking, and a rich standard library, you can ship production services without hunting for dependencies.

## Why CopperMoon for Backend?

- **Fast startup** - Lua scripts load in milliseconds, ideal for serverless and microservice architectures
- **Low memory** - A full HTTP service runs in a few megabytes of RAM
- **Batteries included** - HTTP client/server, JSON, SQLite, MySQL, Redis, crypto, networking out of the box
- **Simple deployment** - Single binary (`coppermoon`) plus your Lua files, no compilation step needed
- **Familiar patterns** - Express-style routing, middleware chains, ORM, structured logging

## What You Can Build

### REST APIs

Build JSON APIs with HoneyMoon's Express-style routing, validation, and middleware:

```lua
local honeymoon = require("honeymoon")
local app = honeymoon.new()

app:use(honeymoon.cors())
app:use(honeymoon.helmet())

app:get("/api/users", function(req, res)
    local users = db:query("SELECT * FROM users")
    res:json({ data = users })
end)

app:listen(3000)
```

### Microservices

Lightweight Lua scripts are a natural fit for microservices. Each service is just a script with its own routes and database:

```lua
-- order-service.lua
local honeymoon = require("honeymoon")
local app = honeymoon.new()

app:post("/orders", function(req, res)
    local order = json.decode(req.body)
    -- process order, call payment service
    local payment = http.post("http://payment-service:3001/charge", json.encode(order))
    res:json({ status = "created", payment = json.decode(payment.body) })
end)

app:listen(3002)
```

### CLI Tools

Build command-line tools with interactive prompts, colored output, and terminal control:

```lua
local name = console.prompt("Project name: ")
local db = console.select("Database:", {"SQLite", "MySQL", "None"})

print(term.bold(term.green("Creating project: ")) .. name)
-- scaffold project files...
print(term.green("Done!"))
```

### Background Workers

Process jobs, poll queues, or run scheduled tasks:

```lua
while true do
    local jobs = redis:lrange("queue:emails", 0, 9)
    for _, raw in ipairs(jobs) do
        local job = json.decode(raw)
        send_email(job.to, job.subject, job.body)
        redis:lpop("queue:emails")
    end
    time.sleep(1000)
end
```

## Architecture Overview

A typical CopperMoon backend project:

```
my-service/
  Shipyard.toml          -- project config
  harbor.toml            -- dependencies
  app.lua                -- entry point
  routes/
    users.lua            -- user routes
    auth.lua             -- auth routes
  models/
    user.lua             -- user model
  middleware/
    auth.lua             -- JWT middleware
  config.lua             -- configuration
```

## The Stack

| Layer | Tool | Purpose |
|-------|------|---------|
| HTTP | HoneyMoon | Routing, middleware, request/response |
| Templates | Vein | HTML rendering (optional for APIs) |
| ORM | Freight | Models, queries, migrations |
| Cache | Redis | Caching, sessions, queues |
| Logging | Ember | Structured logging with transports |
| Testing | Assay | Unit and integration testing |
| CLI | Shipyard | Dev server, project scaffolding |
| Packages | Harbor | Dependency management |

## Next Steps

- [REST APIs](/docs/backend-services/rest-api) - Build a complete CRUD API
- [Middleware Patterns](/docs/backend-services/middleware-patterns) - CORS, auth, rate limiting, logging
- [Database Integration](/docs/backend-services/database) - SQLite, MySQL, and Redis
- [CLI Tools](/docs/backend-services/cli-tools) - Build command-line applications
- [Configuration](/docs/backend-services/configuration) - Environment variables and config management
