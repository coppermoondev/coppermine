# Project Templates

Shipyard provides three project templates to get you started quickly. Use the `--template` (or `-t`) flag with `shipyard new` or `shipyard init`.

## minimal (default)

The default template. A bare Lua application with no dependencies.

```bash
shipyard new my-app
shipyard new my-app --template minimal
```

### Generated structure

```
my-app/
├── Shipyard.toml
├── .gitignore
├── harbor_modules/
└── app.lua
```

### app.lua

```lua
-- CopperMoon Application

print("Hello from CopperMoon!")
print("Version:", _COPPERMOON_VERSION)
```

### When to use

- Learning CopperMoon
- Simple scripts and utilities
- Building from scratch with full control

## web

A full web application using HoneyMoon framework and Vein templating. Both packages are pre-installed in `harbor_modules/`.

```bash
shipyard new my-site --template web
shipyard new my-site -t web
```

### Generated structure

```
my-site/
├── Shipyard.toml
├── .gitignore
├── harbor_modules/
│   ├── honeymoon/          # Web framework
│   │   ├── init.lua
│   │   └── lib/
│   │       ├── application.lua
│   │       ├── router.lua
│   │       ├── request.lua
│   │       ├── response.lua
│   │       ├── schema.lua
│   │       ├── errors.lua
│   │       ├── utils.lua
│   │       ├── session.lua
│   │       ├── view.lua
│   │       └── middleware/
│   │           ├── init.lua
│   │           ├── logger.lua
│   │           ├── cors.lua
│   │           ├── bodyparser.lua
│   │           ├── static.lua
│   │           ├── ratelimit.lua
│   │           ├── auth.lua
│   │           └── session.lua
│   └── vein/               # Template engine
│       ├── init.lua
│       └── lib/
│           ├── compiler.lua
│           ├── filters.lua
│           ├── loader.lua
│           ├── cache.lua
│           └── runtime.lua
└── app.lua
```

### app.lua

The generated `app.lua` includes:

- HoneyMoon application setup
- Logger and CORS middleware
- Three sample routes:
  - `GET /` - HTML page with styled layout
  - `GET /api/status` - JSON status endpoint
  - `GET /api/hello` - Greeting endpoint with query parameter support
- Server listening on port 3000

### When to use

- Web applications with HTML pages
- Sites that need templating, routing, and middleware
- Full-stack projects with views, forms, and sessions

## api

A REST API server using CopperMoon's built-in HTTP server. No external dependencies.

```bash
shipyard new my-api --template api
shipyard new my-api -t api
```

### Generated structure

```
my-api/
├── Shipyard.toml
├── .gitignore
├── harbor_modules/
└── app.lua
```

### app.lua

The generated `app.lua` includes:

- HTTP server setup with `http.server`
- Request logging with timestamps
- JSON body parsing with error handling
- Sample routes:
  - `GET /health` - Health check endpoint
  - `GET /api/v1/info` - API information
  - `GET /api/v1/users` - List users (sample data)
  - `POST /api/v1/users` - Create user (with body parsing)
- 404 handler for unknown routes
- Status codes (200, 201, 400, 404)

### When to use

- REST APIs and microservices
- JSON-only backends
- Lightweight services without templating

## Generated .gitignore

All templates include a `.gitignore` with:

```
# Dependencies
harbor_modules/

# Build output
dist/
build/

# Logs
*.log

# Environment
.env
.env.local

# IDE
.idea/
.vscode/
*.swp

# OS
.DS_Store
Thumbs.db
```

## Generated Shipyard.toml

All templates generate a `Shipyard.toml` with the project name and defaults:

```toml
name = "my-app"
version = "0.1.0"
description = ""

[server]
port = 3000
workers = 16
host = "127.0.0.1"

[lua]
version = "5.4"
entry = "app.lua"

[dependencies]

[scripts]
test = "coppermoon tests/init.lua"
```

## After Creating a Project

1. Enter the project directory:
   ```bash
   cd my-app
   ```

2. Start the development server:
   ```bash
   shipyard dev
   ```

3. Open `http://localhost:3000` in your browser.

4. Edit `app.lua` and save — the server restarts automatically.

5. Install additional packages with Harbor:
   ```bash
   harbor install freight
   harbor install dotenv
   ```
