# Operations

Beyond reading and writing, Buffer provides operations for slicing, copying, filling, concatenating, and encoding binary data.

## Slice

Create a new buffer from a byte range. Positions are 1-indexed and the end is exclusive:

```lua
local buf = buffer.from("Hello World")

local hello = buf:slice(1, 6)
print(hello:toString())         -- "Hello "

local world = buf:slice(7)      -- to end
print(world:toString())         -- "World"
```

The original buffer is not modified. The returned buffer is an independent copy.

## Copy

Copy bytes from one buffer to another:

```lua
local src = buffer.from("ABCDEF")
local dst = buffer.new(6)

-- Copy all bytes to dst
src:copy(dst)
print(dst:toString())           -- "ABCDEF"
```

With optional range parameters:

```lua
local src = buffer.from("ABCDEF")
local dst = buffer.new(10)

-- copy(target, targetStart, sourceStart, sourceEnd)
src:copy(dst, 3, 2, 5)
-- Copies bytes 2-4 (BCD) from src to dst starting at position 3
print(dst:get(3))               -- 66 (B)
print(dst:get(4))               -- 67 (C)
print(dst:get(5))               -- 68 (D)
```

If the target buffer is too small, it auto-grows:

```lua
local src = buffer.from("ABCDEF")
local dst = buffer.new(2)
src:copy(dst)
print(dst:len())                -- 6 (auto-grown)
```

## Fill

Fill a buffer range with a byte value:

```lua
local buf = buffer.new(8)

-- Fill entire buffer
buf:fill(0xFF)
print(buf:toHex())              -- ffffffffffffffff

-- Fill a range (positions 3-6)
buf:fill(0x00, 3, 6)
print(buf:toHex())              -- ffff00000000ffff
```

## Clear

Zero all bytes and reset the cursor to position 1:

```lua
local buf = buffer.from("sensitive data")
buf:clear()
print(buf:toHex())              -- 0000000000000000000000000000
print(buf:tell())               -- 1
```

## Concat

Concatenate multiple buffers into a new one:

```lua
local a = buffer.from("Hello")
local b = buffer.from(" ")
local c = buffer.from("World")

local joined = buffer.concat(a, b, c)
print(joined:toString())        -- "Hello World"
print(joined:len())             -- 11
```

The original buffers are not modified.

## Encoding

### Hex

```lua
local buf = buffer.from("Hello")
print(buf:toHex())              -- 48656c6c6f

-- Decode hex
local buf2 = buffer.fromHex("48656c6c6f")
print(buf2:toString())          -- Hello
```

### Base64

```lua
local buf = buffer.from("Hello World")
print(buf:toBase64())           -- SGVsbG8gV29ybGQ=

-- Decode base64
local buf2 = buffer.fromBase64("SGVsbG8gV29ybGQ=")
print(buf2:toString())          -- Hello World
```

### Raw String

`toString()` and `bytes()` both return the buffer as a Lua string. `bytes()` is an alias that makes intent clearer when working with raw binary data:

```lua
local buf = buffer.from("Hello")
print(buf:toString())           -- Hello
print(buf:bytes())              -- Hello (same)

-- Useful for passing raw bytes to other functions
local hash = crypto.sha256(buf:bytes())
```

## Practical Examples

### Reading a BMP file header

```lua
local data = fs.read("image.bmp")
local buf = buffer.from(data)

local signature = buf:readString(2)        -- "BM"
local fileSize  = buf:readUInt32LE()       -- total file size
buf:seek(11)                               -- skip to offset field
local dataOffset = buf:readUInt32LE()      -- pixel data offset
local headerSize = buf:readUInt32LE()      -- DIB header size
local width      = buf:readInt32LE()       -- image width
local height     = buf:readInt32LE()       -- image height

print(string.format("BMP: %dx%d, %d bytes", width, height, fileSize))
```

### Building a WAV header

```lua
local function wavHeader(sampleRate, channels, bitsPerSample, dataSize)
    local buf = buffer.new(0)

    -- RIFF header
    buf:writeString("RIFF")
    buf:writeUInt32LE(36 + dataSize)
    buf:writeString("WAVE")

    -- fmt chunk
    buf:writeString("fmt ")
    buf:writeUInt32LE(16)                    -- chunk size
    buf:writeUInt16LE(1)                     -- PCM format
    buf:writeUInt16LE(channels)
    buf:writeUInt32LE(sampleRate)
    local byteRate = sampleRate * channels * bitsPerSample / 8
    buf:writeUInt32LE(byteRate)
    buf:writeUInt16LE(channels * bitsPerSample / 8)
    buf:writeUInt16LE(bitsPerSample)

    -- data chunk header
    buf:writeString("data")
    buf:writeUInt32LE(dataSize)

    return buf
end
```

### Hex dump utility

```lua
local function hexDump(buf, bytesPerLine)
    bytesPerLine = bytesPerLine or 16
    for i = 1, buf:len(), bytesPerLine do
        local hex = {}
        local ascii = {}
        for j = 0, bytesPerLine - 1 do
            if i + j <= buf:len() then
                local byte = buf:get(i + j)
                hex[#hex + 1] = string.format("%02x", byte)
                ascii[#ascii + 1] = (byte >= 32 and byte < 127) and string.char(byte) or "."
            end
        end
        print(string.format("%08x  %-48s  %s", i - 1, table.concat(hex, " "), table.concat(ascii)))
    end
end

local buf = buffer.from("Hello, World! This is a hex dump test.")
hexDump(buf)
```

## Next Steps

- [API Reference](/docs/buffer/api) — Complete method reference
