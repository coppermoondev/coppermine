# MQTT

A native MQTT client for CopperMoon. Connect to any MQTT broker, publish messages, subscribe to topics with wildcards, and receive messages in real-time — all from Lua with a clean OO API backed by a compiled Rust module.

MQTT (Message Queuing Telemetry Transport) is a lightweight publish/subscribe messaging protocol widely used for IoT, real-time data feeds, notifications, and inter-service communication.

## Installation

```bash
harbor install mqtt
```

Harbor detects the native build flag and automatically compiles the Rust module for your platform. You need a working Rust toolchain (`cargo`) installed.

## Quick Start

```lua
local mqtt = require("mqtt")

-- Connect to a local MQTT broker
local client = mqtt.connect("localhost")

-- Subscribe to a topic
client:subscribe("sensors/temperature")

-- Publish a message
client:publish("sensors/temperature", "22.5")

-- Receive a message
local msg = client:receive()
print(msg.topic)    --> "sensors/temperature"
print(msg.payload)  --> "22.5"

-- Disconnect
client:disconnect()
```

## Connecting

Create a client with `mqtt.connect(host, options)`. The connection is established immediately — if the broker is unreachable, an error is raised.

```lua
-- Default (localhost:1883)
local client = mqtt.connect("localhost")

-- Custom port
local client = mqtt.connect("broker.example.com", { port = 8883 })

-- With authentication
local client = mqtt.connect("broker.example.com", {
    username = "myuser",
    password = "secret",
})

-- Full options
local client = mqtt.connect("broker.example.com", {
    port = 1883,
    client_id = "my-sensor-01",
    username = "user",
    password = "pass",
    keep_alive = 30,
    clean_session = true,
    timeout = 10,
})
```

### Connection Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `port` | number | `1883` | Broker port |
| `client_id` | string | auto-generated | Unique client identifier |
| `username` | string | nil | Authentication username |
| `password` | string | nil | Authentication password |
| `keep_alive` | number | `60` | Keep-alive interval in seconds |
| `clean_session` | boolean | `true` | Start with a clean session |
| `timeout` | number | `10` | Connection timeout in seconds |
| `capacity` | number | `100` | Internal message buffer size |
| `will` | table | nil | Last Will and Testament (see below) |

### Last Will and Testament

The Last Will is a message the broker publishes on your behalf when your client disconnects unexpectedly (network failure, crash, etc.). This is the standard MQTT mechanism for detecting offline devices.

```lua
local client = mqtt.connect("localhost", {
    client_id = "sensor-01",
    will = {
        topic = "devices/sensor-01/status",
        payload = "offline",
        qos = 1,
        retain = true,
    },
})

-- Publish online status
client:publish("devices/sensor-01/status", "online", { retain = true })
```

When `sensor-01` disconnects unexpectedly, the broker automatically publishes `"offline"` to `devices/sensor-01/status`.

## Publishing

Send messages to a topic with `client:publish()`:

```lua
-- Simple publish (QoS 0, no retain)
client:publish("home/livingroom/temperature", "22.5")

-- Publish with QoS and retain
client:publish("home/livingroom/temperature", "22.5", {
    qos = 1,
    retain = true,
})

-- Publish JSON data
client:publish("events/user/login", json.encode({
    user_id = 42,
    timestamp = time.now(),
    ip = "192.168.1.100",
}))
```

### QoS Levels

MQTT supports three Quality of Service levels:

| Level | Name | Description |
|-------|------|-------------|
| `0` | At Most Once | Fire and forget. Fastest, no acknowledgment. |
| `1` | At Least Once | Guaranteed delivery, may receive duplicates. |
| `2` | Exactly Once | Guaranteed single delivery. Slowest. |

QoS constants are available as `mqtt.QoS`:

```lua
mqtt.QoS.AT_MOST_ONCE   -- 0
mqtt.QoS.AT_LEAST_ONCE  -- 1
mqtt.QoS.EXACTLY_ONCE   -- 2
```

### Retained Messages

When `retain = true`, the broker stores the last message for that topic. Any new subscriber immediately receives the retained message upon subscribing. Useful for status/state topics.

## Subscribing

Subscribe to topics to receive messages. MQTT supports two wildcard characters:

- `+` — matches a single level: `sensors/+/temperature` matches `sensors/kitchen/temperature` and `sensors/bedroom/temperature`
- `#` — matches all remaining levels: `sensors/#` matches `sensors/temperature`, `sensors/kitchen/humidity`, etc.

```lua
-- Exact topic
client:subscribe("home/livingroom/temperature")

-- Single-level wildcard
client:subscribe("home/+/temperature")

-- Multi-level wildcard
client:subscribe("home/#")

-- Subscribe with QoS
client:subscribe("alerts/#", 1)

-- Unsubscribe
client:unsubscribe("home/livingroom/temperature")
```

## Receiving Messages

### Single Message

Use `client:receive()` to wait for the next message:

```lua
-- Block until a message arrives
local msg = client:receive()
print(msg.topic)    --> "sensors/temp"
print(msg.payload)  --> "22.5"
print(msg.qos)      --> 0
print(msg.retain)   --> false

-- With timeout (seconds) — returns nil if no message within the timeout
local msg = client:receive(5)
if msg then
    print(msg.payload)
else
    print("No message received within 5 seconds")
end
```

### Message Loop

Use `client:listen()` to continuously process messages:

```lua
client:subscribe("sensors/#")

client:listen(function(msg)
    print("[" .. msg.topic .. "] " .. msg.payload)

    -- Return false to stop the loop
    if msg.payload == "shutdown" then
        return false
    end
end)
```

The loop also stops automatically if the connection is lost.

### Custom Receive Loop

For more control, build your own loop with `receive()`:

```lua
client:subscribe("sensors/#")

while client:is_connected() do
    local msg = client:receive(1)  -- 1 second timeout
    if msg then
        -- Process message
        local value = tonumber(msg.payload)
        if value and value > 100 then
            client:publish("alerts/high-value", msg.payload, { qos = 1 })
        end
    end
    -- Do other work between receives
end
```

## Usage Examples

### IoT Sensor Network

```lua
local mqtt = require("mqtt")

-- Sensor publisher
local sensor = mqtt.connect("localhost", {
    client_id = "temp-sensor-01",
    will = {
        topic = "sensors/temp-01/status",
        payload = "offline",
        qos = 1,
        retain = true,
    },
})

sensor:publish("sensors/temp-01/status", "online", { retain = true })

-- Publish readings every 5 seconds
while true do
    local reading = math.random(180, 250) / 10  -- 18.0 - 25.0
    sensor:publish("sensors/temp-01/value", tostring(reading))
    time.sleep(5000)
end
```

```lua
-- Dashboard subscriber
local mqtt = require("mqtt")

local dashboard = mqtt.connect("localhost", {
    client_id = "dashboard",
})

dashboard:subscribe("sensors/#")

dashboard:listen(function(msg)
    local sensor = msg.topic:match("sensors/(.+)/value")
    if sensor then
        print(term.cyan(sensor) .. ": " .. term.bold(msg.payload) .. "C")
    elseif msg.topic:ends_with("/status") then
        local name = msg.topic:match("sensors/(.+)/status")
        if msg.payload == "online" then
            print(term.green(name .. " is online"))
        else
            print(term.red(name .. " went offline"))
        end
    end
end)
```

### Microservice Communication

```lua
local mqtt = require("mqtt")
local client = mqtt.connect("localhost", { client_id = "order-service" })

-- Listen for new orders
client:subscribe("orders/new", 1)

client:listen(function(msg)
    local order = json.decode(msg.payload)
    print("Processing order #" .. order.id)

    -- Validate and store
    db:execute("INSERT INTO orders (id, user_id, total) VALUES (?, ?, ?)",
        order.id, order.user_id, order.total)

    -- Notify other services
    client:publish("orders/confirmed", json.encode({
        order_id = order.id,
        status = "confirmed",
        timestamp = time.now(),
    }), { qos = 1 })
end)
```

### Chat System

```lua
local mqtt = require("mqtt")

local username = console.prompt("Username: ")
local client = mqtt.connect("localhost", {
    client_id = "chat-" .. username,
    will = {
        topic = "chat/presence",
        payload = json.encode({ user = username, status = "offline" }),
        qos = 1,
    },
})

-- Announce presence
client:publish("chat/presence", json.encode({
    user = username,
    status = "online",
}), { qos = 1 })

-- Subscribe to messages and presence
client:subscribe("chat/messages")
client:subscribe("chat/presence")

-- Read messages in background-like loop
-- (In practice you'd use coroutines or separate scripts)
client:listen(function(msg)
    if msg.topic == "chat/messages" then
        local data = json.decode(msg.payload)
        if data.user ~= username then
            print(term.bold(data.user) .. ": " .. data.text)
        end
    elseif msg.topic == "chat/presence" then
        local data = json.decode(msg.payload)
        if data.user ~= username then
            if data.status == "online" then
                print(term.green(">> " .. data.user .. " joined"))
            else
                print(term.red(">> " .. data.user .. " left"))
            end
        end
    end
end)
```

## Error Handling

All MQTT operations raise Lua errors on failure. Use `pcall` to handle them gracefully:

```lua
-- Connection errors
local ok, err = pcall(function()
    return mqtt.connect("nonexistent-host", { timeout = 3 })
end)
if not ok then
    print("Could not connect: " .. tostring(err))
end

-- Publish/subscribe errors
local ok, err = pcall(function()
    client:publish("topic", "message")
end)
if not ok then
    print("MQTT error: " .. tostring(err))
end
```

## Architecture

The package is a native Rust module compiled via Harbor's native build system. It consists of two layers:

- **`copper_mqtt`** — A compiled Rust library (`.dll` / `.so` / `.dylib`) that uses the `rumqttc` crate for MQTT 3.1.1 communication. A background thread drives the connection event loop, handling reconnections automatically. Exposed to Lua via mlua's `#[lua_module]` macro.
- **`init.lua`** — A thin OO wrapper that provides the `mqtt.connect()` constructor and delegates all method calls to the native client userdata.

This design gives you native performance for all MQTT I/O while keeping the Lua API clean and idiomatic.

### Reconnection

After the initial connection is established, the client automatically attempts to reconnect if the connection is lost. The `is_connected()` method reflects the current connection state. If the broker comes back online, the client reconnects and resumes operation.

## Next Steps

- [API Reference](/docs/mqtt/api) - Complete method reference
- [Backend Services](/docs/backend-services/overview) - Build backend services with CopperMoon
- [Redis](/docs/redis/overview) - Redis client for caching and pub/sub
