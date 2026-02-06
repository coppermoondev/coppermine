# harbor.toml Reference

Complete reference for the `harbor.toml` configuration file.

## File Structure

```toml
[package]
name = "my-app"
version = "1.0.0"
description = "My application"
author = "Author Name <email@example.com>"
license = "MIT"
repository = "https://github.com/user/my-app"
keywords = ["web", "api"]
main = "init.lua"

[dependencies]
honeymoon = { version = "0.2.0" }
vein = { version = "0.1.0" }
freight = { git = "https://github.com/user/freight.git", tag = "v0.1.0" }
utils = { path = "../utils" }

[dev-dependencies]
assay = { path = "../assay" }

[scripts]
start = "coppermoon app.lua"
dev = "coppermoon --watch app.lua"
test = "coppermoon tests/init.lua"
seed = "coppermoon seed.lua"

[native]
build = true
```

## [package]

Project or package metadata.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | string | required | Package name |
| `version` | string | required | Semantic version |
| `description` | string | `""` | Short description |
| `author` | string | `""` | Author name and email |
| `license` | string | `"MIT"` | License identifier |
| `repository` | string | `""` | Source repository URL |
| `keywords` | string[] | `[]` | Search keywords |
| `main` | string | `"init.lua"` | Entry point file |

### name

The package name is used as:

- The directory name in `harbor_modules/`
- The argument to `require()` in Lua

```toml
name = "my-package"
```

```lua
local pkg = require("my-package")
```

### version

Semantic version string. Follow semver conventions:

```toml
version = "1.2.3"
```

### main

The file loaded when the package is required. If not specified, Harbor checks for `init.lua`, `index.lua`, or `main.lua` in order.

```toml
main = "init.lua"
```

## [dependencies]

Packages your project needs to run.

### Registry dependencies

Install a package by name from the Harbor registry:

```toml
[dependencies]
# Simple version pin
honeymoon = { version = "0.2.0" }
vein = { version = "0.1.0" }
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | string | Yes | Version to install |

Registry dependencies:

- Are downloaded from [packages.coppermoon.dev](https://packages.coppermoon.dev) (default registry)
- Lock the exact version and SHA256 checksum in `harbor.lock`
- Are extracted into `harbor_modules/`

### Git dependencies

Install a package directly from a Git repository:

```toml
[dependencies]
# Latest (default branch)
mylib = { git = "https://github.com/user/repo.git" }

# Pin to a specific tag (recommended for stability)
mylib = { git = "https://github.com/user/repo.git", tag = "v1.0.0" }

# Track a branch
mylib = { git = "https://github.com/user/repo.git", branch = "develop" }

# Pin to an exact commit hash
mylib = { git = "https://github.com/user/repo.git", rev = "a1b2c3d4e5f6" }
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `git` | string | Yes | Repository URL (HTTPS, SSH, `git://`) |
| `tag` | string | No | Git tag to check out |
| `branch` | string | No | Git branch to track |
| `rev` | string | No | Exact commit hash to pin |

Only one of `tag`, `branch`, or `rev` should be specified. If none is given, the repository's default branch is used.

Git dependencies:

- Must contain a `harbor.toml` at the repository root
- Are cloned into a local cache (`~/.harbor/cache/git/` or `%LOCALAPPDATA%/harbor/cache/git/`)
- Files are copied to `harbor_modules/` (excluding `.git/`)
- Lock the exact commit hash in `harbor.lock` for reproducibility
- Support SSH authentication (via the system's `git` credential helpers)

### Path dependencies

Reference a package on the local filesystem:

```toml
[dependencies]
my-lib = { path = "../my-lib" }
utils = { path = "../../shared/utils" }
```

Path dependencies:

- Must contain a `harbor.toml`
- Are symlinked on Unix, copied on Windows
- Update instantly when the source changes (via symlink)

Relative paths are resolved from the project root (where `harbor.toml` is located).

## [dev-dependencies]

Packages only needed during development. Same syntax as `[dependencies]`.

```toml
[dev-dependencies]
assay = { path = "../assay" }
```

Dev dependencies are installed by `harbor install` but are not included when your package is installed as a dependency of another project.

## [scripts]

Shell commands that can be run with `shipyard script <name>`:

```toml
[scripts]
start = "coppermoon app.lua"
dev = "coppermoon --watch app.lua"
test = "coppermoon tests/init.lua"
seed = "coppermoon seed.lua"
lint = "luacheck ."
format = "lua-format --in-place ."
```

```bash
shipyard script test
shipyard script seed
shipyard x dev           # 'x' is a shorthand alias
```

Scripts are executed through the system shell. Additional command-line arguments are appended to the script command.

## [native]

Configuration for packages that contain native Rust code. See [Native Modules](/docs/harbor/native-modules) for a complete guide.

```toml
[native]
build = true
```

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `build` | boolean | `false` | Run `cargo build --release` on install |

When `build = true`, Harbor will:

1. Run `cargo build --release` in the package directory after installation
2. Copy the compiled shared library (`.dll` / `.so` / `.dylib`) to a `native/` subdirectory
3. The library is then loadable via `require()` in Lua

Native packages must also include a `Cargo.toml` with `crate-type = ["cdylib"]` and a dependency on `mlua` with the `module` feature.

## Complete Examples

### Web Application

```toml
[package]
name = "copper-blog"
version = "0.1.0"
description = "Demo blog application"
author = "CopperMoon Team"
license = "MIT"
main = "app.lua"

[dependencies]
honeymoon = { version = "0.2.0" }
vein = { version = "0.1.0" }
freight = { version = "0.1.0" }
lantern = { version = "0.1.0" }
dotenv = { version = "0.1.0" }

[dev-dependencies]
assay = { path = "../assay" }

[scripts]
start = "coppermoon app.lua"
dev = "coppermoon --watch app.lua"
test = "coppermoon tests/init.lua"
seed = "coppermoon seed.lua"
```

### Utility Library

```toml
[package]
name = "string-utils"
version = "1.0.0"
description = "String manipulation utilities for Lua"
author = "Your Name <you@example.com>"
license = "MIT"
repository = "https://github.com/yourname/string-utils"
keywords = ["string", "utility", "text"]
main = "init.lua"

[dependencies]
```

### Monorepo Package

```toml
[package]
name = "my-app"
version = "0.1.0"
description = "Application using local packages"
main = "app.lua"

[dependencies]
honeymoon = { path = "../../packages/honeymoon" }
vein = { path = "../../packages/vein" }
freight = { path = "../../packages/freight" }
dotenv = { path = "../../packages/dotenv" }

[dev-dependencies]
assay = { path = "../../packages/assay" }

[scripts]
test = "coppermoon tests/init.lua"
```

### Mixed Dependencies (Registry + Git + Path)

```toml
[package]
name = "my-app"
version = "0.1.0"
description = "Application with mixed dependency sources"
main = "app.lua"

[dependencies]
# From the registry (published packages)
honeymoon = { version = "0.2.0" }
vein = { version = "0.1.0" }

# From Git (private packages, pre-release versions)
auth-lib = { git = "https://github.com/company/auth-lib.git", tag = "v2.1.0" }
internal-utils = { git = "https://gitlab.company.com/libs/utils.git", branch = "main" }

# From local path (development)
my-helpers = { path = "../helpers" }

[scripts]
start = "coppermoon app.lua"
dev = "coppermoon --watch app.lua"
```

### Native Module Package

```toml
[package]
name = "copper-redis"
version = "0.1.0"
description = "Redis client for CopperMoon"
author = "Your Name"
license = "MIT"
keywords = ["redis", "database", "cache"]

[native]
build = true
```

Native packages also require a `Cargo.toml` alongside `harbor.toml`. See [Native Modules](/docs/harbor/native-modules) for the full guide.
