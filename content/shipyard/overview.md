# Shipyard CLI

Shipyard is the official CLI toolchain for CopperMoon. It handles project creation, development server with hot reload, production builds, and custom script execution.

## Installation

Shipyard is installed alongside CopperMoon. Verify it's available:

```bash
shipyard --version
```

## Commands at a Glance

| Command | Purpose |
|---------|---------|
| `shipyard new <name>` | Create a new project |
| `shipyard init` | Initialize a project in the current directory |
| `shipyard dev` | Start development server with hot reload |
| `shipyard run` | Run the project |
| `shipyard build` | Build for production |
| `shipyard script <name>` | Run a custom script |
| `shipyard scripts` | List all available scripts |

## Quick Start

Create and run a new project:

```bash
shipyard new my-app --template web
cd my-app
shipyard dev
```

This creates a web application with HoneyMoon and Vein pre-installed, then starts the development server at `http://localhost:3000` with hot reload enabled.

## Project Templates

Shipyard includes three project templates:

| Template | Description | Includes |
|----------|-------------|----------|
| `minimal` | Basic Lua application (default) | app.lua only |
| `web` | Full web application | HoneyMoon + Vein |
| `api` | REST API server | HTTP server routes |

```bash
shipyard new my-app                    # Uses minimal template
shipyard new my-site --template web    # Web app with HoneyMoon
shipyard new my-api -t api             # REST API server
```

## Development Server

The `dev` command starts a development server with automatic file watching:

```bash
shipyard dev
shipyard dev --port 8080
```

Features:

- Watches for file changes in the project directory
- Automatically restarts the server when files change
- Monitors `.lua`, `.vein`, `.html`, `.css`, `.js`, `.md`, `.toml`, `.json` files
- 300ms debounce to prevent rapid restarts
- Crash detection with exit code reporting

## Custom Scripts

Define scripts in `Shipyard.toml` and run them with `shipyard script`:

```toml
[scripts]
test = "coppermoon tests/init.lua"
seed = "coppermoon seed.lua"
lint = "luacheck ."
```

```bash
shipyard script test
shipyard script seed
shipyard x lint          # 'x' is a shorthand alias
```

## Next Steps

- [Commands](/docs/shipyard/commands) - Detailed reference for each command
- [Configuration](/docs/shipyard/configuration) - Shipyard.toml reference
- [Project Templates](/docs/shipyard/templates) - Template details and generated files
