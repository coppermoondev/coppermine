# Commands Reference

Complete API reference for all Redis commands available in the CopperMoon Redis package.

## Constructor

### `Redis.new(url)`

Create a new Redis client and connect to the server.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `url` | string | `"redis://127.0.0.1:6379"` | Redis connection URL |

**Returns:** Redis client instance

```lua
local Redis = require("redis")
local client = Redis.new("redis://localhost:6379")
```

## String Commands

### `client:get(key)`

Get the value of a key.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The key to retrieve |

**Returns:** `string` or `nil` if the key does not exist

```lua
local value = client:get("mykey")
```

### `client:set(key, value)`

Set a key to a string value.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The key to set |
| `value` | string | The value to store |

**Returns:** `"OK"`

```lua
client:set("name", "CopperMoon")
```

### `client:setex(key, seconds, value)`

Set a key with an expiration time in seconds.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The key to set |
| `seconds` | number | TTL in seconds |
| `value` | string | The value to store |

**Returns:** `"OK"`

```lua
client:setex("session:token", 3600, "abc123")
```

### `client:setnx(key, value)`

Set a key only if it does not already exist.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The key to set |
| `value` | string | The value to store |

**Returns:** `true` if the key was set, `false` if it already existed

```lua
local was_set = client:setnx("lock:job", "worker-1")
```

### `client:mget(...)`

Get the values of multiple keys in a single call.

| Parameter | Type | Description |
|-----------|------|-------------|
| `...` | string | One or more keys |

**Returns:** table of values (`nil` for keys that don't exist)

```lua
local values = client:mget("key1", "key2", "key3")
-- values[1], values[2], values[3]
```

### `client:mset(pairs)`

Set multiple key-value pairs at once.

| Parameter | Type | Description |
|-----------|------|-------------|
| `pairs` | table | `{ key = value, ... }` |

**Returns:** `"OK"`

```lua
client:mset({
    greeting = "hello",
    farewell = "goodbye",
})
```

### `client:incr(key, amount)`

Increment a key's integer value.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `key` | string | | The key to increment |
| `amount` | number | `1` | Increment amount |

**Returns:** `number` — the new value

```lua
client:set("counter", "10")
client:incr("counter")      --> 11
client:incr("counter", 5)   --> 16
```

### `client:decr(key, amount)`

Decrement a key's integer value.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `key` | string | | The key to decrement |
| `amount` | number | `1` | Decrement amount |

**Returns:** `number` — the new value

```lua
client:decr("counter")      --> 15
client:decr("counter", 3)   --> 12
```

### `client:append(key, value)`

Append a string to an existing key's value.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The key |
| `value` | string | The string to append |

**Returns:** `number` — the new string length

```lua
client:set("msg", "Hello")
client:append("msg", " World")  --> 11
client:get("msg")               --> "Hello World"
```

### `client:strlen(key)`

Get the length of the string value stored at a key.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The key |

**Returns:** `number`

```lua
client:set("msg", "Hello")
client:strlen("msg")  --> 5
```

## Key Commands

### `client:del(...)`

Delete one or more keys.

| Parameter | Type | Description |
|-----------|------|-------------|
| `...` | string | One or more keys to delete |

**Returns:** `number` — number of keys that were deleted

```lua
client:del("key1")
client:del("key1", "key2", "key3")  --> 2
```

### `client:exists(key)`

Check if a key exists.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The key to check |

**Returns:** `boolean`

```lua
if client:exists("session:abc") then
    print("Session exists")
end
```

### `client:expire(key, seconds)`

Set a timeout on a key.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The key |
| `seconds` | number | TTL in seconds |

**Returns:** `true` if the timeout was set, `false` if the key doesn't exist

```lua
client:expire("temp_data", 300)
```

### `client:persist(key)`

Remove the expiration from a key, making it persistent.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The key |

**Returns:** `boolean`

```lua
client:persist("important_data")
```

### `client:ttl(key)`

Get the remaining time to live of a key in seconds.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The key |

**Returns:** `number` — TTL in seconds. Returns `-2` if the key does not exist, `-1` if no expiry is set.

```lua
local ttl = client:ttl("session:abc")
if ttl == -2 then
    print("Key does not exist")
elseif ttl == -1 then
    print("No expiry set")
else
    print("Expires in " .. ttl .. " seconds")
end
```

### `client:keys(pattern)`

Find all keys matching a glob-style pattern.

| Parameter | Type | Description |
|-----------|------|-------------|
| `pattern` | string | Glob pattern (e.g. `"user:*"`) |

**Returns:** table of matching key names

```lua
local user_keys = client:keys("user:*")
for _, key in ipairs(user_keys) do
    print(key)
end
```

> **Warning:** Avoid using `keys` in production on large databases. It blocks the server while scanning. Use the `command("SCAN", ...)` approach for large keyspaces.

### `client:rename(key, newkey)`

Rename a key.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The current key name |
| `newkey` | string | The new key name |

**Returns:** `"OK"`

```lua
client:rename("old_name", "new_name")
```

### `client:typeof(key)`

Get the data type of a key.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The key |

**Returns:** `string` — one of `"string"`, `"list"`, `"set"`, `"zset"`, `"hash"`, or `"none"`

```lua
print(client:typeof("mylist"))  --> "list"
```

## Hash Commands

### `client:hget(key, field)`

Get the value of a hash field.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The hash key |
| `field` | string | The field name |

**Returns:** `string` or `nil`

```lua
local name = client:hget("user:1", "name")
```

### `client:hset(key, field, value)`

Set a hash field to a value.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The hash key |
| `field` | string | The field name |
| `value` | string | The value |

**Returns:** `number` — `1` if the field is new, `0` if it was updated

```lua
client:hset("user:1", "name", "Alice")
```

### `client:hmset(key, pairs)`

Set multiple hash fields at once.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The hash key |
| `pairs` | table | `{ field = value, ... }` |

**Returns:** `"OK"`

```lua
client:hmset("user:1", {
    name = "Alice",
    email = "alice@example.com",
    role = "admin",
})
```

### `client:hgetall(key)`

Get all fields and values of a hash.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The hash key |

**Returns:** table `{ field = value, ... }`

```lua
local user = client:hgetall("user:1")
print(user.name)   --> "Alice"
print(user.email)  --> "alice@example.com"
```

### `client:hdel(key, ...)`

Delete one or more hash fields.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The hash key |
| `...` | string | One or more field names |

**Returns:** `number` — number of fields deleted

```lua
client:hdel("user:1", "role", "email")
```

### `client:hexists(key, field)`

Check if a hash field exists.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The hash key |
| `field` | string | The field name |

**Returns:** `boolean`

```lua
if client:hexists("user:1", "email") then
    print("Email is set")
end
```

### `client:hkeys(key)`

Get all field names of a hash.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The hash key |

**Returns:** table of field names

```lua
local fields = client:hkeys("user:1")
-- {"name", "email", "role"}
```

### `client:hvals(key)`

Get all values of a hash.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The hash key |

**Returns:** table of values

```lua
local values = client:hvals("user:1")
```

### `client:hlen(key)`

Get the number of fields in a hash.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The hash key |

**Returns:** `number`

```lua
print(client:hlen("user:1"))  --> 3
```

## List Commands

### `client:lpush(key, ...)`

Push one or more values to the head (left) of a list.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The list key |
| `...` | string | Values to push |

**Returns:** `number` — the new list length

```lua
client:lpush("queue", "first")
client:lpush("queue", "second", "third")  --> 3
```

### `client:rpush(key, ...)`

Push one or more values to the tail (right) of a list.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The list key |
| `...` | string | Values to push |

**Returns:** `number` — the new list length

```lua
client:rpush("queue", "a", "b", "c")
```

### `client:lpop(key)`

Pop and return a value from the head (left) of a list.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The list key |

**Returns:** `string` or `nil` if the list is empty

```lua
local item = client:lpop("queue")
```

### `client:rpop(key)`

Pop and return a value from the tail (right) of a list.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The list key |

**Returns:** `string` or `nil` if the list is empty

```lua
local item = client:rpop("queue")
```

### `client:lrange(key, start, stop)`

Get a range of elements from a list.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The list key |
| `start` | number | Start index (0-based) |
| `stop` | number | Stop index (inclusive, -1 for end) |

**Returns:** table of strings

```lua
-- Get all elements
local all = client:lrange("queue", 0, -1)

-- Get first 3
local first3 = client:lrange("queue", 0, 2)
```

### `client:llen(key)`

Get the length of a list.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The list key |

**Returns:** `number`

```lua
print(client:llen("queue"))  --> 5
```

### `client:lindex(key, index)`

Get an element by its index.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The list key |
| `index` | number | 0-based index |

**Returns:** `string` or `nil`

```lua
local first = client:lindex("queue", 0)
local last  = client:lindex("queue", -1)
```

## Set Commands

### `client:sadd(key, ...)`

Add one or more members to a set.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The set key |
| `...` | string | Members to add |

**Returns:** `number` — number of members actually added (excludes duplicates)

```lua
client:sadd("tags", "lua", "redis", "native")  --> 3
client:sadd("tags", "lua")                     --> 0 (already exists)
```

### `client:srem(key, ...)`

Remove one or more members from a set.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The set key |
| `...` | string | Members to remove |

**Returns:** `number` — number of members removed

```lua
client:srem("tags", "redis")  --> 1
```

### `client:smembers(key)`

Get all members of a set.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The set key |

**Returns:** table of strings (unordered)

```lua
local tags = client:smembers("tags")
for _, tag in ipairs(tags) do
    print(tag)
end
```

### `client:sismember(key, member)`

Check if a value is a member of a set.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The set key |
| `member` | string | The value to check |

**Returns:** `boolean`

```lua
if client:sismember("tags", "lua") then
    print("Tagged with lua")
end
```

### `client:scard(key)`

Get the number of members in a set.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The set key |

**Returns:** `number`

```lua
print(client:scard("tags"))  --> 2
```

## Sorted Set Commands

### `client:zadd(key, score, member)`

Add a member to a sorted set with a score.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The sorted set key |
| `score` | number | The score |
| `member` | string | The member |

**Returns:** `number` — `1` if added, `0` if score was updated

```lua
client:zadd("leaderboard", 1500, "alice")
client:zadd("leaderboard", 2300, "bob")
```

### `client:zrange(key, start, stop)`

Get members in a sorted set by rank range (ascending score).

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The sorted set key |
| `start` | number | Start rank (0-based) |
| `stop` | number | Stop rank (inclusive, -1 for end) |

**Returns:** table of member strings

```lua
local top3 = client:zrange("leaderboard", 0, 2)
```

### `client:zrank(key, member)`

Get the rank (position) of a member in a sorted set, ordered by ascending score.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The sorted set key |
| `member` | string | The member |

**Returns:** `number` (0-based) or `nil` if the member doesn't exist

```lua
print(client:zrank("leaderboard", "bob"))  --> 1
```

### `client:zscore(key, member)`

Get the score of a member in a sorted set.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The sorted set key |
| `member` | string | The member |

**Returns:** `number` or `nil` if the member doesn't exist

```lua
print(client:zscore("leaderboard", "bob"))  --> 2300
```

### `client:zrem(key, member)`

Remove a member from a sorted set.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The sorted set key |
| `member` | string | The member to remove |

**Returns:** `number` — `1` if removed, `0` if not found

```lua
client:zrem("leaderboard", "alice")
```

### `client:zcard(key)`

Get the number of members in a sorted set.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | The sorted set key |

**Returns:** `number`

```lua
print(client:zcard("leaderboard"))  --> 2
```

## Pub/Sub

### `client:publish(channel, message)`

Publish a message to a channel.

| Parameter | Type | Description |
|-----------|------|-------------|
| `channel` | string | The channel name |
| `message` | string | The message to send |

**Returns:** `number` — number of subscribers that received the message

```lua
local count = client:publish("events", "user_signup")
```

### `client:subscriber()`

Create a dedicated subscriber connection. Redis requires a separate connection for subscriptions — this method opens a new one automatically.

**Returns:** `Subscriber` instance

```lua
local sub = client:subscriber()
```

## Subscriber Methods

The Subscriber object returned by `client:subscriber()` has its own set of methods for managing subscriptions and receiving messages.

### `sub:subscribe(...)`

Subscribe to one or more channels.

| Parameter | Type | Description |
|-----------|------|-------------|
| `...` | string | Channel names |

```lua
sub:subscribe("events")
sub:subscribe("chat", "notifications", "alerts")
```

### `sub:psubscribe(...)`

Subscribe to one or more glob-style patterns.

| Parameter | Type | Description |
|-----------|------|-------------|
| `...` | string | Glob patterns |

```lua
sub:psubscribe("user:*")
sub:psubscribe("event:*", "log:*")
```

### `sub:unsubscribe(...)`

Unsubscribe from one or more channels.

| Parameter | Type | Description |
|-----------|------|-------------|
| `...` | string | Channel names |

```lua
sub:unsubscribe("events")
sub:unsubscribe("chat", "notifications")
```

### `sub:punsubscribe(...)`

Unsubscribe from one or more patterns.

| Parameter | Type | Description |
|-----------|------|-------------|
| `...` | string | Glob patterns |

```lua
sub:punsubscribe("user:*")
```

### `sub:receive(timeout)`

Block until the next message arrives.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `timeout` | number | none (block forever) | Optional timeout in seconds |

**Returns:** table `{ channel, payload, pattern? }` or `nil` on timeout

The returned table has these fields:

| Field | Type | Description |
|-------|------|-------------|
| `channel` | string | The channel the message was received on |
| `payload` | string | The message content |
| `pattern` | string or nil | The matched pattern (only for `psubscribe` matches) |

```lua
-- Block forever until a message arrives
local msg = sub:receive()
print(msg.channel)  --> "events"
print(msg.payload)  --> "hello"

-- With a 5-second timeout
local msg = sub:receive(5.0)
if msg then
    print(msg.payload)
else
    print("Timed out")
end
```

### `sub:listen(callback)`

Continuously receive messages, calling `callback(msg)` for each one.

| Parameter | Type | Description |
|-----------|------|-------------|
| `callback` | function | Called with each message table |

The callback receives the same table as `receive()`. Return `false` from the callback to stop listening; any other return value (including `nil`) continues the loop.

```lua
sub:listen(function(msg)
    print("[" .. msg.channel .. "] " .. msg.payload)

    -- Stop when we receive "shutdown"
    if msg.payload == "shutdown" then
        return false
    end
end)
```

## Server Commands

### `client:ping()`

Ping the Redis server.

**Returns:** `"PONG"`

```lua
print(client:ping())  --> "PONG"
```

### `client:dbsize()`

Get the number of keys in the current database.

**Returns:** `number`

```lua
print(client:dbsize() .. " keys in database")
```

### `client:flushdb()`

Delete all keys in the current database.

**Returns:** `"OK"`

```lua
client:flushdb()
```

> **Warning:** This permanently deletes all data in the selected database.

### `client:select(db)`

Switch to a different database.

| Parameter | Type | Description |
|-----------|------|-------------|
| `db` | number | Database index (0-15) |

**Returns:** `"OK"`

```lua
client:select(1)  -- Switch to database 1
```

### `client:info(section)`

Get server information and statistics.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `section` | string | all sections | Optional section filter |

**Returns:** `string` — raw INFO output

```lua
-- All info
local info = client:info()

-- Specific section
local memory = client:info("memory")
```

## Generic Command

### `client:command(cmd, ...)`

Execute any Redis command by name. Use this for commands not covered by the methods above.

| Parameter | Type | Description |
|-----------|------|-------------|
| `cmd` | string | The command name (e.g. `"SCAN"`, `"OBJECT"`) |
| `...` | any | Command arguments (strings, numbers, booleans) |

**Returns:** varies depending on the command

```lua
-- SCAN for keys
local result = client:command("SCAN", 0, "MATCH", "user:*", "COUNT", 100)

-- Get object encoding
local enc = client:command("OBJECT", "ENCODING", "mykey")

-- RANDOMKEY
local key = client:command("RANDOMKEY")
```
