# Installing Packages

## Install All Dependencies

Run `harbor install` with no arguments to install everything declared in `harbor.toml`:

```bash
harbor install
```

This reads both `[dependencies]` and `[dev-dependencies]`, downloads, clones, or links any missing packages, and updates `harbor.lock`.

## Install a Specific Package

### From the registry

The simplest way to install a package — just use its name:

```bash
harbor install honeymoon
harbor install vein
harbor add freight          # 'add' is an alias for 'install'
```

Harbor checks the registry at [packages.coppermoon.dev](https://packages.coppermoon.dev), downloads the latest version as a tarball, and extracts it into `harbor_modules/`.

To install a specific version, use the `@` suffix:

```bash
harbor install honeymoon@0.2.0
harbor install vein@0.1.0
```

Registry packages are added to `harbor.toml` with their version:

```toml
[dependencies]
honeymoon = { version = "0.2.0" }
```

### From a Git repository

Install packages directly from any Git repository:

```bash
# GitHub shorthand
harbor install user/repo
harbor install user/repo@v1.0.0

# Full URL (GitHub, GitLab, Bitbucket, self-hosted)
harbor install https://github.com/user/repo
harbor install https://gitlab.com/team/project
harbor install https://my-server.com/libs/utils.git

# With a specific tag
harbor install https://github.com/user/repo@v2.0.0
```

Harbor auto-detects Git URLs and GitHub shorthand (`owner/repo`). The `@` suffix specifies a tag to check out. The repository must contain a `harbor.toml` at its root.

For branch or commit pinning, use the `harbor.toml` syntax directly:

```toml
[dependencies]
mylib = { git = "https://github.com/user/repo.git", branch = "develop" }
mylib = { git = "https://github.com/user/repo.git", rev = "abc123def456" }
```

Git repositories are cached locally as bare clones so subsequent installs and updates are fast. The package files are copied to `harbor_modules/` (the `.git/` directory is excluded).

### From a local path

```bash
harbor install ../my-utils
harbor install /absolute/path/to/lib
```

Path dependencies create a symlink on Unix (or copy on Windows) so your changes to the source are reflected immediately.

### As a dev dependency

Use the `-D` or `--dev` flag:

```bash
harbor install user/assay -D
harbor install --dev ../test-utils
```

This adds the package to `[dev-dependencies]` instead of `[dependencies]`.

## Update Packages

### Update all dependencies

```bash
harbor update
```

Re-fetches Git dependencies (checking for new commits) and syncs path dependencies.

### Update a specific package

```bash
harbor update mylib
```

For Git dependencies, this fetches the latest commit for the configured ref (tag, branch, or rev) and updates if the commit hash has changed.

## Remove a Package

```bash
harbor uninstall mylib
harbor rm mylib              # alias
```

Removes the package from `harbor_modules/`, updates `harbor.toml`, and updates `harbor.lock`.

## List Installed Packages

```bash
harbor list
harbor ls                        # alias
```

Displays all packages installed in `harbor_modules/` with their versions.

## The harbor_modules Directory

All packages are installed into `harbor_modules/` at the project root:

```
harbor_modules/
├── honeymoon/
│   ├── harbor.toml
│   ├── init.lua
│   └── lib/
│       └── ...
├── vein/
│   ├── harbor.toml
│   ├── init.lua
│   └── lib/
│       └── ...
└── my-utils -> ../my-utils   # Symlink for path deps
```

Each package has its own subdirectory. Lua's `require()` resolves packages from this directory.

This directory should be listed in `.gitignore`. Other developers install dependencies by running `harbor install` after cloning the project.

## The Lockfile

`harbor.lock` records the exact version and source of every installed package:

```toml
lockfile_version = 1

[packages.honeymoon]
version = "0.2.0"
registry = "https://packages.coppermoon.dev"
sha256 = "a1b2c3d4..."

[packages.my-utils]
version = "0.1.0"
path = "../my-utils"

[packages.mylib]
version = "1.0.0"
git = "https://github.com/user/mylib.git"
commit = "a1b2c3d4e5f67890abcdef1234567890abcdef12"
git_ref = "tag:v1.0.0"
```

**Commit this file to version control.** It ensures every developer and deployment gets identical dependency versions.

Registry dependencies include:
- `version` - Exact version installed
- `registry` - Registry URL the package was downloaded from
- `sha256` - SHA256 hash of the tarball for integrity verification

Git dependencies include:
- `version` - Version from the package's `harbor.toml`
- `git` - Repository URL
- `commit` - Exact commit SHA (40-character hash) for reproducibility
- `git_ref` - The ref type and value that was requested (e.g. `tag:v1.0.0`, `branch:main`)

Path dependencies include:
- `version` - Version from the package's `harbor.toml`
- `path` - Filesystem path to the package

## Comparing Dependency Types

| | Registry | Git | Path |
|---|----------|-----|------|
| **Source** | Harbor registry | Git repository | Local filesystem |
| **Installation** | Download tarball | Clone + copy | Symlink or copy |
| **Integrity** | SHA256 checksum | Commit SHA | None |
| **Version pinning** | Exact version | Tag, branch, commit, or latest | Current local version |
| **Best for** | Published packages | Private repos, forks | Development, monorepos |
| **Caching** | N/A | Bare clone in `~/.harbor/cache/git/` | N/A |

### When to use registry dependencies

- Installing published, stable packages
- The simplest and fastest install method
- Packages available on [packages.coppermoon.dev](https://packages.coppermoon.dev)

### When to use git dependencies

- Sharing packages across projects
- Pinning to a specific release tag for stability
- Using packages from private repositories
- Depending on packages hosted on GitHub, GitLab, etc.

### When to use path dependencies

- Developing multiple packages together in a monorepo
- Testing changes to a package before committing
- Using local packages during development
