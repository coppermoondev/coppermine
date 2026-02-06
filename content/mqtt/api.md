# API Reference

Complete API reference for the CopperMoon MQTT package.

## Module

### `mqtt.connect(host, options)`

Connect to an MQTT broker and return a client instance. Blocks until the connection is established or the timeout is reached.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `host` | string | | Broker hostname or IP address |
| `options` | table | `nil` | Connection options (see below) |

**Options:**

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `port` | number | `1883` | Broker port |
| `client_id` | string | auto-generated | Unique client identifier |
| `username` | string | nil | Authentication username |
| `password` | string | nil | Authentication password |
| `keep_alive` | number | `60` | Keep-alive interval in seconds |
| `clean_session` | boolean | `true` | Start with a clean session |
| `timeout` | number | `10` | Connection timeout in seconds |
| `capacity` | number | `100` | Internal message buffer size |
| `will` | table | nil | Last Will and Testament |

**Will options:**

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `topic` | string | required | Topic to publish on unexpected disconnect |
| `payload` | string | required | Message to publish |
| `qos` | number | `0` | QoS level (0, 1, or 2) |
| `retain` | boolean | `false` | Whether to retain the will message |

**Returns:** MQTT client instance

**Raises:** error if the connection fails or times out

```lua
local mqtt = require("mqtt")

-- Minimal
local client = mqtt.connect("localhost")

-- Full options
local client = mqtt.connect("broker.example.com", {
    port = 1883,
    client_id = "my-device",
    username = "admin",
    password = "secret",
    keep_alive = 30,
    clean_session = true,
    timeout = 5,
    will = {
        topic = "devices/my-device/status",
        payload = "offline",
        qos = 1,
        retain = true,
    },
})
```

### `mqtt.QoS`

Table of QoS level constants.

| Constant | Value | Description |
|----------|-------|-------------|
| `mqtt.QoS.AT_MOST_ONCE` | `0` | Fire and forget |
| `mqtt.QoS.AT_LEAST_ONCE` | `1` | Acknowledged delivery |
| `mqtt.QoS.EXACTLY_ONCE` | `2` | Assured delivery |

```lua
client:subscribe("topic", mqtt.QoS.AT_LEAST_ONCE)
```

### `mqtt.version`

The package version string.

```lua
print(mqtt.version)  --> "0.1.0"
```

## Client Methods

### `client:publish(topic, payload, options)`

Publish a message to a topic.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `topic` | string | | Topic to publish to |
| `payload` | string | | Message payload |
| `options` | table | `nil` | Publish options |

**Options:**

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `qos` | number | `0` | QoS level (0, 1, or 2) |
| `retain` | boolean | `false` | Retain the message on the broker |

```lua
-- Simple publish
client:publish("sensors/temp", "22.5")

-- With options
client:publish("sensors/temp", "22.5", {
    qos = 1,
    retain = true,
})

-- Publish JSON
client:publish("events/log", json.encode({
    level = "info",
    message = "Server started",
}))
```

### `client:subscribe(topic, qos)`

Subscribe to a topic filter. MQTT wildcards are supported:

- `+` matches a single topic level
- `#` matches all remaining levels

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `topic` | string | | Topic filter |
| `qos` | number | `0` | Maximum QoS level for received messages |

```lua
-- Exact topic
client:subscribe("home/livingroom/temp")

-- Single-level wildcard
client:subscribe("home/+/temp")

-- Multi-level wildcard
client:subscribe("home/#")

-- With QoS
client:subscribe("alerts/#", 1)
```

### `client:unsubscribe(topic)`

Unsubscribe from a topic filter.

| Parameter | Type | Description |
|-----------|------|-------------|
| `topic` | string | Topic filter to unsubscribe from |

```lua
client:unsubscribe("home/livingroom/temp")
```

### `client:receive(timeout)`

Wait for the next incoming message. Blocks until a message arrives or the timeout is reached.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `timeout` | number | nil (block forever) | Timeout in seconds |

**Returns:** message table or `nil` on timeout

The returned message table has these fields:

| Field | Type | Description |
|-------|------|-------------|
| `topic` | string | The topic the message was published to |
| `payload` | string | The message content |
| `qos` | number | QoS level (0, 1, or 2) |
| `retain` | boolean | Whether this is a retained message |

**Raises:** error if the connection is permanently lost

```lua
-- Block until a message arrives
local msg = client:receive()
print(msg.topic)    --> "sensors/temp"
print(msg.payload)  --> "22.5"
print(msg.qos)      --> 0
print(msg.retain)   --> false

-- With timeout
local msg = client:receive(5)
if msg then
    print("Got: " .. msg.payload)
else
    print("Timed out")
end
```

### `client:listen(callback)`

Continuously receive messages, calling `callback(msg)` for each one. The loop runs until:

- The callback returns `false`
- The connection is lost

| Parameter | Type | Description |
|-----------|------|-------------|
| `callback` | function | Called with each message table |

The callback receives the same message table as `receive()`. Return `false` to stop the loop; any other return value (including `nil`) continues.

```lua
client:subscribe("events/#")

client:listen(function(msg)
    print("[" .. msg.topic .. "] " .. msg.payload)

    -- Stop on shutdown message
    if msg.payload == "shutdown" then
        return false
    end
end)
```

### `client:is_connected()`

Check the current connection status.

**Returns:** `boolean`

```lua
if client:is_connected() then
    print("Connected to broker")
else
    print("Disconnected")
end
```

### `client:disconnect()`

Gracefully disconnect from the broker. Sends an MQTT DISCONNECT packet.

```lua
client:disconnect()
```

After disconnecting, calling `publish`, `subscribe`, or `receive` will raise an error.
