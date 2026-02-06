# Archive

A complete compression and archive toolkit built into CopperMoon's standard library. The `archive` module provides ZIP and TAR/TAR.GZ support for reading, creating, and extracting archives, plus raw GZIP compression — all with a simple, synchronous API.

## Quick Start

### Create a ZIP

```lua
local z = archive.zip.create("backup.zip")
z:add("config.lua")
z:add_string("readme.txt", "Created by CopperMoon")
z:add_dir("src/")
z:close()
```

### Read a ZIP

```lua
local z = archive.zip.open("backup.zip")
for _, entry in ipairs(z:list()) do
    print(entry.name, entry.size)
end
local data = z:read("config.lua")
z:close()
```

### Create a TAR.GZ

```lua
local t = archive.tar.create("backup.tar.gz")
t:add("config.lua")
t:add_string("readme.txt", "Compressed archive")
t:add_dir("src/")
t:close()
```

### GZIP Compress/Decompress

```lua
local compressed = archive.gzip.compress("Hello, World!")
local original = archive.gzip.decompress(compressed)
```

## ZIP

ZIP is the most widely used archive format. It supports random access, per-file compression, and is natively understood by every operating system.

### Opening Archives

Open a ZIP from a file path:

```lua
local z = archive.zip.open("data.zip")
```

Open a ZIP from memory (binary string or Buffer), useful when receiving ZIP data over HTTP without writing to disk:

```lua
local response = http.get("https://example.com/data.zip")
local z = archive.zip.from_string(response.body)

-- Also works with Buffer objects
local buf = buffer.from(response.body)
local z = archive.zip.from_buffer(buf)
```

Both `from_string` and `from_buffer` accept either a string or a Buffer, and return the same `ZipReader` object with identical methods.

### Listing Entries

```lua
local entries = z:list()
for _, entry in ipairs(entries) do
    print(string.format("%s  %d bytes (compressed: %d)  dir: %s",
        entry.name, entry.size, entry.compressed_size, tostring(entry.is_dir)))
end
```

Each entry is a table with:

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Full path inside the archive |
| `size` | number | Uncompressed size in bytes |
| `compressed_size` | number | Compressed size in bytes |
| `is_dir` | boolean | Whether the entry is a directory |

### Reading Files

Read a specific file by its path inside the archive:

```lua
local content = z:read("src/main.lua")
print(content)
```

Binary data is returned as-is (Lua strings are binary-safe):

```lua
local image = z:read("assets/logo.png")
fs.write("logo.png", image)
```

Use `read_buffer` to get a Buffer object instead:

```lua
local buf = z:read_buffer("assets/logo.png")
print(buf:len())       -- size in bytes
print(buf:toHex())     -- hex representation
```

### Checking Existence

```lua
if z:exists("config.json") then
    local config = json.decode(z:read("config.json"))
end
```

### Extracting

Extract the entire archive to a directory:

```lua
z:extract("output/")
```

Extract only specific files:

```lua
z:extract("output/", {"readme.txt", "src/main.lua"})
```

Parent directories are created automatically. Path traversal attacks (`../`) are detected and rejected.

### Creating Archives

```lua
local z = archive.zip.create("release.zip")

-- Add a file from disk (uses filename as archive name)
z:add("build/app.lua")

-- Add a file with a custom name inside the archive
z:add("build/app.lua", "app.lua")

-- Add content directly from a string (or Buffer)
z:add_string("version.txt", "1.0.0")
z:add_string("data/config.json", json.encode({ debug = false }))

-- Add content from a Buffer object
local buf = buffer.from("binary data here")
z:add_data("raw.bin", buf)

-- Add an entire directory recursively
z:add_dir("assets/")

-- Add a directory with a prefix
z:add_dir("build/static", "public")
-- "build/static/style.css" becomes "public/style.css" in the ZIP

-- Finalize and close (writes the central directory)
z:close()
```

All files are compressed with Deflate. Path separators are normalized to `/` for cross-platform compatibility.

### Closing

Always call `close()` when done:

```lua
z:close()
```

For readers, this releases the file handle. For writers, this finalizes the archive by writing the ZIP central directory — without it, the ZIP file will be corrupt.

## TAR

TAR (Tape Archive) is the standard Unix archive format. Combined with GZIP compression (`.tar.gz` or `.tgz`), it's the most common format for distributing source code and backups on Linux/macOS.

### Opening Archives

The module auto-detects GZIP compression from the file extension:

```lua
local t = archive.tar.open("backup.tar.gz")  -- gzipped
local t = archive.tar.open("backup.tgz")     -- gzipped
local t = archive.tar.open("backup.tar")     -- plain tar
```

### Listing Entries

```lua
local entries = t:list()
for _, entry in ipairs(entries) do
    print(string.format("%s  %d bytes  dir: %s",
        entry.name, entry.size, tostring(entry.is_dir)))
end
```

Each entry is a table with:

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Full path inside the archive |
| `size` | number | File size in bytes |
| `is_dir` | boolean | Whether the entry is a directory |

### Reading Files

```lua
local content = t:read("src/main.lua")
```

Use `read_buffer` to get a Buffer object instead:

```lua
local buf = t:read_buffer("data.bin")
```

> Note: TAR is a sequential format. Each `read()` / `read_buffer()` call scans from the beginning of the archive. For reading many files, consider extracting to disk instead.

### Extracting

```lua
t:extract("output/")
```

Extracts all files, creating directories as needed.

### Creating Archives

The module auto-detects whether to use GZIP compression from the file extension:

```lua
local t = archive.tar.create("backup.tar.gz")  -- gzipped
local t = archive.tar.create("backup.tar")     -- plain tar
```

Adding files works the same as ZIP:

```lua
-- Add a file from disk
t:add("config.lua")
t:add("config.lua", "etc/config.lua")  -- custom name

-- Add content from a string (or Buffer)
t:add_string("readme.txt", "Hello from CopperMoon")

-- Add content from a Buffer
local buf = buffer.from("binary payload")
t:add_data("payload.bin", buf)

-- Add a directory recursively
t:add_dir("src/")

-- Finalize and close
t:close()
```

### Closing

```lua
t:close()
```

For writers, this writes the TAR end-of-archive marker and (for `.tar.gz`) flushes the GZIP footer. Without it, the archive will be incomplete.

## GZIP

Raw GZIP compression and decompression for arbitrary data. Useful for compressing strings, HTTP responses, or any binary data without the archive structure.

### Compress

```lua
local compressed = archive.gzip.compress("Hello, World!")
print(#compressed)  -- much smaller for repetitive data
```

With a custom compression level (0 = no compression, 9 = maximum):

```lua
local fast = archive.gzip.compress(data, { level = 1 })
local best = archive.gzip.compress(data, { level = 9 })
```

The default level is 6 (balanced speed/size).

### Decompress

```lua
local original = archive.gzip.decompress(compressed)
```

### Buffer Variants

Use `compress_buffer` and `decompress_buffer` to work with Buffer objects:

```lua
local compressed_buf = archive.gzip.compress_buffer(data)
print(compressed_buf:len())  -- compressed size

local decompressed_buf = archive.gzip.decompress_buffer(compressed_buf:toString())
assert(decompressed_buf:toString() == data)
```

All GZIP functions accept both strings and Buffers as input.

### Round-Trip Example

```lua
local data = string.rep("CopperMoon ", 1000)
print("Original:", #data)

local compressed = archive.gzip.compress(data)
print("Compressed:", #compressed)

local restored = archive.gzip.decompress(compressed)
assert(restored == data, "Round-trip failed!")
print("Match: true")
```

## Usage Examples

### Package Distribution

```lua
-- Create a release package
local z = archive.zip.create("myapp-1.0.0.zip")
z:add_string("package.json", json.encode({
    name = "myapp",
    version = "1.0.0",
}))
z:add_dir("src/", "myapp/src")
z:add_dir("assets/", "myapp/assets")
z:add("README.md", "myapp/README.md")
z:close()
```

### Analyze a Downloaded ZIP

```lua
-- Download and inspect without writing to disk
local resp = http.get("https://example.com/data.zip")
local z = archive.zip.from_string(resp.body)

local entries = z:list()
print("Archive contains " .. #entries .. " files")

-- Read specific files
if z:exists("manifest.json") then
    local manifest = json.decode(z:read("manifest.json"))
    print("Package:", manifest.name, "v" .. manifest.version)
end

z:close()
```

### Backup and Restore

```lua
-- Backup
local t = archive.tar.create("backup-" .. os.date("%Y%m%d") .. ".tar.gz")
t:add_dir("data/")
t:add_dir("config/")
t:close()

-- Restore
local t = archive.tar.open("backup-20250101.tar.gz")
t:extract("restored/")
t:close()
```

### Compress HTTP Response Data

```lua
local data = json.encode(largeDataset)
local compressed = archive.gzip.compress(data)
-- Send compressed data over the network, decompress on the other end
```

## Buffer Integration

All archive APIs support Buffer objects alongside strings, making it easy to work with binary data:

| Method | Description |
|--------|-------------|
| `z:read_buffer(name)` | Read a ZIP entry as a Buffer |
| `t:read_buffer(name)` | Read a TAR entry as a Buffer |
| `z:add_data(name, data)` | Add string or Buffer to ZIP |
| `t:add_data(name, data)` | Add string or Buffer to TAR |
| `archive.zip.from_buffer(data)` | Open ZIP from Buffer |
| `archive.gzip.compress_buffer(data)` | Compress to Buffer |
| `archive.gzip.decompress_buffer(data)` | Decompress to Buffer |

`add_string`, `from_string`, `compress`, and `decompress` also accept Buffer objects as input.

### Example: Process ZIP from HTTP without disk I/O

```lua
local resp = http.get("https://example.com/data.zip")
local z = archive.zip.from_string(resp.body)

-- Read a binary file as a Buffer for processing
local image_buf = z:read_buffer("assets/photo.png")
print("Image size:", image_buf:len(), "bytes")
z:close()
```

## Error Handling

All archive operations raise Lua errors on failure. Use `pcall` for graceful handling:

```lua
local ok, err = pcall(function()
    local z = archive.zip.open("nonexistent.zip")
end)
if not ok then
    print("Error:", err)
end
```

Common error scenarios:

- **File not found** — the archive path doesn't exist
- **Invalid archive** — the file is not a valid ZIP or TAR
- **Entry not found** — `read()` with a name that doesn't exist in the archive
- **Already closed** — calling methods on a closed reader/writer
- **Path traversal** — ZIP extract detects `../` escape attempts
- **Write failure** — disk full or permission denied

## Architecture

The `archive` module is part of CopperMoon's standard library (`coppermoon_std`), implemented in Rust.

- **ZIP** uses the `zip` crate — supports Deflate compression, random access by name or index
- **TAR** uses the `tar` crate — sequential reading/writing, standard GNU tar format
- **GZIP** uses the `flate2` crate — fast compression/decompression with configurable levels
- **In-memory ZIP** uses `Cursor<Vec<u8>>` to wrap binary data as a seekable reader
- All APIs are **synchronous/blocking** — simple to use, no callbacks needed
- Reader/writer objects use `Mutex<Option<>>` internally for safe state management

## Next Steps

- [API Reference](/docs/archive/api) — Complete function and method reference
- [Buffer](/docs/buffer/overview) — Binary data manipulation for working with raw bytes
- [Network](/docs/net/overview) — TCP, UDP, and WebSocket networking
