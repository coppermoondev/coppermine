# API Reference

Complete reference for the `buffer` module. All positions are **1-indexed**.

---

## Module Functions

### buffer.new(size)

Create a zero-filled buffer of the given size.

| Parameter | Type | Description |
|-----------|------|-------------|
| `size` | `number` | Number of bytes to allocate |

**Returns:** `Buffer`

```lua
local buf = buffer.new(16)
print(buf:len())    -- 16
print(buf:get(1))   -- 0
```

---

### buffer.from(data)

Create a buffer from a Lua string (including binary data).

| Parameter | Type | Description |
|-----------|------|-------------|
| `data` | `string` | Source string |

**Returns:** `Buffer`

```lua
local buf = buffer.from("Hello")
print(buf:len())         -- 5
print(buf:toString())    -- Hello
```

---

### buffer.fromHex(hex)

Decode a hex string into a buffer.

| Parameter | Type | Description |
|-----------|------|-------------|
| `hex` | `string` | Hexadecimal string (e.g. `"48656c6c6f"`) |

**Returns:** `Buffer`

**Throws:** Error if the string contains invalid hex characters or has odd length.

```lua
local buf = buffer.fromHex("48656c6c6f")
print(buf:toString())    -- Hello
```

---

### buffer.fromBase64(b64)

Decode a Base64 string into a buffer.

| Parameter | Type | Description |
|-----------|------|-------------|
| `b64` | `string` | Base64-encoded string |

**Returns:** `Buffer`

**Throws:** Error if the string is not valid Base64.

```lua
local buf = buffer.fromBase64("SGVsbG8gV29ybGQ=")
print(buf:toString())    -- Hello World
```

---

### buffer.alloc(size, fill?)

Allocate a buffer with an optional fill byte.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `size` | `number` | | Number of bytes to allocate |
| `fill` | `number` | `0` | Byte value to fill with (0-255) |

**Returns:** `Buffer`

```lua
local buf = buffer.alloc(4, 0xFF)
print(buf:toHex())    -- ffffffff
```

---

### buffer.concat(...)

Concatenate multiple buffers into a new buffer. The originals are not modified.

| Parameter | Type | Description |
|-----------|------|-------------|
| `...` | `Buffer` | One or more Buffer objects |

**Returns:** `Buffer`

**Throws:** Error if any argument is not a Buffer.

```lua
local a = buffer.from("Hello")
local b = buffer.from(" World")
local c = buffer.concat(a, b)
print(c:toString())    -- Hello World
```

---

### buffer.isBuffer(value)

Check whether a value is a Buffer.

| Parameter | Type | Description |
|-----------|------|-------------|
| `value` | `any` | Value to check |

**Returns:** `boolean`

```lua
print(buffer.isBuffer(buffer.new(4)))   -- true
print(buffer.isBuffer("hello"))         -- false
print(buffer.isBuffer(42))             -- false
```

---

## Cursor Management

The cursor tracks the current read/write position. It starts at position 1 and advances automatically after each read or write operation.

### buf:tell()

Get the current cursor position (1-indexed).

**Returns:** `number`

```lua
local buf = buffer.new(8)
print(buf:tell())          -- 1
buf:writeUInt8(0xFF)
print(buf:tell())          -- 2
```

---

### buf:seek(pos)

Set the cursor to a specific position.

| Parameter | Type | Description |
|-----------|------|-------------|
| `pos` | `number` | New cursor position (1-indexed, must be >= 1 and <= length + 1) |

**Throws:** Error if the position is out of range.

```lua
local buf = buffer.from("ABCDEF")
buf:seek(3)
print(buf:readString(1))   -- C
```

---

### buf:reset()

Reset the cursor to position 1.

```lua
local buf = buffer.from("Hello")
buf:seek(4)
buf:reset()
print(buf:tell())    -- 1
```

---

### buf:len()

Get the number of bytes in the buffer.

**Returns:** `number`

```lua
local buf = buffer.from("Hello")
print(buf:len())    -- 5
print(#buf)         -- 5 (same, via __len metamethod)
```

---

### buf:capacity()

Get the allocated capacity (may be >= length).

**Returns:** `number`

```lua
local buf = buffer.new(8)
print(buf:capacity())    -- >= 8
```

---

## Read Methods

All read methods read from the current cursor position and advance the cursor by the number of bytes consumed. They throw an error if there are not enough bytes remaining.

### Integer Reads

| Method | Bytes | Range | Description |
|--------|-------|-------|-------------|
| `readUInt8()` | 1 | 0 to 255 | Unsigned 8-bit integer |
| `readInt8()` | 1 | -128 to 127 | Signed 8-bit integer |
| `readUInt16LE()` | 2 | 0 to 65535 | Unsigned 16-bit, little-endian |
| `readUInt16BE()` | 2 | 0 to 65535 | Unsigned 16-bit, big-endian |
| `readInt16LE()` | 2 | -32768 to 32767 | Signed 16-bit, little-endian |
| `readInt16BE()` | 2 | -32768 to 32767 | Signed 16-bit, big-endian |
| `readUInt32LE()` | 4 | 0 to 4294967295 | Unsigned 32-bit, little-endian |
| `readUInt32BE()` | 4 | 0 to 4294967295 | Unsigned 32-bit, big-endian |
| `readInt32LE()` | 4 | -2^31 to 2^31-1 | Signed 32-bit, little-endian |
| `readInt32BE()` | 4 | -2^31 to 2^31-1 | Signed 32-bit, big-endian |
| `readInt64LE()` | 8 | -2^63 to 2^63-1 | Signed 64-bit, little-endian |
| `readInt64BE()` | 8 | -2^63 to 2^63-1 | Signed 64-bit, big-endian |

**Returns:** `number` (integer)

```lua
local buf = buffer.new(0)
buf:writeUInt16LE(1024)
buf:seek(1)
print(buf:readUInt16LE())    -- 1024
```

### Float Reads

| Method | Bytes | Description |
|--------|-------|-------------|
| `readFloatLE()` | 4 | 32-bit IEEE 754 float, little-endian |
| `readFloatBE()` | 4 | 32-bit IEEE 754 float, big-endian |
| `readDoubleLE()` | 8 | 64-bit IEEE 754 double, little-endian |
| `readDoubleBE()` | 8 | 64-bit IEEE 754 double, big-endian |

**Returns:** `number` (float)

```lua
local buf = buffer.new(0)
buf:writeDoubleLE(3.14159)
buf:seek(1)
print(buf:readDoubleLE())    -- 3.14159
```

### String Read

### buf:readString(len)

Read `len` bytes from the cursor and return them as a Lua string.

| Parameter | Type | Description |
|-----------|------|-------------|
| `len` | `number` | Number of bytes to read |

**Returns:** `string`

**Throws:** Error if not enough bytes remaining.

```lua
local buf = buffer.from("Hello World")
print(buf:readString(5))    -- Hello
print(buf:readString(1))    -- " "
print(buf:readString(5))    -- World
```

---

## Write Methods

All write methods write at the current cursor position and advance the cursor. If the write extends past the end of the buffer, the buffer is automatically grown.

### Integer Writes

| Method | Bytes | Description |
|--------|-------|-------------|
| `writeUInt8(value)` | 1 | Unsigned 8-bit integer |
| `writeInt8(value)` | 1 | Signed 8-bit integer |
| `writeUInt16LE(value)` | 2 | Unsigned 16-bit, little-endian |
| `writeUInt16BE(value)` | 2 | Unsigned 16-bit, big-endian |
| `writeInt16LE(value)` | 2 | Signed 16-bit, little-endian |
| `writeInt16BE(value)` | 2 | Signed 16-bit, big-endian |
| `writeUInt32LE(value)` | 4 | Unsigned 32-bit, little-endian |
| `writeUInt32BE(value)` | 4 | Unsigned 32-bit, big-endian |
| `writeInt32LE(value)` | 4 | Signed 32-bit, little-endian |
| `writeInt32BE(value)` | 4 | Signed 32-bit, big-endian |
| `writeInt64LE(value)` | 8 | Signed 64-bit, little-endian |
| `writeInt64BE(value)` | 8 | Signed 64-bit, big-endian |

All take a single `number` parameter and return nothing.

```lua
local buf = buffer.new(0)
buf:writeUInt8(0xFF)
buf:writeUInt32LE(12345)
print(buf:len())    -- 5
```

### Float Writes

| Method | Bytes | Description |
|--------|-------|-------------|
| `writeFloatLE(value)` | 4 | 32-bit IEEE 754 float, little-endian |
| `writeFloatBE(value)` | 4 | 32-bit IEEE 754 float, big-endian |
| `writeDoubleLE(value)` | 8 | 64-bit IEEE 754 double, little-endian |
| `writeDoubleBE(value)` | 8 | 64-bit IEEE 754 double, big-endian |

All take a single `number` parameter and return nothing.

```lua
local buf = buffer.new(0)
buf:writeFloatLE(1.5)
buf:writeDoubleBE(3.14)
print(buf:len())    -- 12
```

### String Write

### buf:writeString(str)

Write the bytes of a string at the cursor position.

| Parameter | Type | Description |
|-----------|------|-------------|
| `str` | `string` | String to write |

**Returns:** `number` — the number of bytes written.

```lua
local buf = buffer.new(0)
local n = buf:writeString("RIFF")
print(n)            -- 4
print(buf:len())    -- 4
```

---

## Byte Access

### buf:get(index)

Get the byte value at a 1-indexed position. Does not affect the cursor.

| Parameter | Type | Description |
|-----------|------|-------------|
| `index` | `number` | Position (1-indexed) |

**Returns:** `number` (0-255)

**Throws:** Error if index is out of range.

```lua
local buf = buffer.from("ABC")
print(buf:get(1))    -- 65 (A)
print(buf:get(2))    -- 66 (B)
```

---

### buf:set(index, value)

Set the byte value at a 1-indexed position. Does not affect the cursor.

| Parameter | Type | Description |
|-----------|------|-------------|
| `index` | `number` | Position (1-indexed) |
| `value` | `number` | Byte value (0-255) |

**Throws:** Error if index is out of range.

```lua
local buf = buffer.from("ABC")
buf:set(1, 0x5A)         -- Z
print(buf:toString())    -- ZBC
```

---

## Buffer Operations

### buf:slice(start, end?)

Create a new independent buffer from a byte range.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `start` | `number` | | Start position (1-indexed, inclusive) |
| `end` | `number` | `buf:len()` | End position (exclusive) |

**Returns:** `Buffer` — a new buffer (independent copy).

**Throws:** Error if range is out of bounds.

```lua
local buf = buffer.from("Hello World")
local hello = buf:slice(1, 6)
print(hello:toString())    -- "Hello "
```

---

### buf:copy(target, targetStart?, sourceStart?, sourceEnd?)

Copy bytes from this buffer into another buffer.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `target` | `Buffer` | | Destination buffer |
| `targetStart` | `number` | `1` | Write position in target (1-indexed) |
| `sourceStart` | `number` | `1` | Start position in source (1-indexed) |
| `sourceEnd` | `number` | `buf:len()` | End position in source (exclusive) |

**Returns:** `number` — the number of bytes copied.

If the target buffer is too small, it is automatically grown.

```lua
local src = buffer.from("ABCDEF")
local dst = buffer.new(6)
src:copy(dst)
print(dst:toString())    -- ABCDEF

-- Partial copy
local dst2 = buffer.new(10)
src:copy(dst2, 3, 2, 5)
print(dst2:get(3))       -- 66 (B)
```

---

### buf:fill(value, start?, end?)

Fill a range with a byte value.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `value` | `number` | | Byte value (0-255) |
| `start` | `number` | `1` | Start position (1-indexed, inclusive) |
| `end` | `number` | `buf:len()` | End position (exclusive) |

```lua
local buf = buffer.new(8)
buf:fill(0xFF)
print(buf:toHex())        -- ffffffffffffffff

buf:fill(0x00, 3, 6)
print(buf:toHex())        -- ffff00000000ffff
```

---

### buf:clear()

Zero all bytes and reset the cursor to position 1.

```lua
local buf = buffer.from("secret")
buf:clear()
print(buf:toHex())     -- 000000000000
print(buf:tell())      -- 1
```

---

## Encoding & Conversion

### buf:toString()

Return the buffer contents as a Lua string.

**Returns:** `string`

```lua
local buf = buffer.from("Hello")
print(buf:toString())    -- Hello
```

---

### buf:bytes()

Alias for `toString()`. Returns the buffer contents as a raw Lua string. Use this when the intent is to pass binary data (makes code more readable).

**Returns:** `string`

```lua
local buf = buffer.from("Hello")
local raw = buf:bytes()
local hash = crypto.sha256(raw)
```

---

### buf:toHex()

Encode the buffer contents as a lowercase hexadecimal string.

**Returns:** `string`

```lua
local buf = buffer.from("Hi")
print(buf:toHex())    -- 4869
```

---

### buf:toBase64()

Encode the buffer contents as a Base64 string.

**Returns:** `string`

```lua
local buf = buffer.from("Hello World")
print(buf:toBase64())    -- SGVsbG8gV29ybGQ=
```

---

## Metamethods

### __len

The `#` operator returns the buffer length.

```lua
local buf = buffer.new(16)
print(#buf)    -- 16
```

### __tostring

`tostring()` returns a description string (not the buffer contents).

```lua
local buf = buffer.new(32)
print(tostring(buf))    -- Buffer(32 bytes)
```

---

## Error Handling

Buffer methods throw errors in the following cases:

| Error | Cause |
|-------|-------|
| Buffer underflow | Reading past the end of the buffer |
| Index out of range | `get()` or `set()` with an invalid position |
| Seek out of range | `seek()` with a position < 1 or > length + 1 |
| Slice out of range | `slice()` with invalid start/end |
| Copy out of bounds | `copy()` with invalid source range |
| Invalid hex | `buffer.fromHex()` with non-hex characters or odd length |
| Invalid Base64 | `buffer.fromBase64()` with invalid encoding |
| Type error | `buffer.concat()` with non-Buffer arguments |

Use `pcall` to handle errors gracefully:

```lua
local ok, err = pcall(function()
    local buf = buffer.new(4)
    buf:seek(10)    -- out of range!
end)

if not ok then
    print("Error: " .. err)
end
```
