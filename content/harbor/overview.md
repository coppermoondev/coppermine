# Harbor Package Manager

Harbor is the package manager for CopperMoon. It manages project dependencies and handles package installation from the Harbor registry, Git repositories, and local paths.

## Installation

Harbor is installed alongside CopperMoon. Verify it's available:

```bash
harbor --version
```

## Commands at a Glance

| Command | Alias | Purpose |
|---------|-------|---------|
| `harbor init [name]` | | Initialize a new `harbor.toml` |
| `harbor install [pkg]` | `harbor i`, `harbor add` | Install dependencies |
| `harbor uninstall <pkg>` | `harbor rm` | Remove a package |
| `harbor update [pkg]` | | Update dependencies |
| `harbor list` | `harbor ls` | List installed packages |

## Quick Start

### Initialize a project

```bash
harbor init my-app
```

This creates a `harbor.toml` and a `harbor_modules/` directory.

### Install a package

```bash
# From the registry
harbor install honeymoon
harbor install honeymoon@0.2.0

# From a Git repository
harbor install user/repo
harbor install user/repo@v1.0.0

# From a local path
harbor install ../my-local-lib
```

The package is downloaded, cloned, or linked into `harbor_modules/`.

### Use it in your code

```lua
local honeymoon = require("honeymoon")
local app = honeymoon.new()

app:get("/", function(req, res)
    res:send("Hello!")
end)

app:listen(3000)
```

### Install all dependencies

When you clone a project that has a `harbor.toml`, install all dependencies at once:

```bash
harbor install
```

## How It Works

Harbor uses three key files:

| File | Purpose |
|------|---------|
| `harbor.toml` | Declares your project metadata and dependencies |
| `harbor.lock` | Records exact installed versions for reproducibility |
| `harbor_modules/` | Directory where packages are installed |

When you run `harbor install`, Harbor:

1. Reads dependencies from `harbor.toml`
2. Resolves each package (from the registry, a Git repository, or a local path)
3. Downloads, clones, copies, or symlinks packages into `harbor_modules/`
4. Updates `harbor.lock` with exact versions, commit SHAs, and checksums

The lockfile ensures that every developer on the team gets the same dependency versions.

## Dependency Types

### Registry dependencies

The simplest way to add a package. Install by name from the Harbor registry ([packages.coppermoon.dev](https://packages.coppermoon.dev)):

```bash
harbor install honeymoon
harbor install honeymoon@0.2.0    # Specific version
harbor add vein                   # 'add' is an alias for 'install'
```

In `harbor.toml`:

```toml
[dependencies]
honeymoon = { version = "0.2.0" }
vein = { version = "0.1.0" }
```

Registry packages are downloaded as tarballs, verified, and extracted into `harbor_modules/`. The lockfile records the exact version and SHA256 checksum.

### Git dependencies

Packages installed directly from a Git repository. Supports GitHub, GitLab, Bitbucket, self-hosted Git servers, and any URL that `git clone` accepts.

```toml
[dependencies]
# Latest (default branch)
mylib = { git = "https://github.com/user/repo.git" }

# Pin to a tag
mylib = { git = "https://github.com/user/repo.git", tag = "v1.0.0" }

# Track a branch
mylib = { git = "https://github.com/user/repo.git", branch = "develop" }

# Pin to a specific commit
mylib = { git = "https://github.com/user/repo.git", rev = "abc123def" }
```

Git dependencies are cached locally and the lockfile records the exact commit hash for reproducible builds. Install from the CLI with GitHub shorthand:

```bash
harbor install user/repo            # GitHub shorthand
harbor install user/repo@v1.0.0    # With tag
harbor install https://gitlab.com/team/project  # Any git host
```

### Path dependencies

Local packages referenced by filesystem path, useful for monorepos and development:

```toml
[dependencies]
my-utils = { path = "../my-utils" }
```

Path dependencies are symlinked on Unix and copied on Windows.

### Dev dependencies

Packages only needed during development (testing, linting):

```toml
[dev-dependencies]
assay = { path = "../assay" }
```

## Next Steps

- [Installing Packages](/docs/harbor/installing-packages) - Install, update, and remove packages
- [Creating Packages](/docs/harbor/creating-packages) - Build your own packages
- [harbor.toml Reference](/docs/harbor/harbor-toml) - Complete configuration reference
