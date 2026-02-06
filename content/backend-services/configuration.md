# Configuration

Manage application settings, environment variables, secrets, and per-environment configuration for your backend services.

## Environment Variables

Access environment variables with `os_ext.env()`:

```lua
local db_url = os_ext.env("DATABASE_URL") or "sqlite:app.db"
local port = tonumber(os_ext.env("PORT")) or 3000
local secret = os_ext.env("JWT_SECRET")
local env = os_ext.env("APP_ENV") or "development"
```

### Required Variables

Fail fast if critical config is missing:

```lua
local function require_env(key)
    local value = os_ext.env(key)
    if not value or #value == 0 then
        print(term.red("Error: ") .. "missing required environment variable: " .. term.bold(key))
        process.exit(1)
    end
    return value
end

local jwt_secret = require_env("JWT_SECRET")
local db_url = require_env("DATABASE_URL")
```

## Configuration Module

Create a central config module for your application:

```lua
-- config.lua
local env = os_ext.env("APP_ENV") or "development"

local config = {
    env = env,
    is_dev = env == "development",
    is_prod = env == "production",

    -- Server
    port = tonumber(os_ext.env("PORT")) or 3000,
    host = os_ext.env("HOST") or "0.0.0.0",

    -- Database
    database = {
        path = os_ext.env("DATABASE_PATH") or "app.db",
    },

    -- Redis
    redis = {
        host = os_ext.env("REDIS_HOST") or "127.0.0.1",
        port = tonumber(os_ext.env("REDIS_PORT")) or 6379,
        password = os_ext.env("REDIS_PASSWORD"),
    },

    -- Security
    jwt_secret = os_ext.env("JWT_SECRET") or "dev-secret-change-me",
    cookie_secret = os_ext.env("COOKIE_SECRET") or "dev-cookie-secret",

    -- External services
    mail = {
        api_key = os_ext.env("MAIL_API_KEY"),
        from = os_ext.env("MAIL_FROM") or "noreply@example.com",
    },
}

-- Warnings for development defaults
if config.is_prod then
    if config.jwt_secret == "dev-secret-change-me" then
        print(term.red("WARNING: ") .. "Using default JWT secret in production!")
        process.exit(1)
    end
end

return config
```

Use it from anywhere:

```lua
-- app.lua
local config = require("config")

app:listen(config.port, function(port)
    print("Running in " .. term.bold(config.env) .. " on port " .. port)
end)
```

## .env File Loading

Load environment variables from a `.env` file at startup:

```lua
-- env.lua - Simple .env file loader
local function load_env(path)
    path = path or ".env"
    if not fs.exists(path) then
        return
    end

    local content = fs.read(path)
    for _, line in ipairs(string.lines(content)) do
        -- Skip comments and empty lines
        local trimmed = line:trim()
        if #trimmed > 0 and not trimmed:starts_with("#") then
            -- Parse KEY=VALUE
            local key, value = trimmed:match("^([%w_]+)%s*=%s*(.*)")
            if key and value then
                -- Remove surrounding quotes
                if (value:starts_with('"') and value:ends_with('"')) or
                   (value:starts_with("'") and value:ends_with("'")) then
                    value = value:sub(2, -2)
                end
                -- Only set if not already defined (system env takes precedence)
                if not os_ext.env(key) then
                    os_ext.setenv(key, value)
                end
            end
        end
    end
end

return load_env
```

Example `.env` file:

```bash
APP_ENV=development
PORT=3000
DATABASE_PATH=./data/app.db
JWT_SECRET=my-development-secret
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
```

Usage in your app:

```lua
-- app.lua - Load .env before anything else
local load_env = require("env")
load_env()

local config = require("config")
-- config now has values from .env
```

## Per-Environment Configuration

Different settings for development, staging, and production:

```lua
-- config.lua
local env = os_ext.env("APP_ENV") or "development"

local defaults = {
    port = 3000,
    log_level = "info",
    cors_origin = "*",
}

local overrides = {
    development = {
        log_level = "debug",
        cors_origin = "*",
    },
    staging = {
        port = 8080,
        log_level = "info",
        cors_origin = "https://staging.example.com",
    },
    production = {
        port = 80,
        log_level = "warn",
        cors_origin = "https://example.com",
    },
}

-- Merge defaults with environment overrides
local config = table.merge(defaults, overrides[env] or {})
config.env = env

return config
```

## Shipyard.toml

Configure your project with `Shipyard.toml`:

```toml
[project]
name = "my-api"
entry = "app.lua"

[server]
port = 3000
host = "0.0.0.0"

[scripts]
seed = "coppermoon scripts/seed.lua"
migrate = "coppermoon scripts/migrate.lua"
test = "coppermoon scripts/test.lua"
```

Run scripts with:

```bash
shipyard run seed
shipyard run migrate
```

## Secrets Management

### Best Practices

- Never commit secrets to version control
- Add `.env` to `.gitignore`
- Use different secrets per environment
- Rotate secrets regularly

### Example .gitignore

```
.env
.env.local
.env.production
*.db
harbor_modules/
```

### Validating Configuration

Check all required config at startup:

```lua
local function validate_config(config)
    local errors = {}

    if config.is_prod and not os_ext.env("JWT_SECRET") then
        table.insert(errors, "JWT_SECRET is required in production")
    end

    if config.is_prod and not os_ext.env("DATABASE_URL") then
        table.insert(errors, "DATABASE_URL is required in production")
    end

    if #errors > 0 then
        print(term.bold(term.red("Configuration errors:")))
        for _, err in ipairs(errors) do
            print(term.red("  - " .. err))
        end
        process.exit(1)
    end
end

validate_config(config)
```

## Platform Information

Get runtime information for logging and diagnostics:

```lua
print("Platform: " .. os_ext.platform())     -- "linux", "windows", "macos"
print("Arch: " .. os_ext.arch())              -- "x86_64", "aarch64"
print("CPUs: " .. os_ext.cpus())              -- 8
print("Hostname: " .. os_ext.hostname())      -- "prod-server-01"
print("CWD: " .. os_ext.cwd())               -- "/app"
print("Home: " .. (os_ext.homedir() or "?"))  -- "/root"
print("Temp: " .. os_ext.tmpdir())            -- "/tmp"
print("PID: " .. process.pid())               -- 12345
```

## Next Steps

- [REST APIs](/docs/backend-services/rest-api) - Build your API
- [Middleware Patterns](/docs/backend-services/middleware-patterns) - Security and logging
- [Database Integration](/docs/backend-services/database) - Connect to databases
- [Shipyard Configuration](/docs/shipyard/configuration) - Project config reference
