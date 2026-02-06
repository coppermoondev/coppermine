# Configuration

Quarry supports a TOML config file (`quarry.toml`) to define multiple applications. Use `quarry startfile` to launch all apps from a config file at once.

## Basic Example

```toml
[[apps]]
name = "api"
script = "app.lua"

[[apps]]
name = "worker"
script = "worker.lua"
```

```bash
quarry startfile
```

## Full Example

```toml
[[apps]]
name = "api"
script = "app.lua"
cwd = "/srv/my-api"
args = ["--port", "3000"]
max_restarts = 10
restart_delay = 1000
min_uptime = 5000
kill_timeout = 5000
watch = false
env = { COPPERMOON_ENV = "production", LOG_LEVEL = "info" }

[[apps]]
name = "worker"
script = "worker.lua"
cwd = "/srv/worker"
max_restarts = 0
restart_delay = 2000

[[apps]]
name = "cron"
script = "cron.lua"
cwd = "/srv/cron"
watch = true
```

## Reference

### App fields

Each `[[apps]]` entry supports the following fields:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | string | **required** | Process name (must be unique) |
| `script` | string | **required** | Lua script to run |
| `cwd` | string | current dir | Working directory for the process |
| `args` | array | `[]` | Arguments passed to the Lua script |
| `max_restarts` | integer | `16` | Maximum restarts before entering errored state. `0` = infinite |
| `restart_delay` | integer | `1000` | Base delay between restart attempts (ms) |
| `min_uptime` | integer | `5000` | Minimum uptime in ms to consider a launch stable |
| `kill_timeout` | integer | `5000` | Grace period before force-kill in ms |
| `watch` | boolean | `false` | Auto-restart when files change |
| `env` | table | `{}` | Environment variables passed to the process |

### Environment variables

The `env` field is a TOML inline table of key-value string pairs:

```toml
[[apps]]
name = "api"
script = "app.lua"
env = { COPPERMOON_ENV = "production", SECRET_KEY = "abc123", PORT = "3000" }
```

These environment variables are set on the child process and are **not** inherited by other managed processes.

## Custom config path

By default, `quarry startfile` looks for `quarry.toml` in the current directory. Use `-c` to specify a different path:

```bash
quarry startfile -c /etc/quarry/production.toml
```

## Combining with save/resurrect

After starting apps from a config file, you can save the running state for automatic restore:

```bash
quarry startfile -c quarry.toml
quarry save
```

Now if the daemon restarts (or the server reboots with `quarry startup` enabled), all apps come back up automatically. See [Process Management](/docs/quarry/process-management) for details.
