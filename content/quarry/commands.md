# Commands

Complete reference for all Quarry CLI commands. In every command that takes a target, you can pass a process **name**, numeric **ID**, or the keyword `all`.

## start

Start a CopperMoon app as a managed background process. The script can be a local `.lua` file or a Git repository URL.

```bash
quarry start <script> [options] [-- <args>]
```

### Local script

| Argument | Required | Description |
|----------|----------|-------------|
| `script` | Yes | Lua script to run |
| `--name, -n` | No | Process name (defaults to script filename) |
| `--cwd` | No | Working directory (defaults to current dir) |
| `--watch, -w` | No | Auto-restart on file changes |
| `--max-restarts` | No | Max restarts before errored state (default: 16, 0 = infinite) |
| `--restart-delay` | No | Delay between restarts in ms (default: 1000) |
| `--min-uptime` | No | Min uptime in ms to consider launch stable (default: 5000) |
| `--kill-timeout` | No | Grace period before SIGKILL in ms (default: 5000) |

Pass arguments to the Lua script after `--`:

```bash
quarry start app.lua --name my-api -- --port 3000 --env production
```

Example with all options:

```bash
quarry start server.lua \
  --name api \
  --cwd /srv/my-api \
  --watch \
  --max-restarts 10 \
  --restart-delay 2000 \
  --min-uptime 5000 \
  --kill-timeout 5000 \
  -- --port 8080
```

### Git repository

When the script argument is a Git URL (`https://`, `http://`, `git@`, or ends with `.git`), Quarry clones the repository and manages it as a git-deployed process.

| Argument | Required | Description |
|----------|----------|-------------|
| `script` | Yes | Git repository URL |
| `--entry-point, -e` | No | Lua script to run inside the repo (default: `main.lua`) |
| `--branch, -b` | No | Git branch to track (default: auto-detect) |
| `--name, -n` | No | Process name (defaults to repo name) |
| `--poll-interval` | No | Seconds between remote checks for new commits (default: 60) |
| `--max-restarts` | No | Max restarts before errored state (default: 16) |
| `--restart-delay` | No | Delay between restarts in ms (default: 1000) |
| `--min-uptime` | No | Min uptime in ms to consider launch stable (default: 5000) |
| `--kill-timeout` | No | Grace period before SIGKILL in ms (default: 5000) |

```bash
# SSH (recommended for private repos)
quarry start git@github.com:user/my-app.git --entry-point app.lua

# HTTPS (public repos)
quarry start https://github.com/user/my-app --entry-point app.lua

# With options
quarry start git@github.com:myorg/api.git \
  --entry-point app.lua \
  --name api \
  --branch main \
  --poll-interval 30 \
  --max-restarts 0
```

On first launch, the process is registered in **stopped** state so you can configure the app (e.g. add a `.env` file). Run `quarry restart <name>` to start it. See [Git Deployment](/docs/quarry/git-deploy) for the full workflow.

## stop

Stop process(es) gracefully. Sends SIGTERM (or equivalent on Windows), waits for the kill timeout, then force-kills if needed.

```bash
quarry stop <target>
```

| Argument | Required | Description |
|----------|----------|-------------|
| `target` | Yes | Process name, ID, or `all` |

```bash
quarry stop my-api
quarry stop 0
quarry stop all
```

## restart

Restart process(es). Stops and then re-spawns each matched process.

```bash
quarry restart <target>
```

| Argument | Required | Description |
|----------|----------|-------------|
| `target` | Yes | Process name, ID, or `all` |

```bash
quarry restart my-api
quarry restart all
```

## delete

Stop and remove process(es) from the managed list. Also deletes their log files.

```bash
quarry delete <target>
```

| Argument | Required | Description |
|----------|----------|-------------|
| `target` | Yes | Process name, ID, or `all` |

```bash
quarry delete my-api
quarry delete all
```

## list

Show all managed processes in a table with status, PID, restart count, uptime, CPU, and memory usage.

```bash
quarry list
```

Alias: `quarry ls`

Example output:

```
  id  name                 status        pid  restarts     uptime      cpu     memory
-------------------------------------------------------------------------------------
   0  api                  online       1234         0     1h 30m     0.3%    15.2 MB
   1  worker               online       1235         2       45m     1.2%     8.7 MB
   2  cron                 stopped         -         0          -        -          -
```

## logs

View process logs. By default shows the last 20 lines of stdout.

```bash
quarry logs <target> [options]
```

| Argument | Required | Description |
|----------|----------|-------------|
| `target` | Yes | Process name or ID |
| `-n, --lines` | No | Number of lines to show (default: 20) |
| `--follow, -f` | No | Stream new log lines in real time |
| `--err` | No | Show stderr log instead of stdout |

```bash
quarry logs my-api
quarry logs my-api -n 100
quarry logs my-api --follow
quarry logs my-api --err
```

## info

Show detailed information about a process.

```bash
quarry info <target>
```

| Argument | Required | Description |
|----------|----------|-------------|
| `target` | Yes | Process name or ID |

Example output:

```
Process Information
──────────────────────────────────────────────────
  Name:            my-api
  ID:              0
  Script:          app.lua
  CWD:             /srv/my-api
  PID:             1234
  Status:          online
  Restarts:        2/16
  Uptime:          1h 30m
  Started at:      2025-01-15T10:30:00+00:00
  CPU:             0.3%
  Memory:          15.2 MB
  Watch:           disabled
  Args:            --port 3000
```

For git-deployed processes, additional fields are shown:

```
  Git URL:         git@github.com:user/my-app.git
  Git Branch:      main
```

## monit

Live terminal dashboard that refreshes the process table every 2 seconds.

```bash
quarry monit
```

Press `Ctrl+C` to exit.

## save

Save the current process list to `dump.json` for auto-restore. Records each process configuration and whether it was running.

```bash
quarry save
```

After saving, the daemon will automatically resurrect saved processes when it restarts. See [Process Management](/docs/quarry/process-management) for details.

## resurrect

Manually restore previously saved processes from `dump.json`. Only processes that were online when saved are restarted. Processes already running (by name) are skipped.

```bash
quarry resurrect
```

## startfile

Start all apps defined in a `quarry.toml` config file.

```bash
quarry startfile [options]
```

| Argument | Required | Description |
|----------|----------|-------------|
| `-c, --config` | No | Config file path (default: `quarry.toml`) |

```bash
quarry startfile
quarry startfile -c production.toml
```

See [Configuration](/docs/quarry/configuration) for the file format.

## startup

Register the Quarry daemon as a systemd service on Linux. This enables automatic startup on boot.

```bash
sudo quarry startup
```

Requires root privileges. If not run as root, Quarry prints the manual commands you can copy and run.

## unstartup

Remove the Quarry systemd service.

```bash
sudo quarry unstartup
```

## flush

Truncate log files for one or all processes.

```bash
quarry flush [target]
```

| Argument | Required | Description |
|----------|----------|-------------|
| `target` | No | Process name, ID, or `all` (all if omitted) |

```bash
quarry flush my-api
quarry flush all
quarry flush          # Same as "all"
```

## ping

Check if the Quarry daemon is running.

```bash
quarry ping
```

## kill-daemon

Stop the Quarry daemon. All managed processes continue running as orphans (they are not stopped).

```bash
quarry kill-daemon
```
