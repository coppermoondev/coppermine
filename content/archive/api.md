# API Reference

Complete API reference for the CopperMoon `archive` module — ZIP, TAR/TAR.GZ, and GZIP.

## ZIP

### `archive.zip.open(path)`

Open a ZIP archive from a file on disk.

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Path to the ZIP file |

**Returns:** ZipReader object

**Raises:** error if file not found or invalid ZIP

```lua
local z = archive.zip.open("data.zip")
```

### `archive.zip.from_string(data)` / `archive.zip.from_buffer(data)`

Open a ZIP archive from binary data in memory. Useful for processing ZIP files received over HTTP without writing to disk. Both functions are identical — accepts a string or a Buffer.

| Parameter | Type | Description |
|-----------|------|-------------|
| `data` | string \| Buffer | Binary ZIP data |

**Returns:** ZipReader object

**Raises:** error if data is not a valid ZIP

```lua
local response = http.get("https://example.com/data.zip")
local z = archive.zip.from_string(response.body)

-- Also works with a Buffer
local buf = buffer.from(response.body)
local z = archive.zip.from_buffer(buf)
```

### `archive.zip.create(path)`

Create a new ZIP archive for writing.

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Output file path |

**Returns:** ZipWriter object

**Raises:** error if file cannot be created

```lua
local z = archive.zip.create("output.zip")
```

## ZipReader Methods

### `z:list()`

List all entries in the archive.

**Returns:** array of entry tables

Each entry table contains:

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Full path inside the archive |
| `size` | number | Uncompressed size in bytes |
| `compressed_size` | number | Compressed size in bytes |
| `is_dir` | boolean | Whether the entry is a directory |

```lua
local entries = z:list()
for i, e in ipairs(entries) do
    print(e.name, e.size, e.compressed_size, e.is_dir)
end
```

### `z:read(name)`

Read a specific file from the archive by its path.

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | string | Path of the file inside the archive |

**Returns:** string (binary-safe file contents)

**Raises:** error if the file is not found

```lua
local content = z:read("src/main.lua")
local image = z:read("assets/logo.png")
```

### `z:read_buffer(name)`

Read a specific file from the archive and return it as a Buffer object. Useful for binary data processing without string conversion.

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | string | Path of the file inside the archive |

**Returns:** Buffer object

**Raises:** error if the file is not found

```lua
local buf = z:read_buffer("assets/logo.png")
print(buf:len())       -- size in bytes
print(buf:toHex())     -- hex representation
```

### `z:exists(name)`

Check whether a file exists in the archive.

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | string | Path of the file inside the archive |

**Returns:** boolean

```lua
if z:exists("config.json") then
    local config = json.decode(z:read("config.json"))
end
```

### `z:extract(output_dir, filter?)`

Extract files from the archive to a directory on disk.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `output_dir` | string | | Destination directory |
| `filter` | table | nil | Optional array of filenames to extract |

Parent directories are created automatically. Path traversal (`../`) is detected and rejected.

```lua
z:extract("output/")                              -- extract all
z:extract("output/", {"readme.txt", "src/main.lua"})  -- extract specific files
```

### `z:close()`

Close the archive and release the file handle.

```lua
z:close()
```

## ZipWriter Methods

### `z:add(disk_path, archive_name?)`

Add a file from disk to the archive.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `disk_path` | string | | Path to the file on disk |
| `archive_name` | string | filename from disk_path | Name inside the archive |

```lua
z:add("build/app.lua")                  -- stored as "app.lua"
z:add("build/app.lua", "src/app.lua")   -- stored as "src/app.lua"
```

### `z:add_string(name, contents)`

Add a file from a string or Buffer value.

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | string | Path inside the archive |
| `contents` | string \| Buffer | File contents (binary-safe) |

```lua
z:add_string("version.txt", "1.0.0")
z:add_string("data.json", json.encode({ key = "value" }))
z:add_string("binary.bin", "\x00\x01\x02\x03")
```

### `z:add_data(name, contents)`

Add a file from a string or Buffer value. Identical to `add_string` — provided as an explicit name when working with Buffers.

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | string | Path inside the archive |
| `contents` | string \| Buffer | File contents (binary-safe) |

```lua
local buf = buffer.from("Binary data here")
z:add_data("data.bin", buf)
z:add_data("text.txt", "Also accepts strings")
```

### `z:add_dir(disk_path, prefix?)`

Add a directory and all its contents recursively.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `disk_path` | string | | Path to the directory on disk |
| `prefix` | string | `""` | Prefix for paths inside the archive |

```lua
z:add_dir("src/")                        -- src/main.lua -> src/main.lua
z:add_dir("build/static", "public")      -- build/static/style.css -> public/style.css
```

### `z:close()`

Finalize and close the archive. Writes the ZIP central directory. **Must be called** or the ZIP file will be corrupt.

```lua
z:close()
```

## TAR

### `archive.tar.open(path)`

Open a TAR or TAR.GZ archive from a file. GZIP compression is auto-detected from the file extension (`.tar.gz` or `.tgz`).

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Path to the archive file |

**Returns:** TarReader object

**Raises:** error if file not found

```lua
local t = archive.tar.open("backup.tar.gz")
local t = archive.tar.open("data.tgz")
local t = archive.tar.open("plain.tar")
```

### `archive.tar.create(path)`

Create a new TAR or TAR.GZ archive. GZIP compression is auto-detected from the file extension (`.tar.gz` or `.tgz`).

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Output file path |

**Returns:** TarWriter object

**Raises:** error if file cannot be created

```lua
local t = archive.tar.create("backup.tar.gz")  -- gzipped
local t = archive.tar.create("plain.tar")      -- uncompressed
```

## TarReader Methods

### `t:list()`

List all entries in the archive.

**Returns:** array of entry tables

Each entry table contains:

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Full path inside the archive |
| `size` | number | File size in bytes |
| `is_dir` | boolean | Whether the entry is a directory |

```lua
local entries = t:list()
for i, e in ipairs(entries) do
    print(e.name, e.size, e.is_dir)
end
```

### `t:read(name)`

Read a specific file from the archive.

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | string | Path of the file inside the archive |

**Returns:** string (binary-safe file contents)

**Raises:** error if the file is not found

> Note: TAR is sequential. Each `read()` scans from the beginning.

```lua
local content = t:read("src/main.lua")
```

### `t:read_buffer(name)`

Read a specific file from the archive and return it as a Buffer object.

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | string | Path of the file inside the archive |

**Returns:** Buffer object

**Raises:** error if the file is not found

> Note: TAR is sequential. Each `read_buffer()` scans from the beginning.

```lua
local buf = t:read_buffer("data.bin")
print(buf:len())
```

### `t:extract(output_dir)`

Extract all files from the archive to a directory.

| Parameter | Type | Description |
|-----------|------|-------------|
| `output_dir` | string | Destination directory |

```lua
t:extract("output/")
```

### `t:close()`

Close the reader. For TarReader this is a no-op (each operation opens its own file handle), but provided for API consistency.

```lua
t:close()
```

## TarWriter Methods

### `t:add(disk_path, archive_name?)`

Add a file from disk to the archive.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `disk_path` | string | | Path to the file on disk |
| `archive_name` | string | filename from disk_path | Name inside the archive |

```lua
t:add("config.lua")                           -- stored as "config.lua"
t:add("build/app.lua", "bin/app.lua")         -- stored as "bin/app.lua"
```

### `t:add_string(name, contents)`

Add a file from a string or Buffer value.

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | string | Path inside the archive |
| `contents` | string \| Buffer | File contents (binary-safe) |

Files are created with permissions `0644`.

```lua
t:add_string("readme.txt", "Hello from CopperMoon")
t:add_string("data.bin", "\x00\x01\x02\x03")
```

### `t:add_data(name, contents)`

Add a file from a string or Buffer value. Identical to `add_string` — provided as an explicit name when working with Buffers.

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | string | Path inside the archive |
| `contents` | string \| Buffer | File contents (binary-safe) |

Files are created with permissions `0644`.

```lua
local buf = buffer.from("Binary payload")
t:add_data("payload.bin", buf)
```

### `t:add_dir(disk_path, prefix?)`

Add a directory and all its contents recursively.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `disk_path` | string | | Path to the directory on disk |
| `prefix` | string | `""` | Prefix for paths inside the archive |

```lua
t:add_dir("src/")
t:add_dir("build/static", "public")
```

### `t:close()`

Finalize and close the archive. Writes the TAR end-of-archive marker and (for `.tar.gz`) flushes the GZIP footer. **Must be called** or the archive will be incomplete.

```lua
t:close()
```

## GZIP

### `archive.gzip.compress(data, options?)`

Compress data with GZIP.

| Parameter | Type | Description |
|-----------|------|-------------|
| `data` | string \| Buffer | Data to compress (binary-safe) |
| `options` | table | Optional configuration |

**Options:**

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `level` | number | `6` | Compression level (0-9) |

Compression levels:

| Level | Description |
|-------|-------------|
| `0` | No compression (store only) |
| `1` | Fastest compression |
| `6` | Default (balanced) |
| `9` | Maximum compression (slowest) |

**Returns:** string (compressed binary data)

```lua
local compressed = archive.gzip.compress("Hello, World!")
local compressed = archive.gzip.compress(data, { level = 9 })
local fast = archive.gzip.compress(data, { level = 1 })
```

### `archive.gzip.decompress(data)`

Decompress GZIP data.

| Parameter | Type | Description |
|-----------|------|-------------|
| `data` | string \| Buffer | GZIP compressed data |

**Returns:** string (decompressed data)

**Raises:** error if data is not valid GZIP

```lua
local original = archive.gzip.decompress(compressed)
```

### `archive.gzip.compress_buffer(data, options?)`

Compress data with GZIP and return the result as a Buffer object. Same as `compress` but returns a Buffer instead of a string.

| Parameter | Type | Description |
|-----------|------|-------------|
| `data` | string \| Buffer | Data to compress (binary-safe) |
| `options` | table | Optional configuration |

**Options:** Same as `compress` (`level` 0-9, default 6).

**Returns:** Buffer (compressed data)

```lua
local compressed_buf = archive.gzip.compress_buffer("Hello, World!")
print(compressed_buf:len())  -- compressed size
```

### `archive.gzip.decompress_buffer(data)`

Decompress GZIP data and return the result as a Buffer object.

| Parameter | Type | Description |
|-----------|------|-------------|
| `data` | string \| Buffer | GZIP compressed data |

**Returns:** Buffer (decompressed data)

**Raises:** error if data is not valid GZIP

```lua
local buf = archive.gzip.decompress_buffer(compressed)
print(buf:len())           -- decompressed size
print(buf:toString())      -- as string
```
