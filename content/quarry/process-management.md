# Process Management

Quarry keeps your CopperMoon applications running reliably. This page covers auto-restart behavior, the save/resurrect system, systemd integration, and log management.

## Auto-Restart

When a managed process crashes, Quarry automatically restarts it. The behavior is controlled by three settings:

| Setting | Default | Description |
|---------|---------|-------------|
| `max_restarts` | 16 | Maximum restart attempts before marking as **errored**. Set to `0` for infinite. |
| `restart_delay` | 1000 ms | Base delay between restart attempts |
| `min_uptime` | 5000 ms | Minimum uptime to consider a launch **stable** |

### Exponential backoff

If a process dies before reaching `min_uptime`, it's considered **unstable**. Quarry applies exponential backoff to the restart delay:

- 1st unstable crash: `restart_delay * 2` (2s with default settings)
- 2nd unstable crash: `restart_delay * 4` (4s)
- 3rd unstable crash: `restart_delay * 8` (8s)
- Caps at `restart_delay * 32`

Once the process stays up past `min_uptime`, the backoff resets to the base `restart_delay`.

### Process states

| State | Meaning |
|-------|---------|
| **online** | Process is running normally |
| **stopped** | Process was manually stopped |
| **launching** | Process is waiting to be restarted after a crash |
| **errored** | Process exceeded `max_restarts` and will not be restarted |
| **stopping** | Process is shutting down (between SIGTERM and exit) |

## Graceful Shutdown

When you run `quarry stop`, Quarry sends a graceful termination signal:

- **Linux/macOS**: Sends `SIGTERM` to the entire process group
- **Windows**: Calls `TerminateProcess` on the child

If the process doesn't exit within `kill_timeout` (default: 5000 ms), Quarry force-kills it.

Process groups on Unix ensure that child processes spawned by your Lua app are also terminated, preventing orphan processes.

## Save and Resurrect

The save/resurrect system lets you persist the running process list so it survives daemon restarts and server reboots.

### Saving

```bash
quarry save
```

This writes `~/.quarry/dump.json` containing:
- The configuration of every managed process
- Whether each process was **online** at the time of save

### Resurrecting

```bash
quarry resurrect
```

Reads `dump.json` and restarts all processes that were online when saved. Processes that were stopped are skipped. If a process with the same name is already running, it's also skipped.

### Auto-resurrect on daemon startup

When the Quarry daemon starts and finds a `dump.json` file, it automatically resurrects saved processes. This means:

1. Start your apps: `quarry start app.lua --name my-api`
2. Save the state: `quarry save`
3. If the daemon is killed or the server reboots, the daemon restarts and your apps come back up automatically

This is the recommended workflow for production servers.

## Systemd Integration (Linux)

On Linux servers, register Quarry as a systemd service so the daemon starts automatically on boot:

```bash
sudo quarry startup
```

This creates `/etc/systemd/system/quarry.service`, enables, and starts it. The service:

- Starts the Quarry daemon on boot
- Auto-restarts the daemon if it crashes
- Runs as the current user with the correct `HOME` and `PATH`

Combined with `quarry save`, this gives you fully automatic process recovery after server reboots.

### Checking service status

```bash
# Via quarry
quarry ping

# Via systemctl
systemctl status quarry

# View daemon logs
journalctl -u quarry -f
```

### Removing the service

```bash
sudo quarry unstartup
```

This stops, disables, and removes the systemd service file.

## Log Management

Each process has two log files in `~/.quarry/logs/{name}/`:

| File | Content |
|------|---------|
| `out.log` | Process stdout |
| `err.log` | Process stderr |

### Viewing logs

```bash
quarry logs my-api              # Last 20 lines of stdout
quarry logs my-api -n 100       # Last 100 lines
quarry logs my-api --follow     # Stream in real time
quarry logs my-api --err        # View stderr
```

### Flushing logs

Truncate log files when they get too large:

```bash
quarry flush my-api    # Flush one process
quarry flush all       # Flush all processes
quarry flush           # Same as "all"
```

### Log location

Logs are deleted when a process is removed with `quarry delete`. They persist across restarts and daemon restarts.

## Monitoring

### Process table

```bash
quarry list
```

Shows ID, name, status, PID, restart count, uptime, CPU usage, and memory usage for all processes. CPU and memory metrics are refreshed every 3 seconds by the daemon.

### Detailed info

```bash
quarry info my-api
```

Shows extended information including the script path, working directory, start time, arguments, and watch mode status.

### Live dashboard

```bash
quarry monit
```

Displays a continuously refreshing process table (every 2 seconds). Press `Ctrl+C` to exit.

## Production Checklist

A typical production setup:

```bash
# 1. Start your apps
quarry start app.lua --name api --max-restarts 0
quarry start worker.lua --name worker --max-restarts 0

# 2. Save the process list
quarry save

# 3. Register as a systemd service (Linux)
sudo quarry startup

# 4. Verify everything is running
quarry list
quarry ping
```

With this setup:
- Apps auto-restart on crash (infinite retries with `--max-restarts 0`)
- The daemon auto-starts on boot via systemd
- Saved processes auto-resurrect when the daemon starts
