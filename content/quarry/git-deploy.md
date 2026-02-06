# Git Deployment

Quarry can deploy and manage applications directly from a Git repository. It clones the repo, starts your app, and automatically watches for new commits to pull updates and restart the process.

## Quick Start

```bash
quarry start git@github.com:user/my-app.git --entry-point app.lua
```

This will:

1. Clone the repository to `~/.quarry/repos/my-app/`
2. Register the process in **stopped** state
3. Wait for you to configure the app (e.g. create a `.env` file)
4. Start the app when you run `quarry restart my-app`

After the first launch, Quarry polls the remote repository for new commits and automatically restarts the process when changes are detected.

## Usage

### Starting from a Git URL

Quarry auto-detects Git URLs when the script argument starts with `https://`, `http://`, `git@`, or ends with `.git`:

```bash
# SSH (recommended for private repos)
quarry start git@github.com:user/my-app.git --entry-point app.lua

# HTTPS (public repos)
quarry start https://github.com/user/my-app --entry-point app.lua
```

### Options

| Option | Description |
|--------|-------------|
| `--entry-point, -e` | Lua script to run inside the repo (default: `main.lua`) |
| `--branch, -b` | Git branch to track (default: auto-detect main/master) |
| `--name, -n` | Process name (default: derived from repo name) |
| `--poll-interval` | Seconds between remote checks (default: 60) |
| `--max-restarts` | Max restart attempts (default: 16, 0 = infinite) |
| `--restart-delay` | Delay between restarts in ms (default: 1000) |
| `--min-uptime` | Min uptime to consider launch stable in ms (default: 5000) |
| `--kill-timeout` | Grace period before SIGKILL in ms (default: 5000) |

### Full example

```bash
quarry start git@github.com:myorg/api-server.git \
  --entry-point app.lua \
  --name api \
  --branch main \
  --poll-interval 30 \
  --max-restarts 0
```

## First Launch Workflow

On the first `quarry start` with a Git URL, the process is registered but **not started**. This gives you time to configure the application before it runs.

```bash
# 1. Clone and register
quarry start git@github.com:user/my-app.git --entry-point app.lua

# 2. Configure the app
cd ~/.quarry/repos/my-app
nano .env                    # Add environment variables, secrets, etc.

# 3. Start the app
quarry restart my-app

# 4. Verify it's running
quarry list
quarry logs my-app
```

After the initial setup, all subsequent updates (from git polls or manual restarts) start the process immediately without pausing.

## Auto-Update

Once a git-deployed process is **online**, Quarry runs a background poll loop that:

1. Checks the remote repository for new commits at the configured `poll-interval` (default: every 60 seconds)
2. If new commits are found, pulls the latest changes (`git fetch` + `git pull --ff-only`)
3. Stops the running process gracefully
4. Restarts the process with the updated code

The auto-update only runs on processes that are currently **online**. Stopped or errored processes are not checked.

### Poll interval

Control how frequently Quarry checks for updates:

```bash
# Check every 30 seconds
quarry start git@github.com:user/app.git --entry-point app.lua --poll-interval 30

# Check every 5 minutes
quarry start git@github.com:user/app.git --entry-point app.lua --poll-interval 300
```

### Monitoring updates

Git poll activity is logged to the daemon's stderr. You can view it with:

```bash
# If running as a systemd service
journalctl -u quarry -f
```

Example log output:

```
[git] New commits detected for 'my-app', restarting...
[git] 'my-app' restarted with latest changes
```

## Private Repositories

For private repos, use SSH authentication:

```bash
quarry start git@github.com:myorg/private-app.git --entry-point app.lua
```

### Setting up SSH keys

On your server, generate an SSH key and add it as a deploy key on GitHub:

```bash
# Generate a key (if not already done)
ssh-keygen -t ed25519 -C "my-server"

# Display the public key
cat ~/.ssh/id_ed25519.pub

# Test the connection
ssh -T git@github.com
```

Then add the public key to your repository:

- **GitHub**: Repository > Settings > Deploy keys > Add deploy key
- **GitLab**: Repository > Settings > Repository > Deploy keys
- **Bitbucket**: Repository > Settings > Access keys

HTTPS URLs for private repos will fail because the daemon cannot prompt for credentials. Always use SSH for private repositories.

## Data Directory

Git-deployed repos are stored in `~/.quarry/repos/`:

```
~/.quarry/
  repos/
    my-app/           # Cloned repository
      .env            # Your configuration files
      app.lua         # Entry point
      ...
  logs/
    my-app/
      out.log         # Process stdout
      err.log         # Process stderr
```

## Process Info

For git-deployed processes, `quarry info` displays additional fields:

```bash
quarry info my-app
```

```
Process Information
──────────────────────────────────────────────────
  Name:            my-app
  ID:              0
  Script:          app.lua
  CWD:             /root/.quarry/repos/my-app
  PID:             1234
  Status:          online
  Restarts:        0/16
  Uptime:          2h 15m
  Started at:      2025-01-15T10:30:00+00:00
  CPU:             0.5%
  Memory:          15.2 MB
  Watch:           disabled
  Git URL:         git@github.com:user/my-app.git
  Git Branch:      main
```

## Save and Resurrect

Git-deployed processes work with `quarry save` and `quarry resurrect` like any other process. The git configuration (URL, branch, entry point, poll interval) is preserved in the dump file.

```bash
quarry save
# After daemon restart, the process is resurrected with the same git config
```

## Production Setup

A complete production workflow for deploying from Git:

```bash
# 1. Deploy the app
quarry start git@github.com:myorg/api.git \
  --entry-point app.lua \
  --name api \
  --max-restarts 0 \
  --poll-interval 60

# 2. Configure environment
cd ~/.quarry/repos/api
nano .env

# 3. Start the app
quarry restart api

# 4. Save for auto-restore
quarry save

# 5. Enable systemd (Linux)
sudo quarry startup

# 6. Verify
quarry list
quarry ping
```

With this setup:
- The app auto-restarts on crash
- New commits on the tracked branch trigger automatic updates
- The daemon auto-starts on boot via systemd
- Saved processes auto-resurrect when the daemon starts
