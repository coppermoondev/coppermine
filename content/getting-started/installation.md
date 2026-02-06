# Installation

## Quick Install (Recommended)

The easiest way to install CopperMoon is with our install script:

```bash
curl -fsSL https://coppermoon.dev/install.sh | sh
```

This installs:
- `coppermoon` - The Lua runtime
- `shipyard` - Project CLI tool
- `harbor` - Package manager

## Building from Source

### Prerequisites

- Rust 1.70+ with Cargo
- Git

### Clone and Build

```bash
git clone https://github.com/coppermoon/coppermoon.git
cd coppermoon
cargo build --release
```

### Add to PATH

```bash
# Linux/macOS
export PATH="$PATH:$(pwd)/target/release"

# Windows (PowerShell)
$env:PATH += ";$(Get-Location)\target\release"
```

## Verify Installation

```bash
coppermoon --version
# CopperMoon v0.1.0

shipyard --version
# Shipyard v0.1.0
```

## IDE Support

### VS Code

Install the "Lua" extension by sumneko for:
- Syntax highlighting
- Code completion
- Linting

### Recommended Settings

```json
{
  "Lua.runtime.version": "Lua 5.4",
  "Lua.diagnostics.globals": [
    "_COPPERMOON_VERSION",
    "http",
    "json",
    "fs",
    "time",
    "os_ext"
  ]
}
```

## Next Steps

Continue to [Quick Start](/docs/getting-started/quickstart) to create your first project.
