# Commands

Complete reference for all Shipyard CLI commands.

## new

Create a new project in a new directory.

```bash
shipyard new <name> [--template <type>]
```

| Argument | Required | Description |
|----------|----------|-------------|
| `name` | Yes | Project directory name |
| `--template, -t` | No | Template type: `minimal`, `web`, `api` (default: `minimal`) |

Creates a directory with `Shipyard.toml`, `app.lua`, `.gitignore`, and `harbor_modules/`.

```bash
shipyard new my-app
shipyard new my-site --template web
shipyard new my-api -t api
```

The `web` template auto-installs HoneyMoon and Vein into `harbor_modules/`.

## init

Initialize a project in the current directory.

```bash
shipyard init [--template <type>]
```

| Argument | Required | Description |
|----------|----------|-------------|
| `--template, -t` | No | Template type: `minimal`, `web`, `api` (default: `minimal`) |

Same as `new` but uses the current directory instead of creating one. Fails if a `Shipyard.toml` already exists. Uses the current directory name as the project name.

```bash
mkdir my-project && cd my-project
shipyard init --template web
```

## dev

Start the development server with hot reload.

```bash
shipyard dev [--port <port>]
```

| Argument | Required | Description |
|----------|----------|-------------|
| `--port, -p` | No | Port to listen on (default: from config or `3000`) |

The dev server:

1. Reads `Shipyard.toml` for the entry file and port
2. Starts the CopperMoon runtime with the entry file
3. Watches the project directory for file changes
4. Automatically restarts the server when changes are detected

**Watched directories:**

- Project root
- `views/`
- `lib/`
- `harbor_modules/`
- `public/`
- `content/`

**Watched file types:** `.lua`, `.vein`, `.html`, `.css`, `.js`, `.md`, `.toml`, `.json`

**Debounce:** 300ms between restarts to prevent rapid reloads.

The dev server monitors the process health and reports crashes with exit codes. Press `Ctrl+C` to stop.

```bash
shipyard dev
shipyard dev --port 8080
shipyard dev -p 5000
```

## run

Run the project in production mode.

```bash
shipyard run [--file <file>]
```

| Argument | Required | Description |
|----------|----------|-------------|
| `--file, -f` | No | Entry file to run (default: from config or `app.lua`) |

Starts the CopperMoon runtime with the entry file. No file watching or auto-restart.

```bash
shipyard run
shipyard run --file main.lua
shipyard run -f server.lua
```

## build

Build the project for production deployment.

```bash
shipyard build
```

Creates a `dist/` directory containing:

- The entry file (from config, default: `app.lua`)
- All `.lua` files from the project root
- The entire `harbor_modules/` directory (dependencies)

The `dist/` directory is ready to deploy. Run it with:

```bash
cd dist
coppermoon app.lua
```

## script

Run a custom script defined in `Shipyard.toml`.

```bash
shipyard script <name> [args...]
```

| Argument | Required | Description |
|----------|----------|-------------|
| `name` | Yes | Script name from `[scripts]` section |
| `args...` | No | Additional arguments appended to the command |

Alias: `shipyard x <name>`

Scripts are shell commands defined in the `[scripts]` section of `Shipyard.toml`:

```toml
[scripts]
test = "coppermoon tests/init.lua"
seed = "coppermoon seed.lua"
lint = "luacheck ."
```

```bash
shipyard script test
shipyard x lint
shipyard script test --verbose    # args appended to command
```

Scripts execute through the system shell (`cmd /C` on Windows, `sh -c` on Unix). If the script name is not found, Shipyard lists all available scripts.

## scripts

List all available scripts.

```bash
shipyard scripts
```

Displays a table of all scripts defined in `Shipyard.toml` with their names and commands. Shows example script definitions if none are configured.
