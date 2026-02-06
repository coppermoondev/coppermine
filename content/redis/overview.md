# Redis

A native Redis client for CopperMoon. Connect to Redis, get/set keys, work with hashes, lists, sets, sorted sets, pub/sub and more — all from Lua with a clean OO API backed by a compiled Rust module.

## Installation

```bash
harbor install redis
```

Harbor detects the native build flag and automatically compiles the Rust module for your platform. You need a working Rust toolchain (`cargo`) installed.

## Quick Start

```lua
local Redis = require("redis")

-- Connect to a local Redis server
local client = Redis.new("redis://127.0.0.1:6379")

-- Basic key/value operations
client:set("greeting", "Hello from CopperMoon!")
print(client:get("greeting"))  --> "Hello from CopperMoon!"

-- Check connection
print(client:ping())  --> "PONG"
```

## Connecting

Create a client with `Redis.new(url)`. The URL follows the standard Redis URI scheme:

```lua
-- Default (localhost:6379)
local client = Redis.new()

-- Explicit host and port
local client = Redis.new("redis://192.168.1.100:6380")

-- With password
local client = Redis.new("redis://:mypassword@localhost:6379")

-- With username and password (Redis 6+)
local client = Redis.new("redis://user:password@localhost:6379")

-- Select database
local client = Redis.new("redis://localhost:6379/2")
```

If no URL is provided, it defaults to `redis://127.0.0.1:6379`.

## Usage Examples

### Caching

```lua
local Redis = require("redis")
local client = Redis.new()

-- Cache with expiration (TTL in seconds)
client:setex("session:abc123", 3600, "user_data_here")

-- Check remaining TTL
print(client:ttl("session:abc123"))  --> 3599

-- Set only if key doesn't exist (useful for locks)
local acquired = client:setnx("lock:resource", "owner_id")
if acquired then
    print("Lock acquired!")
end
```

### Counters

```lua
-- Page view counter
client:set("views:home", "0")
client:incr("views:home")       --> 1
client:incr("views:home")       --> 2
client:incr("views:home", 10)   --> 12
client:decr("views:home", 5)    --> 7
```

### Hash Maps (User Profiles)

```lua
-- Store a user profile
client:hmset("user:1001", {
    name = "Alice",
    email = "alice@example.com",
    role = "admin",
})

-- Get a single field
print(client:hget("user:1001", "name"))  --> "Alice"

-- Get the entire profile
local profile = client:hgetall("user:1001")
for field, value in pairs(profile) do
    print(field, value)
end

-- Update a single field
client:hset("user:1001", "role", "superadmin")
```

### Lists (Job Queue)

```lua
-- Push jobs to a queue
client:rpush("jobs:email", "send_welcome:user42")
client:rpush("jobs:email", "send_receipt:order99")

-- Worker: pop jobs from the front
local job = client:lpop("jobs:email")
print(job)  --> "send_welcome:user42"

-- Check queue length
print(client:llen("jobs:email"))  --> 1

-- Peek at queued items without removing
local items = client:lrange("jobs:email", 0, -1)
```

### Sets (Tags / Unique Collections)

```lua
-- Tag a post
client:sadd("post:42:tags", "lua", "redis", "tutorial")

-- Check membership
print(client:sismember("post:42:tags", "lua"))    --> true
print(client:sismember("post:42:tags", "python"))  --> false

-- Get all tags
local tags = client:smembers("post:42:tags")

-- Count tags
print(client:scard("post:42:tags"))  --> 3
```

### Sorted Sets (Leaderboard)

```lua
-- Add scores
client:zadd("leaderboard", 1500, "alice")
client:zadd("leaderboard", 2300, "bob")
client:zadd("leaderboard", 1800, "charlie")

-- Top players (ascending rank)
local top = client:zrange("leaderboard", 0, -1)
-- {"alice", "charlie", "bob"}

-- Get rank and score
print(client:zrank("leaderboard", "bob"))    --> 2  (0-based)
print(client:zscore("leaderboard", "bob"))   --> 2300
```

### Pub/Sub

Redis pub/sub lets you send and receive messages in real-time across channels.

**Publishing** uses the regular client connection:

```lua
local receivers = client:publish("notifications", "New deployment started")
print(receivers .. " subscribers received the message")
```

**Subscribing** requires a dedicated connection (Redis protocol constraint). Create one with `client:subscriber()`:

```lua
local sub = client:subscriber()

-- Subscribe to channels
sub:subscribe("events", "notifications")

-- Subscribe to patterns (glob-style)
sub:psubscribe("user:*")

-- Blocking receive — waits for the next message
local msg = sub:receive()
print(msg.channel)   --> "events"
print(msg.payload)   --> "hello world"
print(msg.pattern)   --> nil (set for psubscribe matches)

-- Receive with timeout (seconds) — returns nil on timeout
local msg = sub:receive(5.0)
if msg then
    print(msg.payload)
else
    print("No message within 5 seconds")
end

-- Listen loop with callback
sub:listen(function(msg)
    print(msg.channel .. ": " .. msg.payload)
    -- return false to stop listening, anything else continues
    if msg.payload == "quit" then
        return false
    end
end)

-- Unsubscribe
sub:unsubscribe("events")
sub:punsubscribe("user:*")
```

A typical publisher/subscriber pair:

```lua
-- publisher.lua
local Redis = require("redis")
local client = Redis.new()
client:publish("chat", "Hello everyone!")

-- subscriber.lua
local Redis = require("redis")
local client = Redis.new()
local sub = client:subscriber()
sub:subscribe("chat")
sub:listen(function(msg)
    print("[" .. msg.channel .. "] " .. msg.payload)
end)
```

### Generic Command

For any Redis command not covered by the built-in methods, use `command()`:

```lua
-- SCAN cursor
local result = client:command("SCAN", 0, "MATCH", "user:*", "COUNT", 100)

-- OBJECT ENCODING
local encoding = client:command("OBJECT", "ENCODING", "mykey")

-- CLIENT INFO
local info = client:command("CLIENT", "INFO")
```

## Error Handling

All Redis operations raise Lua errors on failure. Use `pcall` to handle them gracefully:

```lua
local ok, err = pcall(function()
    client:set("key", "value")
end)

if not ok then
    print("Redis error: " .. tostring(err))
end
```

Connection errors are raised at construction time:

```lua
local ok, err = pcall(function()
    return Redis.new("redis://nonexistent-host:6379")
end)

if not ok then
    print("Could not connect: " .. tostring(err))
end
```

## Architecture

The package is a native Rust module compiled via Harbor's native build system. It consists of two layers:

- **`copper_redis`** — A compiled Rust library (`.dll` / `.so` / `.dylib`) that uses the `redis` crate for fast, synchronous Redis communication. Exposed to Lua via mlua's `#[lua_module]` macro.
- **`init.lua`** — A thin OO wrapper that provides the `Redis.new()` constructor and delegates all method calls to the native connection userdata.

This design gives you native performance for all Redis I/O while keeping the Lua API clean and idiomatic.
