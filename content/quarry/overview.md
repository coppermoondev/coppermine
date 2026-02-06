# Quarry Process Manager

Quarry is a process manager for CopperMoon applications, inspired by PM2. It keeps your apps running in the background, automatically restarts them on crash, monitors CPU and memory usage, and manages logs. Quarry uses a daemon + CLI architecture that works seamlessly on Linux, macOS, and Windows.

## Installation

Quarry is installed alongside CopperMoon. Verify it's available:

```bash
quarry --version
```

## Commands at a Glance

| Command | Purpose |
|---------|---------|
| `quarry start script.lua` | Start an app as a managed background process |
| `quarry start <git-url>` | Deploy an app from a Git repository |
| `quarry stop name\|id\|all` | Stop process(es) gracefully |
| `quarry restart name\|id\|all` | Restart process(es) |
| `quarry delete name\|id\|all` | Stop and remove from process list |
| `quarry list` | Show all processes with status, CPU, memory |
| `quarry logs name` | View or stream process logs |
| `quarry info name` | Detailed process information |
| `quarry monit` | Live terminal dashboard |
| `quarry save` | Save process list for auto-restore |
| `quarry resurrect` | Restore previously saved processes |
| `quarry startfile` | Start all apps from a config file |
| `quarry startup` | Register as a systemd service (Linux) |
| `quarry flush` | Truncate log files |
| `quarry ping` | Check if the daemon is running |
| `quarry kill-daemon` | Stop the daemon |

## Quick Start

### Start an application

```bash
quarry start app.lua --name my-api
```

This launches `app.lua` as a background process managed by the Quarry daemon. The daemon auto-starts on the first CLI command if it isn't already running.

### Deploy from a Git repository

```bash
quarry start git@github.com:user/my-app.git --entry-point app.lua
```

Quarry clones the repository, registers the process in stopped state (so you can configure `.env`), and then watches for new commits to auto-update. See [Git Deployment](/docs/quarry/git-deploy) for the full workflow.

### Check running processes

```bash
quarry list
```

```
  id  name                 status        pid  restarts     uptime      cpu     memory
-------------------------------------------------------------------------------------
   0  my-api               online       1234         0     2m 30s     0.5%    12.3 MB
```

### View logs

```bash
quarry logs my-api
quarry logs my-api --follow    # Stream new lines in real time
quarry logs my-api --err       # View error log
```

### Restart, stop, delete

```bash
quarry restart my-api
quarry stop my-api
quarry delete my-api       # Stop + remove from list
```

Use `all` as the target to apply to every process:

```bash
quarry restart all
quarry stop all
```

## How It Works

Quarry uses a **daemon + CLI** model:

- The **daemon** runs in the background, managing child processes. It handles spawning, monitoring, auto-restart, CPU/memory metrics collection, and log routing.
- The **CLI** sends commands to the daemon over TCP (`127.0.0.1:42517`) using JSON messages.
- The daemon **auto-starts** on the first CLI command if it's not already running.

### Data directory

All process data is stored in `~/.quarry/`:

```
~/.quarry/
  daemon.pid          # Daemon process ID
  daemon.port         # TCP port the daemon listens on
  processes.json      # Saved process configurations
  dump.json           # Save/resurrect snapshot
  logs/
    {name}/out.log    # stdout per process
    {name}/err.log    # stderr per process
```

## Features

- **Auto-restart** on crash with configurable limits and exponential backoff
- **Git deployment** with auto-update on new commits
- **Graceful shutdown** with SIGTERM, then SIGKILL after timeout
- **CPU and memory monitoring** via sysinfo, refreshed every 3 seconds
- **Log management** with per-process stdout/stderr files
- **Save/Resurrect** to persist and restore running processes across daemon restarts
- **Config file** support for starting multiple apps at once
- **Systemd integration** on Linux for boot-time startup
- **Cross-platform** support for Linux, macOS, and Windows

## Next Steps

- [Commands](/docs/quarry/commands) - Detailed reference for every command
- [Git Deployment](/docs/quarry/git-deploy) - Deploy from Git repos with auto-update
- [Configuration](/docs/quarry/configuration) - quarry.toml config file reference
- [Process Management](/docs/quarry/process-management) - Auto-restart, save/resurrect, systemd
