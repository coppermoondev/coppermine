# Introduction

Welcome to **CopperMoon**, a blazing-fast Lua runtime built in Rust. CopperMoon provides everything you need to build modern web applications, APIs, and more with the simplicity of Lua and the performance of Rust.

## What is CopperMoon?

CopperMoon is a complete ecosystem for building server-side applications in Lua:

- **CopperMoon Runtime** - A Lua 5.4 runtime with async I/O and modern APIs
- **HoneyMoon Framework** - Express.js-style web framework
- **Vein Templating** - Powerful Lua-inspired templating engine
- **Shipyard CLI** - Project scaffolding and development tools
- **Harbor** - Package manager for Lua modules

## Why Choose CopperMoon?

### Performance

Built on Rust with async I/O, CopperMoon can handle thousands of concurrent connections with minimal memory usage. The HTTP server is optimized for high throughput while maintaining low latency.

### Simplicity

Lua is one of the most readable programming languages. Combined with HoneyMoon's Express-like API, you can build complex applications with clean, maintainable code.

### Batteries Included

No need to hunt for packages. CopperMoon includes:
- HTTP server with routing
- JSON parsing and encoding
- File system operations
- Time and date utilities
- Cryptographic functions

### Full Stack Ready

From simple REST APIs to full web applications with templating, sessions, authentication, and more. CopperMoon has you covered.

## Quick Example

```lua
local honeymoon = require("honeymoon")
local app = honeymoon.new()

app:get("/", function(req, res)
    res:json({ message = "Hello, CopperMoon!" })
end)

app:listen(3000)
```

## Next Steps

- [Installation](/docs/getting-started/installation) - Set up CopperMoon on your machine
- [Quick Start](/docs/getting-started/quickstart) - Build your first application
- [HoneyMoon Framework](/docs/honeymoon/overview) - Learn the web framework
