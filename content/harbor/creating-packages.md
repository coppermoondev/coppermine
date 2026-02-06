# Creating Packages

This guide explains how to create a Harbor package and structure it properly for use via Git or local path.

## Package Structure

A minimal Harbor package needs a `harbor.toml` and a Lua entry point:

```
my-package/
├── harbor.toml          # Package manifest
├── init.lua             # Main entry point (default)
└── lib/                 # Additional modules
    ├── utils.lua
    └── helpers.lua
```

## Initialize a Package

```bash
mkdir my-package && cd my-package
harbor init my-package
```

This creates a `harbor.toml` with default values:

```toml
[package]
name = "my-package"
version = "0.1.0"
description = ""
author = ""
license = "MIT"
main = "init.lua"
```

## Configure harbor.toml

Fill in the package metadata:

```toml
[package]
name = "my-package"
version = "1.0.0"
description = "A useful utility library for CopperMoon"
author = "Your Name <you@example.com>"
license = "MIT"
repository = "https://github.com/yourname/my-package"
keywords = ["utility", "helpers"]
main = "init.lua"

[dependencies]
```

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Package name (used in `require()`) |
| `version` | Yes | Semantic version (e.g. `1.0.0`) |
| `description` | No | Short description |
| `author` | No | Author name and email |
| `license` | No | License identifier (default: `MIT`) |
| `repository` | No | Source code URL |
| `keywords` | No | Array of keywords |
| `main` | No | Entry point file (default: `init.lua`) |

## Entry Point

The `main` field in `harbor.toml` (default: `init.lua`) is the file loaded when someone requires your package:

```lua
-- init.lua
local MyPackage = {}

function MyPackage.greet(name)
    return "Hello, " .. name .. "!"
end

function MyPackage.add(a, b)
    return a + b
end

return MyPackage
```

Users import it with:

```lua
local MyPackage = require("my-package")
print(MyPackage.greet("World"))
```

## Declaring Dependencies

If your package depends on other packages, declare them:

```toml
[dependencies]
json = { git = "https://github.com/user/lua-json.git", tag = "v1.0.0" }
logging = { git = "https://github.com/user/logging.git", tag = "v0.5.0" }

# Local path deps for development
utils = { path = "../utils" }
```

## Sharing Packages

### Via Git

The simplest way to share a package is to push it to a Git repository. Others can install it with:

```bash
harbor install user/my-package
harbor install user/my-package@v1.0.0
```

Or add it directly to their `harbor.toml`:

```toml
[dependencies]
my-package = { git = "https://github.com/user/my-package.git", tag = "v1.0.0" }
```

### Via local path

For monorepo setups or local development:

```bash
harbor install ../my-package
```

```toml
[dependencies]
my-package = { path = "../my-package" }
```

## Versioning

Use semantic versioning for your packages:

- **Major** (`2.0.0`) - Breaking changes
- **Minor** (`1.1.0`) - New features, backward compatible
- **Patch** (`1.0.1`) - Bug fixes, backward compatible

Use Git tags to mark releases:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Then consumers can pin to that tag:

```toml
my-package = { git = "https://github.com/user/my-package.git", tag = "v1.0.0" }
```

## Native Packages

Harbor also supports packages containing native Rust code. Native packages include a `Cargo.toml` and Rust source files alongside the standard `harbor.toml`. When installed, Harbor automatically compiles the Rust code and places the resulting shared library where CopperMoon's module loader can find it.

To mark a package as native, add to your `harbor.toml`:

```toml
[native]
build = true
```

For a complete guide on creating native modules — including project structure, Rust code conventions, `Cargo.toml` configuration, and platform considerations — see [Native Modules](/docs/harbor/native-modules).

## Example: Creating a Utility Library

### 1. Create the package

```bash
harbor init string-utils
```

### 2. Write the code

```lua
-- init.lua
local StringUtils = {}

function StringUtils.capitalize(str)
    return str:sub(1, 1):upper() .. str:sub(2)
end

function StringUtils.slugify(str)
    return str:lower():gsub("[^%w%s-]", ""):gsub("%s+", "-")
end

function StringUtils.truncate(str, length, suffix)
    suffix = suffix or "..."
    if #str <= length then return str end
    return str:sub(1, length - #suffix) .. suffix
end

return StringUtils
```

### 3. Configure

```toml
[package]
name = "string-utils"
version = "1.0.0"
description = "String manipulation utilities for Lua"
author = "Your Name"
license = "MIT"
keywords = ["string", "utility", "text"]
main = "init.lua"
```

### 4. Push to Git

```bash
git init
git add .
git commit -m "Initial release"
git tag v1.0.0
git remote add origin https://github.com/yourname/string-utils.git
git push -u origin main --tags
```

### 5. Install from another project

```bash
harbor install yourname/string-utils@v1.0.0
```

```lua
local strings = require("string-utils")
print(strings.capitalize("hello"))   -- "Hello"
print(strings.slugify("Hello World")) -- "hello-world"
```
