# Buffer

Buffer is CopperMoon's built-in module for binary data manipulation. It provides a cursor-based byte buffer with read/write operations for integers, floats, and strings in both little-endian and big-endian byte orders.

## Features

- **Cursor-based I/O** — sequential read/write with automatic position tracking
- **Endianness control** — little-endian and big-endian for all integer and float types
- **Full numeric range** — UInt8, Int8, UInt16, Int16, UInt32, Int32, Int64, Float, Double
- **Auto-growing** — writes past the end automatically expand the buffer
- **Encoding utilities** — hex, base64, and raw string conversion
- **Buffer operations** — slice, copy, fill, concat, clear
- **1-indexed** — follows Lua convention for all position arguments
- **Zero dependencies** — built into the CopperMoon runtime in Rust

## Quick Start

```lua
-- Create a buffer and write binary data
local buf = buffer.new(0)
buf:writeUInt8(0x01)          -- protocol version
buf:writeUInt16BE(0x0042)     -- message type
buf:writeUInt32BE(5)          -- payload length
buf:writeString("Hello")     -- payload

-- Read it back
buf:seek(1)
print(buf:readUInt8())        -- 1
print(buf:readUInt16BE())     -- 66
local len = buf:readUInt32BE()
print(buf:readString(len))    -- "Hello"
```

## Use Cases

- **Binary protocols** — parse and build network protocol messages
- **File formats** — read and write binary file formats (PNG, WAV, etc.)
- **Serialization** — pack/unpack structured binary data
- **Cryptography** — manipulate raw bytes for hashing and encryption
- **Data conversion** — convert between hex, base64, and raw binary

## Architecture

Buffer is implemented as a Rust `UserData` type exposed to Lua. All read/write operations go through Rust's `from_le_bytes`/`to_le_bytes` family of functions, ensuring correctness and performance. The buffer auto-grows on writes (like Rust's `Vec<u8>`) and returns clear error messages on read underflow.

```
buffer.new(size) -> Buffer UserData
                      |
                      +-- data: Vec<u8>     (byte storage)
                      +-- position: usize   (cursor offset)
                      |
                      +-- readXxx() / writeXxx()  (advance cursor)
                      +-- get(i) / set(i, v)      (random access)
                      +-- toHex() / toBase64()    (encoding)
```

## Next Steps

- [Getting Started](/docs/buffer/getting-started) — Create buffers and learn the cursor model
- [Reading & Writing](/docs/buffer/reading-writing) — Endianness, integer and float I/O
- [Operations](/docs/buffer/operations) — Slice, copy, fill, encode, and more
- [API Reference](/docs/buffer/api) — Complete method reference
