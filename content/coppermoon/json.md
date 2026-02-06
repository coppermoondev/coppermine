# JSON

The `json` module provides JSON encoding and decoding. It is available globally without `require()`.

## Encoding

### json.encode(value)

Convert a Lua value to a JSON string.

```lua
json.encode(42)                        -- "42"
json.encode("hello")                   -- '"hello"'
json.encode(true)                      -- "true"
json.encode(nil)                       -- "null"
json.encode({1, 2, 3})                -- "[1,2,3]"
json.encode({name = "Alice", age = 30}) -- '{"age":30,"name":"Alice"}'
```

### json.pretty(value)

Encode to a formatted, indented JSON string.

```lua
local data = {
    name = "Alice",
    age = 30,
    hobbies = {"reading", "coding"},
}

print(json.pretty(data))
```

Output:

```json
{
  "age": 30,
  "hobbies": [
    "reading",
    "coding"
  ],
  "name": "Alice"
}
```

## Decoding

### json.decode(string)

Parse a JSON string into a Lua value.

```lua
local data = json.decode('{"name":"Alice","age":30}')
print(data.name)   -- "Alice"
print(data.age)    -- 30

local arr = json.decode("[1, 2, 3]")
print(arr[1])      -- 1

local val = json.decode("true")
print(val)         -- true
```

Throws an error if the JSON is invalid. Use `pcall()` to handle parse errors:

```lua
local ok, data = pcall(json.decode, invalidString)
if ok then
    print(data.name)
else
    print("Invalid JSON:", data)
end
```

## Type Mapping

### Lua to JSON

| Lua Type | JSON Type |
|----------|-----------|
| `nil` | `null` |
| `true` / `false` | `true` / `false` |
| number (integer) | number |
| number (float) | number |
| string | string |
| table (sequential keys) | array |
| table (string keys) | object |

### JSON to Lua

| JSON Type | Lua Type |
|-----------|----------|
| `null` | `nil` |
| `true` / `false` | boolean |
| number | number |
| string | string |
| array | table (1-indexed) |
| object | table (string keys) |

## Arrays vs Objects

Lua tables with sequential integer keys starting at 1 are encoded as JSON arrays:

```lua
json.encode({10, 20, 30})
-- "[10,20,30]"
```

Tables with string keys (or mixed keys) are encoded as JSON objects:

```lua
json.encode({x = 1, y = 2})
-- '{"x":1,"y":2}'
```

Empty tables are encoded as empty arrays:

```lua
json.encode({})
-- "[]"
```

## Practical Examples

### Read and write JSON files

```lua
-- Write
local config = {
    database = { host = "localhost", port = 5432 },
    debug = true,
}
fs.write("config.json", json.pretty(config))

-- Read
local content = fs.read("config.json")
local config = json.decode(content)
print(config.database.host)
```

### HTTP API with JSON

```lua
-- Fetch JSON from an API
local resp = http.get("https://api.example.com/users")
if resp.ok then
    local users = json.decode(resp.body)
    for _, user in ipairs(users) do
        print(user.name, user.email)
    end
end

-- Send JSON in a POST request
local resp = http.post("https://api.example.com/users",
    json.encode({ name = "Alice", email = "alice@example.com" }),
    { headers = { ["Content-Type"] = "application/json" } }
)
```

### JSON server endpoint

```lua
local server = http.server.new()

server:post("/api/echo", function(ctx)
    local ok, data = pcall(json.decode, ctx.body)
    if not ok then
        return ctx:status(400):json({ error = "Invalid JSON" })
    end
    return ctx:json({ received = data })
end)
```

### Parse and re-serialize

```lua
local input = '{"name":"Alice","scores":[95,87,92]}'
local data = json.decode(input)

-- Modify
data.average = 0
for _, s in ipairs(data.scores) do
    data.average = data.average + s
end
data.average = data.average / #data.scores

-- Re-encode
print(json.encode(data))
-- '{"average":91.333,"name":"Alice","scores":[95,87,92]}'
```
