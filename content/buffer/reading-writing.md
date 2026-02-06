# Reading & Writing

Buffer provides typed read/write methods for integers and floats in both little-endian (LE) and big-endian (BE) byte orders. All methods advance the cursor.

## Endianness

**Little-endian (LE)** stores the least significant byte first. Used by x86/x64 processors and most file formats on desktop.

**Big-endian (BE)** stores the most significant byte first. Used by network protocols (TCP/IP), Java, and many binary formats.

```lua
local buf = buffer.new(4)

-- Little-endian: 0x0102 stored as [0x02, 0x01]
buf:writeUInt16LE(0x0102)
print(buf:get(1))   -- 2 (low byte first)
print(buf:get(2))   -- 1 (high byte second)

-- Big-endian: 0x0102 stored as [0x01, 0x02]
buf:writeUInt16BE(0x0102)
print(buf:get(3))   -- 1 (high byte first)
print(buf:get(4))   -- 2 (low byte second)
```

## Integer Types

### 8-bit (1 byte)

```lua
buf:writeUInt8(255)       -- unsigned: 0-255
buf:writeInt8(-128)       -- signed: -128 to 127

buf:seek(1)
buf:readUInt8()           -- 255
buf:readInt8()            -- -128
```

### 16-bit (2 bytes)

```lua
buf:writeUInt16LE(65535)  -- unsigned LE: 0-65535
buf:writeUInt16BE(1024)   -- unsigned BE
buf:writeInt16LE(-256)    -- signed LE: -32768 to 32767
buf:writeInt16BE(-1000)   -- signed BE
```

### 32-bit (4 bytes)

```lua
buf:writeUInt32LE(305419896)   -- unsigned LE: 0-4294967295
buf:writeUInt32BE(305419896)   -- unsigned BE
buf:writeInt32LE(-42)          -- signed LE: -2147483648 to 2147483647
buf:writeInt32BE(-100000)      -- signed BE
```

### 64-bit (8 bytes)

```lua
buf:writeInt64LE(1234567890123)   -- signed LE
buf:writeInt64BE(-9876543210)     -- signed BE
```

> Note: Lua 5.4 integers are 64-bit signed, so `Int64` covers the full range. There is no `UInt64` because Lua integers cannot represent values above 2^63-1.

## Floating Point

### Float (32-bit, 4 bytes)

Single-precision IEEE 754. About 7 decimal digits of precision.

```lua
buf:writeFloatLE(3.14)
buf:writeFloatBE(2.71828)

buf:seek(1)
print(buf:readFloatLE())    -- 3.14 (approximately)
print(buf:readFloatBE())    -- 2.71828 (approximately)
```

### Double (64-bit, 8 bytes)

Double-precision IEEE 754. About 15-17 decimal digits of precision. This is the native Lua number type.

```lua
buf:writeDoubleLE(math.pi)
buf:writeDoubleBE(1.23456789e100)

buf:seek(1)
print(buf:readDoubleLE())   -- 3.1415926535898
print(buf:readDoubleBE())   -- 1.23456789e+100
```

## Strings

Write and read raw byte strings at the cursor position:

```lua
local buf = buffer.new(0)
buf:writeString("Hello")       -- writes 5 bytes, returns 5
buf:writeString(" World")      -- writes 6 bytes, returns 6

buf:seek(1)
print(buf:readString(5))       -- "Hello"
print(buf:readString(6))       -- " World"
```

## Building a Binary Protocol

A typical pattern for binary protocols — write a header with type and length, then the payload:

```lua
-- Write packet
local function writePacket(msgType, payload)
    local buf = buffer.new(0)
    buf:writeUInt8(1)                   -- version
    buf:writeUInt16BE(msgType)          -- message type
    buf:writeUInt32BE(#payload)         -- payload length
    buf:writeString(payload)            -- payload data
    return buf
end

-- Read packet
local function readPacket(buf)
    buf:seek(1)
    local version = buf:readUInt8()
    local msgType = buf:readUInt16BE()
    local length  = buf:readUInt32BE()
    local payload = buf:readString(length)
    return { version = version, type = msgType, payload = payload }
end

local pkt = writePacket(0x01, "Hello Server")
local data = readPacket(pkt)
print(data.payload)   -- "Hello Server"
```

## Mixed Types

You can freely mix different types in the same buffer:

```lua
local buf = buffer.new(0)
buf:writeUInt8(1)               -- 1 byte
buf:writeUInt16BE(42)           -- 2 bytes
buf:writeDoubleLE(3.14)         -- 8 bytes
buf:writeString("OK")           -- 2 bytes
print(buf:len())                -- 13

buf:seek(1)
print(buf:readUInt8())          -- 1
print(buf:readUInt16BE())       -- 42
print(buf:readDoubleLE())       -- 3.14
print(buf:readString(2))        -- "OK"
```

## Complete Read/Write Method Table

| Read | Write | Bytes | Type |
|------|-------|-------|------|
| `readUInt8()` | `writeUInt8(v)` | 1 | Unsigned 8-bit |
| `readInt8()` | `writeInt8(v)` | 1 | Signed 8-bit |
| `readUInt16LE()` | `writeUInt16LE(v)` | 2 | Unsigned 16-bit LE |
| `readUInt16BE()` | `writeUInt16BE(v)` | 2 | Unsigned 16-bit BE |
| `readInt16LE()` | `writeInt16LE(v)` | 2 | Signed 16-bit LE |
| `readInt16BE()` | `writeInt16BE(v)` | 2 | Signed 16-bit BE |
| `readUInt32LE()` | `writeUInt32LE(v)` | 4 | Unsigned 32-bit LE |
| `readUInt32BE()` | `writeUInt32BE(v)` | 4 | Unsigned 32-bit BE |
| `readInt32LE()` | `writeInt32LE(v)` | 4 | Signed 32-bit LE |
| `readInt32BE()` | `writeInt32BE(v)` | 4 | Signed 32-bit BE |
| `readInt64LE()` | `writeInt64LE(v)` | 8 | Signed 64-bit LE |
| `readInt64BE()` | `writeInt64BE(v)` | 8 | Signed 64-bit BE |
| `readFloatLE()` | `writeFloatLE(v)` | 4 | Float 32-bit LE |
| `readFloatBE()` | `writeFloatBE(v)` | 4 | Float 32-bit BE |
| `readDoubleLE()` | `writeDoubleLE(v)` | 8 | Double 64-bit LE |
| `readDoubleBE()` | `writeDoubleBE(v)` | 8 | Double 64-bit BE |
| `readString(n)` | `writeString(s)` | n | Raw bytes |

## Next Steps

- [Operations](/docs/buffer/operations) — Slice, copy, fill, encode
- [API Reference](/docs/buffer/api) — Complete method reference
