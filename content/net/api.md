# API Reference

Complete API reference for the CopperMoon `net` module — TCP, UDP, WebSocket, and DNS.

## TCP

### `net.tcp.connect(host, port)`

Connect to a remote TCP server. Blocks until the connection is established or an error occurs.

| Parameter | Type | Description |
|-----------|------|-------------|
| `host` | string | Remote hostname or IP address |
| `port` | number | Remote port |

**Returns:** TCP connection object

**Raises:** error on connection failure, DNS resolution failure, or timeout

```lua
local conn = net.tcp.connect("example.com", 80)
```

### `net.tcp.listen(host?, port)`

Create a TCP server that listens for incoming connections.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `host` | string | `"0.0.0.0"` | Bind address |
| `port` | number | | Bind port |

**Returns:** TCP server object

```lua
local server = net.tcp.listen(8080)
local server = net.tcp.listen("127.0.0.1", 8080)
```

## TCP Connection Methods

### `conn:read(n?)`

Read up to `n` bytes from the connection. May return fewer bytes than requested.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `n` | number | `4096` | Maximum bytes to read |

**Returns:** string of bytes read

```lua
local data = conn:read()       -- up to 4096 bytes
local data = conn:read(1024)   -- up to 1024 bytes
```

### `conn:read_line()`

Read a single line from the connection (up to and including `\n`).

**Returns:** string including the newline character

```lua
local line = conn:read_line()
```

### `conn:read_all()`

Read all data until the connection is closed by the remote peer.

**Returns:** string of all bytes read

```lua
local data = conn:read_all()
```

### `conn:write(data)`

Write data to the connection. May write fewer bytes than the input.

| Parameter | Type | Description |
|-----------|------|-------------|
| `data` | string | Data to write |

**Returns:** number of bytes actually written

```lua
local written = conn:write("Hello")
```

### `conn:write_all(data)`

Write all data to the connection. Errors if the full payload cannot be sent.

| Parameter | Type | Description |
|-----------|------|-------------|
| `data` | string | Data to write |

```lua
conn:write_all("HTTP/1.0 200 OK\r\n\r\nHello\n")
```

### `conn:flush()`

Flush the write buffer, ensuring all buffered data is sent.

```lua
conn:flush()
```

### `conn:close()`

Close the connection (both read and write directions).

```lua
conn:close()
```

### `conn:set_timeout(ms?)`

Set read and write timeout on the connection.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `ms` | number | nil | Timeout in milliseconds, or `nil` to clear |

```lua
conn:set_timeout(5000)  -- 5 second timeout
conn:set_timeout(nil)   -- no timeout
```

### `conn:peer_addr()`

Get the remote address of the connection.

**Returns:** string in `"ip:port"` format

```lua
print(conn:peer_addr())  --> "93.184.216.34:80"
```

### `conn:local_addr()`

Get the local address of the connection.

**Returns:** string in `"ip:port"` format

```lua
print(conn:local_addr())  --> "192.168.1.5:54321"
```

## TCP Server Methods

### `server:accept()`

Block until a client connects, then return the connection.

**Returns:** TCP connection object

```lua
local conn = server:accept()
print("Client:", conn:peer_addr())
```

### `server:local_addr()`

Get the bound address of the server.

**Returns:** string in `"ip:port"` format

```lua
print(server:local_addr())  --> "0.0.0.0:8080"
```

### `server:set_nonblocking(bool)`

Toggle non-blocking mode on the listener.

| Parameter | Type | Description |
|-----------|------|-------------|
| `nonblocking` | boolean | `true` for non-blocking, `false` for blocking |

```lua
server:set_nonblocking(true)
```

## UDP

### `net.udp.bind(host?, port)`

Create a UDP socket bound to a local address.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `host` | string | `"0.0.0.0"` | Bind address |
| `port` | number | | Bind port (use `0` for OS-assigned) |

**Returns:** UDP socket object

```lua
local socket = net.udp.bind(9000)
local socket = net.udp.bind("127.0.0.1", 9000)
local socket = net.udp.bind(0)  -- random free port
```

## UDP Socket Methods

### `socket:send(data, host, port)`

Send a datagram to a specific address.

| Parameter | Type | Description |
|-----------|------|-------------|
| `data` | string | Payload to send |
| `host` | string | Destination hostname or IP |
| `port` | number | Destination port |

**Returns:** number of bytes sent

```lua
socket:send("Hello", "192.168.1.100", 9000)
```

### `socket:recv(n?)`

Receive a datagram. Blocks until data arrives or the timeout expires.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `n` | number | `65535` | Maximum bytes to receive |

**Returns:** `data, host, port` — the payload, sender IP, and sender port

```lua
local data, host, port = socket:recv()
print(data, "from", host .. ":" .. port)
```

### `socket:connect(host, port)`

Associate the socket with a remote address for use with `send_connected()`.

| Parameter | Type | Description |
|-----------|------|-------------|
| `host` | string | Remote hostname or IP |
| `port` | number | Remote port |

```lua
socket:connect("192.168.1.100", 9000)
```

### `socket:send_connected(data)`

Send a datagram to the previously connected address.

| Parameter | Type | Description |
|-----------|------|-------------|
| `data` | string | Payload to send |

**Returns:** number of bytes sent

```lua
socket:connect("192.168.1.100", 9000)
socket:send_connected("Hello")
```

### `socket:set_timeout(ms?)`

Set read and write timeout on the socket.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `ms` | number | nil | Timeout in milliseconds, or `nil` to clear |

```lua
socket:set_timeout(3000)
```

### `socket:local_addr()`

Get the bound local address of the socket.

**Returns:** string in `"ip:port"` format

```lua
print(socket:local_addr())  --> "0.0.0.0:9000"
```

### `socket:set_broadcast(bool)`

Enable or disable broadcast mode.

| Parameter | Type | Description |
|-----------|------|-------------|
| `broadcast` | boolean | `true` to enable broadcast |

```lua
socket:set_broadcast(true)
socket:send("Discover!", "255.255.255.255", 5000)
```

## WebSocket

### `net.ws.connect(url, options?)`

Connect to a WebSocket server. Supports `ws://` (plain) and `wss://` (TLS). Blocks until the handshake completes.

| Parameter | Type | Description |
|-----------|------|-------------|
| `url` | string | WebSocket URL (`ws://` or `wss://`) |
| `options` | table | Optional configuration |

**Options:**

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `headers` | table | nil | Custom HTTP headers for the handshake |
| `timeout` | number | nil | Read/write timeout in milliseconds (applied after connect) |

**Returns:** WebSocket connection object

**Raises:** error on connection failure, TLS error, or handshake rejection

```lua
-- Simple
local ws = net.ws.connect("wss://echo.websocket.org")

-- With options
local ws = net.ws.connect("ws://localhost:8080/chat", {
    headers = {
        ["Authorization"] = "Bearer my-token",
        ["X-Client-Id"] = "my-app",
    },
    timeout = 5000,
})
```

### `net.ws.listen(host?, port)`

Create a WebSocket server that listens for connections. Handles TCP binding and WebSocket upgrade handshake automatically on `accept()`.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `host` | string | `"0.0.0.0"` | Bind address |
| `port` | number | | Bind port |

**Returns:** WebSocket server object

```lua
local server = net.ws.listen(9001)
local server = net.ws.listen("127.0.0.1", 9001)
```

## WebSocket Connection Methods

### `ws:send(data, type?)`

Send a WebSocket frame.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `data` | string | | Payload to send |
| `type` | string | `"text"` | Frame type: `"text"` or `"binary"` |

```lua
ws:send("Hello!")                       -- text frame
ws:send("\x00\x01\x02\x03", "binary")  -- binary frame
ws:send(json.encode({ action = "ping" }))  -- JSON as text
```

### `ws:recv()`

Receive the next WebSocket message. Blocks until a message arrives, the timeout expires, or the connection closes.

**Returns:** message table, or `nil` if the connection is closed

The returned table has the following fields:

| Field | Type | Present | Description |
|-------|------|---------|-------------|
| `type` | string | always | `"text"`, `"binary"`, `"ping"`, `"pong"`, or `"close"` |
| `data` | string | always | Frame payload |
| `code` | number | close only | WebSocket close code (e.g. `1000`) |
| `reason` | string | close only | Close reason string |

**Raises:** error on timeout or connection failure

```lua
local msg = ws:recv()
if msg == nil then
    print("Connection closed")
elseif msg.type == "text" then
    print("Got:", msg.data)
elseif msg.type == "binary" then
    print("Binary:", #msg.data, "bytes")
elseif msg.type == "close" then
    print("Closed:", msg.code, msg.reason)
end
```

### `ws:ping(data?)`

Send a WebSocket ping frame.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `data` | string | `""` | Optional ping payload |

```lua
ws:ping()
ws:ping("heartbeat")
```

### `ws:pong(data?)`

Send an unsolicited WebSocket pong frame. Solicited pongs (responses to pings) are handled automatically.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `data` | string | `""` | Optional pong payload |

```lua
ws:pong()
```

### `ws:close(code?, reason?)`

Initiate a graceful WebSocket close handshake.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `code` | number | `1000` | Close status code |
| `reason` | string | `""` | Close reason string |

After calling `close()`, continue calling `recv()` to complete the handshake.

Common close codes:

| Code | Meaning |
|------|---------|
| `1000` | Normal closure |
| `1001` | Going away |
| `1002` | Protocol error |
| `1003` | Unsupported data |
| `1008` | Policy violation |
| `1011` | Internal error |

```lua
ws:close()                          -- normal close
ws:close(1001, "Server shutting down")  -- custom close
```

### `ws:set_timeout(ms?)`

Set read and write timeout on the underlying connection.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `ms` | number | nil | Timeout in milliseconds, or `nil` to clear |

```lua
ws:set_timeout(10000)  -- 10 seconds
ws:set_timeout(nil)    -- no timeout
```

### `ws:peer_addr()`

Get the remote address of the WebSocket connection.

**Returns:** string in `"ip:port"` format

```lua
print(ws:peer_addr())  --> "93.184.216.34:443"
```

### `ws:local_addr()`

Get the local address of the WebSocket connection.

**Returns:** string in `"ip:port"` format

```lua
print(ws:local_addr())  --> "192.168.1.5:54321"
```

## WebSocket Server Methods

### `server:accept()`

Block until a client connects, perform the WebSocket upgrade handshake, and return the connection.

**Returns:** WebSocket connection object (same methods as client connections)

**Raises:** error on accept failure or handshake rejection

```lua
local conn = server:accept()
print("Client:", conn:peer_addr())
```

### `server:local_addr()`

Get the bound address of the server.

**Returns:** string in `"ip:port"` format

```lua
print(server:local_addr())  --> "0.0.0.0:9001"
```

### `server:set_nonblocking(bool)`

Toggle non-blocking mode on the listener.

| Parameter | Type | Description |
|-----------|------|-------------|
| `nonblocking` | boolean | `true` for non-blocking, `false` for blocking |

```lua
server:set_nonblocking(true)
```

## Utility

### `net.resolve(hostname)`

Resolve a hostname to a list of IP addresses using the system DNS resolver.

| Parameter | Type | Description |
|-----------|------|-------------|
| `hostname` | string | Hostname to resolve |

**Returns:** table (array) of IP address strings

**Raises:** error on DNS resolution failure

```lua
local ips = net.resolve("example.com")
for _, ip in ipairs(ips) do
    print(ip)
end
-- "93.184.216.34"
-- "2606:2800:220:1:248:1893:25c8:1946"
```
