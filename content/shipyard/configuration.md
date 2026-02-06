# Configuration

Shipyard projects are configured through `Shipyard.toml`, located at the project root.

## Full Reference

```toml
# Project metadata
name = "my-project"
version = "0.1.0"
description = "A CopperMoon application"

# Server settings
[server]
port = 3000
workers = 4
host = "127.0.0.1"

# Lua runtime settings
[lua]
version = "5.4"
entry = "app.lua"

# Package dependencies (managed by Harbor)
[dependencies]

# Custom scripts
[scripts]
test = "coppermoon tests/init.lua"
```

## Root Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | string | required | Project name |
| `version` | string | `"0.1.0"` | Project version (semver) |
| `description` | string | `""` | Project description |

## [server]

HTTP server configuration used by `shipyard dev` and `shipyard run`.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `port` | integer | `3000` | Port to listen on |
| `workers` | integer | CPU count | Number of worker threads |
| `host` | string | `"127.0.0.1"` | Address to bind to |

Set `host` to `"0.0.0.0"` to accept connections from other machines.

The `workers` value defaults to the number of CPU cores on the machine.

## [lua]

Lua runtime configuration.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `version` | string | `"5.4"` | Lua version |
| `entry` | string | `"app.lua"` | Application entry point file |

The `entry` field sets the main file that CopperMoon loads when starting the application. This is used by `shipyard dev`, `shipyard run`, and `shipyard build`.

## [dependencies]

Package dependencies managed by Harbor. This section lists packages that your project depends on.

```toml
[dependencies]
honeymoon = "0.2.0"
vein = "0.1.0"
```

Dependencies are installed into the `harbor_modules/` directory. See the [Harbor documentation](/docs/harbor/overview) for details on managing packages.

## [scripts]

Custom scripts that can be run with `shipyard script <name>` or `shipyard x <name>`.

```toml
[scripts]
test = "coppermoon tests/init.lua"
seed = "coppermoon seed.lua"
dev = "shipyard dev --port 3000"
build = "shipyard build"
lint = "luacheck ."
format = "lua-format --in-place ."
clean = "rm -rf dist build"
```

Each script is a shell command executed through the system shell. Additional arguments passed on the command line are appended to the script command.

```bash
shipyard script test              # Runs: coppermoon tests/init.lua
shipyard script test --verbose    # Runs: coppermoon tests/init.lua --verbose
```

## Minimal Configuration

A working `Shipyard.toml` only needs a name:

```toml
name = "my-app"
```

All other values use their defaults: port 3000, entry `app.lua`, Lua 5.4.

## Example: Web Application

```toml
name = "my-website"
version = "1.0.0"
description = "My personal website"

[server]
port = 3000
workers = 8
host = "127.0.0.1"

[lua]
version = "5.4"
entry = "app.lua"

[dependencies]
honeymoon = "0.2.0"
vein = "0.1.0"
freight = "0.1.0"
dotenv = "0.1.0"
tailwind = "0.1.0"

[scripts]
test = "coppermoon tests/init.lua"
seed = "coppermoon seed.lua"
dev = "shipyard dev"
```

## Example: REST API

```toml
name = "my-api"
version = "0.1.0"
description = "REST API service"

[server]
port = 8080
workers = 16
host = "0.0.0.0"

[lua]
entry = "server.lua"

[scripts]
test = "coppermoon tests/init.lua"
migrate = "coppermoon scripts/migrate.lua"
```
