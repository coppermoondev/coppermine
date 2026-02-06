# Getting Started

Buffer is a global module — no `require()` needed. It provides factory functions to create buffers and a `Buffer` object with methods for reading, writing, and manipulating binary data.

## Creating Buffers

### Zero-filled buffer

```lua
local buf = buffer.new(64)    -- 64 zero bytes
print(#buf)                    -- 64
print(tostring(buf))           -- Buffer(64 bytes)
```

### From a string

```lua
local buf = buffer.from("Hello World")
print(buf:len())               -- 11
print(buf:toString())          -- Hello World
```

### From hex or base64

```lua
local buf1 = buffer.fromHex("48656C6C6F")
print(buf1:toString())         -- Hello

local buf2 = buffer.fromBase64("SGVsbG8gV29ybGQ=")
print(buf2:toString())         -- Hello World
```

### Pre-filled buffer

```lua
local buf = buffer.alloc(8, 0xFF)
print(buf:toHex())             -- ffffffffffffffff
```

## The Cursor Model

Every buffer has an internal cursor that tracks the current read/write position. All `readXxx()` and `writeXxx()` methods advance the cursor by the number of bytes consumed.

```lua
local buf = buffer.new(16)

-- Cursor starts at position 1 (Lua convention)
print(buf:tell())              -- 1

-- Writing advances the cursor
buf:writeUInt32LE(42)          -- writes 4 bytes
print(buf:tell())              -- 5

buf:writeUInt16BE(100)         -- writes 2 bytes
print(buf:tell())              -- 7

-- Seek back to read
buf:seek(1)
print(buf:readUInt32LE())      -- 42
print(buf:readUInt16BE())      -- 100

-- Reset to beginning
buf:reset()
print(buf:tell())              -- 1
```

## Auto-Growing

Writes past the end of the buffer automatically expand it. You can start with an empty buffer and build data incrementally:

```lua
local buf = buffer.new(0)      -- start empty
buf:writeUInt8(1)
buf:writeUInt16LE(2)
buf:writeString("hello")
print(buf:len())               -- 8 (1 + 2 + 5)
```

## Read Underflow

Reading past the end of the buffer returns a clear error:

```lua
local buf = buffer.new(2)

-- This throws: "Buffer underflow: need 4 bytes at position 1, but only 2 available"
buf:readUInt32LE()
```

## Byte Access

Access individual bytes by 1-indexed position without moving the cursor:

```lua
local buf = buffer.from("ABCD")
print(buf:get(1))              -- 65 (A)
print(buf:get(4))              -- 68 (D)

buf:set(1, 90)                 -- Z = 90
print(buf:toString())          -- ZBCD
```

## Type Checking

```lua
print(buffer.isBuffer(buffer.new(0)))   -- true
print(buffer.isBuffer("hello"))         -- false
print(buffer.isBuffer(42))              -- false
```

## Length Operator

The `#` operator returns the buffer size:

```lua
local buf = buffer.new(32)
print(#buf)                    -- 32
```

## Next Steps

- [Reading & Writing](/docs/buffer/reading-writing) — Integer and float I/O with endianness
- [Operations](/docs/buffer/operations) — Slice, copy, fill, encode
- [API Reference](/docs/buffer/api) — Complete method reference
