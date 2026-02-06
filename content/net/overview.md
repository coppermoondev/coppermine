# Network

A complete networking toolkit built into CopperMoon's standard library. The `net` module provides low-level TCP and UDP sockets for custom protocols, plus a full WebSocket client and server for real-time communication — all with a simple, synchronous API.

## Quick Start

### TCP Client

```lua
local conn = net.tcp.connect("example.com", 80)
conn:write_all("GET / HTTP/1.0\r\nHost: example.com\r\n\r\n")
local response = conn:read_all()
print(response)
conn:close()
```

### UDP

```lua
local socket = net.udp.bind(0)
socket:send("Hello!", "127.0.0.1", 9000)
local data, host, port = socket:recv()
print(data, "from", host .. ":" .. port)
```

### WebSocket Client

```lua
local ws = net.ws.connect("wss://echo.websocket.org")
ws:send("Hello WebSocket!")
local msg = ws:recv()
print(msg.type, msg.data)  --> "text", "Hello WebSocket!"
ws:close()
```

## TCP

TCP provides reliable, ordered, byte-stream connections. Use it for custom protocols, low-level HTTP, database wire protocols, or any scenario where you need a persistent connection.

### Connecting

```lua
local conn = net.tcp.connect("localhost", 8080)
print("Connected to", conn:peer_addr())
```

### Reading and Writing

The connection provides several read methods depending on your needs:

```lua
-- Read up to N bytes (default 4096)
local chunk = conn:read(1024)

-- Read a single line (up to \n)
local line = conn:read_line()

-- Read everything until the connection closes
local all = conn:read_all()

-- Write data
conn:write("Hello")       -- returns bytes written
conn:write_all("Hello")   -- writes all bytes, errors if incomplete
conn:flush()               -- flush the write buffer
```

### Timeouts

Set read and write timeouts to avoid blocking forever:

```lua
conn:set_timeout(5000)  -- 5 seconds
local data = conn:read()  -- will error after 5s if no data

conn:set_timeout(nil)  -- remove timeout (block indefinitely)
```

### TCP Server

Create a server that accepts incoming connections:

```lua
local server = net.tcp.listen("0.0.0.0", 8080)
print("Listening on", server:local_addr())

while true do
    local conn = server:accept()  -- blocks until a client connects
    print("Client:", conn:peer_addr())

    local request = conn:read_line()
    conn:write_all("HTTP/1.0 200 OK\r\n\r\nHello!\n")
    conn:close()
end
```

The host parameter is optional and defaults to `"0.0.0.0"` (all interfaces):

```lua
local server = net.tcp.listen(8080)            -- all interfaces
local server = net.tcp.listen("127.0.0.1", 8080) -- localhost only
```

## UDP

UDP provides fast, connectionless datagrams. Use it for DNS queries, game networking, IoT telemetry, service discovery, or any protocol where speed matters more than guaranteed delivery.

### Binding

Every UDP socket must be bound to a local port before it can send or receive:

```lua
local socket = net.udp.bind(9000)            -- bind to port 9000
local socket = net.udp.bind("127.0.0.1", 9000) -- bind to specific interface
local socket = net.udp.bind(0)               -- OS picks a free port
```

### Sending and Receiving

```lua
-- Send to a specific address
socket:send("Hello", "192.168.1.100", 9000)

-- Receive a datagram (returns data, sender host, sender port)
local data, host, port = socket:recv()
print(data, "from", host .. ":" .. port)

-- Limit receive buffer size
local data, host, port = socket:recv(512)
```

### Connected Mode

For repeated communication with a single peer, connect the socket:

```lua
socket:connect("192.168.1.100", 9000)
socket:send_connected("Hello")  -- no need to specify address each time
```

### Broadcast

Enable broadcast to send to all hosts on the local network:

```lua
socket:set_broadcast(true)
socket:send("Discovery!", "255.255.255.255", 9000)
```

## WebSocket

WebSocket provides full-duplex communication over a single TCP connection. Use it for real-time apps, chat systems, live dashboards, streaming APIs, and any scenario requiring persistent bidirectional communication.

Both `ws://` (plain) and `wss://` (TLS) are supported out of the box.

### Client

```lua
local ws = net.ws.connect("wss://echo.websocket.org")

-- Send text (default)
ws:send("Hello!")

-- Send binary
ws:send("\x00\x01\x02\x03", "binary")

-- Receive messages
local msg = ws:recv()
if msg then
    print(msg.type, msg.data)
end

ws:close()
```

### Connection Options

Pass custom headers for authentication or a timeout for the connection:

```lua
local ws = net.ws.connect("ws://localhost:8080/chat", {
    headers = {
        ["Authorization"] = "Bearer my-token",
        ["X-Client-Id"] = "coppermoon-1",
    },
    timeout = 5000,  -- ms
})
```

### Message Format

`recv()` returns a table with a `type` field indicating the frame type:

| Type | Description | Fields |
|------|-------------|--------|
| `"text"` | Text frame | `data` = string |
| `"binary"` | Binary frame | `data` = binary string |
| `"ping"` | Ping frame | `data` = payload |
| `"pong"` | Pong frame | `data` = payload |
| `"close"` | Close frame | `data`, `code`, `reason` |

When the connection closes, `recv()` returns `nil`.

```lua
while true do
    local msg = ws:recv()
    if msg == nil then
        print("Connection closed")
        break
    end

    if msg.type == "text" then
        print("Text:", msg.data)
    elseif msg.type == "binary" then
        print("Binary:", #msg.data, "bytes")
    elseif msg.type == "close" then
        print("Close:", msg.code, msg.reason)
        break
    end
end
```

### WebSocket Server

Create a server that accepts WebSocket connections. The server handles the TCP listen and HTTP upgrade handshake automatically:

```lua
local server = net.ws.listen("127.0.0.1", 9001)
print("WebSocket server on", server:local_addr())

while true do
    local conn = server:accept()
    print("Client:", conn:peer_addr())

    -- Echo loop
    while true do
        local msg = conn:recv()
        if msg == nil or msg.type == "close" then break end
        conn:send(msg.data, msg.type)
    end
end
```

### Ping / Pong

WebSocket ping/pong frames are used for keep-alive. Pings from the remote peer are automatically answered by the library. You can also send pings manually:

```lua
ws:ping()            -- empty ping
ws:ping("heartbeat") -- ping with payload
ws:pong("data")      -- unsolicited pong
```

### Graceful Close

Initiate a close handshake with an optional status code and reason:

```lua
ws:close()                       -- default: code 1000 (Normal)
ws:close(1001, "Going Away")     -- custom close
```

After calling `close()`, continue calling `recv()` to complete the handshake until it returns `nil`.

## DNS Resolution

Resolve a hostname to a list of IP addresses:

```lua
local addrs = net.resolve("example.com")
for _, ip in ipairs(addrs) do
    print(ip)
end
-- "93.184.216.34"
-- "2606:2800:220:1:..."
```

## Usage Examples

### Simple Chat Server (WebSocket)

```lua
local clients = {}
local server = net.ws.listen(8080)
print("Chat server on", server:local_addr())

-- Accept loop (single-threaded, one client at a time for simplicity)
while true do
    local conn = server:accept()
    print("New client:", conn:peer_addr())

    while true do
        local msg = conn:recv()
        if msg == nil or msg.type == "close" then break end
        if msg.type == "text" then
            print("[" .. conn:peer_addr() .. "] " .. msg.data)
            conn:send("Echo: " .. msg.data)
        end
    end

    print("Client disconnected:", conn:peer_addr())
end
```

### TCP Port Scanner

```lua
local host = "127.0.0.1"
local ports = { 22, 80, 443, 3306, 5432, 6379, 8080 }

for _, port in ipairs(ports) do
    local ok = pcall(function()
        local conn = net.tcp.connect(host, port)
        conn:set_timeout(1000)
        conn:close()
    end)
    if ok then
        print(string.format("  %s:%d  OPEN", host, port))
    end
end
```

### UDP Service Discovery

```lua
local socket = net.udp.bind(0)
socket:set_broadcast(true)
socket:set_timeout(3000)

-- Broadcast discovery request
socket:send("DISCOVER", "255.255.255.255", 5000)

-- Collect responses
while true do
    local ok, data, host, port = pcall(socket.recv, socket)
    if not ok then break end  -- timeout
    print("Found service:", host .. ":" .. port, data)
end
```

### WebSocket with JSON Messages

```lua
local ws = net.ws.connect("ws://localhost:8080/api")

-- Send a JSON command
ws:send(json.encode({
    action = "subscribe",
    channel = "prices",
}))

-- Receive updates
while true do
    local msg = ws:recv()
    if msg == nil then break end
    if msg.type == "text" then
        local data = json.decode(msg.data)
        print(data.symbol, data.price)
    end
end

ws:close()
```

## Error Handling

All network operations raise Lua errors on failure. Use `pcall` to handle them gracefully:

```lua
local ok, err = pcall(function()
    local conn = net.tcp.connect("unreachable.host", 9999)
end)
if not ok then
    print("Connection failed:", err)
end
```

Common error scenarios:

- **Connection refused** — the remote host is not listening on that port
- **Connection timeout** — the host is unreachable or too slow
- **DNS resolution failure** — the hostname could not be resolved
- **Connection reset** — the remote peer closed the connection unexpectedly
- **WebSocket upgrade rejected** — the server refused the WebSocket handshake

For WebSocket recv timeouts, set a timeout and catch the error:

```lua
ws:set_timeout(5000)
local ok, result = pcall(ws.recv, ws)
if not ok then
    print("Recv timed out")
end
```

## Architecture

The `net` module is part of CopperMoon's standard library (`coppermoon_std`), implemented in Rust for performance and cross-platform compatibility.

- **TCP/UDP** use Rust's `std::net` types — zero external dependencies, works on all platforms
- **WebSocket** uses the `tungstenite` library with `native-tls` for TLS support — handles the full WebSocket protocol including frame encoding, masking, ping/pong, and close handshakes
- All APIs are **synchronous/blocking** — simple to use, no callbacks or async machinery needed
- Connection objects use `Arc<Mutex<>>` internally for safe shared access

## Next Steps

- [API Reference](/docs/net/api) — Complete function and method reference for TCP, UDP, and WebSocket
- [Buffer](/docs/buffer/overview) — Binary data manipulation for working with raw bytes
- [HTTP](/docs/coppermoon/overview) — Higher-level HTTP client and server
