# Native Modules

CopperMoon supports native modules written in Rust. This lets you use the full power of the Rust ecosystem — high-performance computation, system APIs, C libraries — and expose them to Lua through a simple `require()` call. Harbor handles building, packaging, and installing native modules automatically, similar to how npm handles C/C++ addons with `node-gyp`.

## How it Works

A native module is a Rust crate compiled to a shared library (`.dll` on Windows, `.so` on Linux, `.dylib` on macOS). It uses the [mlua](https://github.com/khvzak/mlua) crate with the `module` feature to expose a Lua-compatible entry point. When you call `require("my_module")`, CopperMoon's native loader:

1. Searches for the shared library in `harbor_modules/<name>/native/`
2. Loads it dynamically with `libloading`
3. Calls the `luaopen_<name>` entry point
4. Returns the module table to Lua

Native modules are loaded **after** Lua modules in the search order, so if a package has both `init.lua` and a native library, the Lua file takes precedence. This lets you write a Lua wrapper around your native code.

## Prerequisites

To create native modules, you need:

- **Rust toolchain** — Install from [rustup.rs](https://rustup.rs)
- **A C compiler** — MSVC on Windows (via Visual Studio Build Tools), GCC/Clang on Linux/macOS
- **CopperMoon** — Version with native module support

## Package Structure

A native Harbor package looks like this:

```
my-redis/
├── harbor.toml       # Package manifest with [native] section
├── Cargo.toml        # Rust crate configuration
├── src/
│   └── lib.rs        # Rust source — entry point for the native module
└── init.lua          # (optional) Lua wrapper
```

The key difference from a regular Harbor package is the presence of `Cargo.toml` and the `[native]` section in `harbor.toml`.

## Creating a Native Module

Let's build a real-world example: a Redis client module that wraps the Rust `redis` crate.

### 1. Initialize the package

```bash
mkdir copper-redis && cd copper-redis
harbor init copper-redis
```

### 2. Configure harbor.toml

Add the `[native]` section to tell Harbor this package contains Rust code:

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

The `[native] build = true` flag tells Harbor to run `cargo build --release` when installing this package and copy the compiled library to the `native/` directory.

### 3. Configure Cargo.toml

Create a `Cargo.toml` for the Rust crate:

```toml
[package]
name = "copper-redis"
version = "0.1.0"
edition = "2021"

[workspace]

[lib]
name = "copper_redis"
crate-type = ["cdylib"]

[dependencies]
mlua = { version = "0.10", features = ["lua54", "module"] }
redis = "0.27"
```

Important details:

- **`[workspace]`** — Prevents Cargo from looking for a parent workspace
- **`crate-type = ["cdylib"]`** — Produces a shared library (`.dll` / `.so` / `.dylib`)
- **`mlua` features** — Use `"lua54"` and `"module"`. Do **not** add `"vendored"` — it is mutually exclusive with `"module"`
- **`[lib] name`** — The library name. Hyphens are replaced by underscores (`copper-redis` becomes `copper_redis`). This must match the `luaopen_` symbol name

### 4. Write the Rust code

Create `src/lib.rs`:

```rust
use mlua::prelude::*;

#[mlua::lua_module]
fn copper_redis(lua: &Lua) -> LuaResult<LuaTable> {
    let module = lua.create_table()?;

    // connect(url) -> client userdata
    let connect = lua.create_function(|lua, url: String| {
        let client = redis::Client::open(url.as_str())
            .map_err(|e| LuaError::runtime(format!("Redis connect error: {}", e)))?;

        let mut con = client.get_connection()
            .map_err(|e| LuaError::runtime(format!("Redis connection error: {}", e)))?;

        // Store connection as Lua userdata
        let ud = lua.create_any_userdata(con)?;
        Ok(ud)
    })?;
    module.set("connect", connect)?;

    // get(connection, key) -> string | nil
    let get = lua.create_function(|_, (con, key): (LuaAnyUserData, String)| {
        let mut con = con.borrow_mut::<redis::Connection>()
            .map_err(|e| LuaError::runtime(e.to_string()))?;

        let result: Option<String> = redis::cmd("GET")
            .arg(&key)
            .query(&mut *con)
            .map_err(|e| LuaError::runtime(format!("Redis GET error: {}", e)))?;

        Ok(result)
    })?;
    module.set("get", get)?;

    // set(connection, key, value, [ttl]) -> "OK"
    let set = lua.create_function(|_, (con, key, value, ttl): (LuaAnyUserData, String, String, Option<u64>)| {
        let mut con = con.borrow_mut::<redis::Connection>()
            .map_err(|e| LuaError::runtime(e.to_string()))?;

        if let Some(seconds) = ttl {
            redis::cmd("SETEX")
                .arg(&key)
                .arg(seconds)
                .arg(&value)
                .query::<String>(&mut *con)
                .map_err(|e| LuaError::runtime(format!("Redis SETEX error: {}", e)))?;
        } else {
            redis::cmd("SET")
                .arg(&key)
                .arg(&value)
                .query::<String>(&mut *con)
                .map_err(|e| LuaError::runtime(format!("Redis SET error: {}", e)))?;
        }

        Ok("OK".to_string())
    })?;
    module.set("set", set)?;

    // del(connection, key) -> number of keys deleted
    let del = lua.create_function(|_, (con, key): (LuaAnyUserData, String)| {
        let mut con = con.borrow_mut::<redis::Connection>()
            .map_err(|e| LuaError::runtime(e.to_string()))?;

        let result: i64 = redis::cmd("DEL")
            .arg(&key)
            .query(&mut *con)
            .map_err(|e| LuaError::runtime(format!("Redis DEL error: {}", e)))?;

        Ok(result)
    })?;
    module.set("del", del)?;

    Ok(module)
}
```

Key points about the Rust code:

- **`#[mlua::lua_module]`** — This macro generates the `luaopen_copper_redis` C entry point. Name the function **without** the `luaopen_` prefix — the macro adds it automatically
- **Function name must match `[lib] name`** — If `[lib] name = "copper_redis"`, the function must be `fn copper_redis(...)`
- **Error handling** — Convert Rust errors to `LuaError::runtime()` for clean error messages in Lua
- **Userdata** — Use `lua.create_any_userdata()` to wrap Rust types that Lua code passes around as handles

### 5. Build and test locally

```bash
# Build the native library
cargo build --release

# Install as a local path dependency in your project
cd ../my-project
harbor install ../copper-redis
```

### 6. Use from Lua

```lua
local redis = require("copper_redis")

-- Connect to Redis
local con = redis.connect("redis://127.0.0.1:6379")

-- Set a value with a 60-second TTL
redis.set(con, "greeting", "Hello from CopperMoon!", 60)

-- Get a value
local value = redis.get(con, "greeting")
print(value) -- "Hello from CopperMoon!"

-- Delete a key
redis.del(con, "greeting")
```

## The `#[mlua::lua_module]` Macro

The `#[mlua::lua_module]` proc macro is the bridge between Rust and Lua. It:

1. Generates an `extern "C-unwind"` function named `luaopen_<function_name>`
2. Sets up the Lua state and calls your function
3. Pushes the returned value onto the Lua stack

Your function receives a `&Lua` reference and must return a `LuaResult<T>` where `T` is typically a `LuaTable` (the module's public API).

```rust
// The function name becomes the symbol: luaopen_my_module
#[mlua::lua_module]
fn my_module(lua: &Lua) -> LuaResult<LuaTable> {
    let exports = lua.create_table()?;
    // Add functions, values, etc.
    Ok(exports)
}
```

### Naming Convention

The function name must follow these rules:

| Cargo.toml `[lib] name` | Function name | Lua `require()` |
|--------------------------|---------------|------------------|
| `copper_redis` | `fn copper_redis(...)` | `require("copper_redis")` |
| `hello_native` | `fn hello_native(...)` | `require("hello_native")` |
| `my_crypto` | `fn my_crypto(...)` | `require("my_crypto")` |

Hyphens in package names are converted to underscores for the library name. If your package is named `copper-redis`, your `[lib] name` should be `copper_redis`.

## Adding a Lua Wrapper

You can include an `init.lua` file alongside the native code to provide a higher-level Lua API. Since Lua modules are searched before native modules, `init.lua` takes precedence and can load the native library internally:

```lua
-- init.lua — Lua wrapper around the native copper_redis module
local native = require("copper_redis")
local Redis = {}

function Redis.new(url)
    local self = setmetatable({}, { __index = Redis })
    self._con = native.connect(url or "redis://127.0.0.1:6379")
    return self
end

function Redis:get(key)
    return native.get(self._con, key)
end

function Redis:set(key, value, ttl)
    return native.set(self._con, key, value, ttl)
end

function Redis:del(key)
    return native.del(self._con, key)
end

return Redis
```

Now users get a clean object-oriented API:

```lua
local Redis = require("copper-redis")

local cache = Redis.new("redis://127.0.0.1:6379")
cache:set("user:1", "Alice", 3600)
print(cache:get("user:1")) -- "Alice"
```

## Installing Native Packages

Native packages are installed the same way as regular packages:

```bash
# From the registry
harbor install copper-redis

# From a local path
harbor install ../copper-redis
```

When Harbor detects `[native] build = true` in the package's `harbor.toml`, it automatically:

1. Runs `cargo build --release` in the package directory
2. Copies the compiled library to `harbor_modules/<name>/native/`
3. The library is ready to load via `require()`

The resulting directory structure after install:

```
my-project/
├── harbor.toml
├── harbor_modules/
│   └── copper-redis/
│       ├── harbor.toml
│       ├── Cargo.toml
│       ├── src/
│       │   └── lib.rs
│       ├── init.lua
│       └── native/
│           └── copper_redis.dll    # (or .so / .dylib)
└── app.lua
```

## Publishing Native Packages

Publishing works the same as regular packages. Harbor includes all Rust source files in the tarball:

```bash
harbor login
harbor publish
```

The tarball contains:

- All `.lua` files
- `harbor.toml`
- `Cargo.toml` and `Cargo.lock`
- All `.rs` source files in `src/`
- Excludes `target/` and `native/` directories

When another user installs your package, Harbor will build the native code from source on their machine. This ensures the compiled library matches their platform and architecture.

## Platform Considerations

### Library naming

CopperMoon automatically handles platform-specific library names:

| Platform | Prefix | Extension | Example |
|----------|--------|-----------|---------|
| Windows | *(none)* | `.dll` | `copper_redis.dll` |
| Linux | `lib` | `.so` | `libcopper_redis.so` |
| macOS | `lib` | `.dylib` | `libcopper_redis.dylib` |

### Windows: lua54.dll

On Windows, native modules compiled with mlua's `module` feature require `lua54.dll` at runtime. CopperMoon builds this automatically during compilation and places it next to the `coppermoon.exe` binary. You don't need to do anything — it just works.

If you're running into `LoadLibraryExW failed` errors, make sure `lua54.dll` is in the same directory as your `coppermoon` executable.

### Cross-compilation

Native packages are compiled from source on the target machine. This means:

- Users need Rust installed to install native packages
- No cross-compilation needed — the package builds natively
- Different platforms get their own optimized binaries

## Common Patterns

### Exposing Rust structs as userdata

```rust
use mlua::prelude::*;

struct Counter {
    value: i64,
}

impl LuaUserData for Counter {
    fn add_methods<M: LuaUserDataMethods<Self>>(methods: &mut M) {
        methods.add_method("get", |_, this, ()| Ok(this.value));

        methods.add_method_mut("increment", |_, this, amount: Option<i64>| {
            this.value += amount.unwrap_or(1);
            Ok(this.value)
        });

        methods.add_method_mut("reset", |_, this, ()| {
            this.value = 0;
            Ok(())
        });
    }
}

#[mlua::lua_module]
fn my_counter(lua: &Lua) -> LuaResult<LuaTable> {
    let module = lua.create_table()?;

    module.set("new", lua.create_function(|_, initial: Option<i64>| {
        Ok(Counter { value: initial.unwrap_or(0) })
    })?)?;

    Ok(module)
}
```

```lua
local counter = require("my_counter")

local c = counter.new(10)
print(c:get())       -- 10
c:increment(5)
print(c:get())       -- 15
c:reset()
print(c:get())       -- 0
```

### Error handling

Always convert Rust errors into Lua errors with descriptive messages:

```rust
// Good — clear error message
let file = std::fs::read_to_string(&path)
    .map_err(|e| LuaError::runtime(format!("Failed to read '{}': {}", path, e)))?;

// Bad — opaque error
let file = std::fs::read_to_string(&path)
    .map_err(LuaError::external)?;
```

### Returning multiple values

```rust
// Return (value, error) pattern
let result = lua.create_function(|_, key: String| {
    match do_something(&key) {
        Ok(val) => Ok((Some(val), mlua::Value::Nil)),
        Err(e) => Ok((None::<String>, mlua::Value::String(
            lua.create_string(&e.to_string())?
        ))),
    }
})?;
```

## Troubleshooting

### `vendored` and `module` are mutually exclusive

```
error: `vendored` and `module` features are mutually exclusive
```

Remove `vendored` from your mlua features. Use `features = ["lua54", "module"]` only.

### Symbol not found: `luaopen_luaopen_*`

If you see a double `luaopen_` prefix, you named your function with the prefix:

```rust
// Wrong — macro adds luaopen_ prefix, resulting in luaopen_luaopen_my_mod
#[mlua::lua_module]
fn luaopen_my_mod(lua: &Lua) -> LuaResult<LuaTable> { ... }

// Correct — function name without the prefix
#[mlua::lua_module]
fn my_mod(lua: &Lua) -> LuaResult<LuaTable> { ... }
```

### `LoadLibraryExW failed` on Windows

The module needs `lua54.dll` at runtime. Make sure it exists next to `coppermoon.exe`. If you built CopperMoon from source, this is generated automatically by the build script.

### Module not found after install

Check that the library is in the correct location:

```
harbor_modules/<package-name>/native/<lib_name>.<ext>
```

The `<lib_name>` must match your `[lib] name` in `Cargo.toml` (with hyphens replaced by underscores).
