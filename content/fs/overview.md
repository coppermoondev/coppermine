# File System

The `fs` module provides complete file system operations for CopperMoon — reading, writing, copying, moving files and directories, path manipulation, glob search, and more.

## Quick Start

### Read and Write Files

```lua
-- Text files
fs.write("config.lua", "return { debug = true }")
local content = fs.read("config.lua")

-- Binary files (using Buffer)
local buf = fs.read_bytes("image.png")
print(buf:len())  -- size in bytes
fs.write_bytes("copy.png", buf)
```

### File Operations

```lua
fs.copy("original.txt", "backup.txt")
fs.move("old_name.txt", "new_name.txt")
fs.remove("temp.txt")
fs.touch("empty.txt")
```

### Directory Operations

```lua
fs.mkdir_all("data/logs/2025")
fs.copy_dir("src/", "backup/src/")

local files = fs.readdir("src/")
for _, name in ipairs(files) do
    print(name)
end

fs.rmdir_all("temp/")
```

### Path Utilities

```lua
print(fs.basename("/app/src/main.lua"))  -- "main.lua"
print(fs.dirname("/app/src/main.lua"))   -- "/app/src"
print(fs.ext("archive.tar.gz"))          -- "gz"
print(fs.join("src", "lib", "utils.lua")) -- "src/lib/utils.lua"
print(fs.abs("."))                        -- "/home/user/project"
```

## Reading Files

### Text Files

`fs.read` reads a file as a UTF-8 string:

```lua
local content = fs.read("config.json")
local config = json.decode(content)
```

### Binary Files

`fs.read_bytes` reads a file and returns a Buffer object. Use this for binary files (images, archives, etc.) that may not be valid UTF-8:

```lua
local buf = fs.read_bytes("photo.jpg")
print(buf:len())          -- file size
print(buf:toBase64())     -- base64 representation

-- Pass directly to other APIs
local z = archive.zip.from_buffer(buf)
```

## Writing Files

### Text Files

```lua
fs.write("output.txt", "Hello, World!")
fs.append("log.txt", "New log entry\n")
```

### Binary Files

`fs.write_bytes` accepts both strings and Buffer objects:

```lua
-- From a Buffer
local buf = archive.gzip.compress_buffer(data)
fs.write_bytes("data.gz", buf)

-- From a binary string
fs.write_bytes("raw.bin", "\x00\x01\x02\x03")
```

## File Operations

### Copy

```lua
-- Copy a single file (returns bytes copied)
local bytes = fs.copy("src.txt", "dest.txt")

-- Copy an entire directory recursively
fs.copy_dir("project/", "backup/project/")
```

### Move

`fs.move` works across filesystems — it tries a fast rename first, and falls back to copy + delete:

```lua
fs.move("downloads/report.pdf", "documents/report.pdf")
fs.move("old_project/", "archive/old_project/")  -- directories too
```

`fs.rename` is the low-level alternative (same filesystem only):

```lua
fs.rename("temp.txt", "final.txt")
```

### Remove

```lua
fs.remove("file.txt")       -- single file
fs.rmdir("empty_dir/")      -- empty directory
fs.rmdir_all("full_dir/")   -- directory with contents
```

### Touch

Creates an empty file if it doesn't exist, or updates the modification time if it does. Creates parent directories automatically:

```lua
fs.touch("data/cache/.ready")
```

## Directory Operations

### Create

```lua
fs.mkdir("logs")                   -- single directory
fs.mkdir_all("data/cache/images")  -- create all parents
```

### List Contents

```lua
local entries = fs.readdir("src/")
for _, name in ipairs(entries) do
    print(name)
end
-- Output: main.lua, utils.lua, lib/
```

### Copy Recursively

```lua
fs.copy_dir("src/", "build/src/")
```

All files and subdirectories are copied. The destination is created if it doesn't exist.

## Checking Files

```lua
if fs.exists("config.lua") then
    local config = fs.read("config.lua")
end

fs.is_file("main.lua")     -- true for files
fs.is_dir("src/")           -- true for directories
fs.is_symlink("link.txt")   -- true for symbolic links
```

## Metadata

### Quick Size Check

```lua
local bytes = fs.size("data.bin")
print(string.format("%.2f MB", bytes / 1024 / 1024))
```

### Full Metadata

```lua
local stat = fs.stat("app.lua")
print(stat.size)        -- file size in bytes
print(stat.is_file)     -- true
print(stat.is_dir)      -- false
print(stat.is_symlink)  -- false
print(stat.readonly)    -- false
print(stat.modified)    -- Unix timestamp
print(stat.created)     -- Unix timestamp
print(stat.accessed)    -- Unix timestamp
```

## Path Utilities

All path functions work with strings — no file access required, purely string manipulation (except `fs.abs` which resolves against the real filesystem).

### Decompose

```lua
fs.basename("/app/src/main.lua")  -- "main.lua"
fs.dirname("/app/src/main.lua")   -- "/app/src"
fs.ext("archive.tar.gz")          -- "gz"
fs.ext("Makefile")                -- ""
```

### Compose

```lua
fs.join("src", "lib", "utils.lua")  -- "src/lib/utils.lua" (OS-appropriate separator)
```

### Resolve

```lua
local abs = fs.abs(".")           -- "/home/user/project"
local abs = fs.abs("../other")    -- "/home/user/other"
```

On Windows, the `\\?\` prefix from `canonicalize` is automatically stripped.

## Glob Search

Find files matching a pattern:

```lua
-- All Lua files in src/
local files = fs.glob("src/*.lua")

-- All Lua files recursively
local files = fs.glob("src/**/*.lua")

-- All config files
local files = fs.glob("config/*.{json,yaml,toml}")

for _, path in ipairs(files) do
    print(path)
end
```

Patterns follow standard glob syntax:
- `*` — matches any characters except `/`
- `**` — matches any number of directories
- `?` — matches a single character
- `{a,b}` — matches either `a` or `b`
- `[abc]` — matches one of the characters

## Environment

```lua
local cwd = fs.cwd()         -- current working directory
local tmp = fs.temp_dir()     -- system temp directory (e.g. /tmp)
```

## Error Handling

All fs operations raise Lua errors on failure. Use `pcall` for graceful handling:

```lua
local ok, err = pcall(function()
    local content = fs.read("nonexistent.txt")
end)
if not ok then
    print("Error:", err)
end
```

Common error scenarios:

- **File not found** — reading or stat-ing a path that doesn't exist
- **Permission denied** — insufficient permissions to read/write/delete
- **Not a directory** — using directory operations on a file
- **Directory not empty** — `fs.rmdir` on a non-empty directory (use `fs.rmdir_all`)
- **Path already exists** — `fs.mkdir` when directory already exists (use `fs.mkdir_all`)

## Next Steps

- [API Reference](/docs/fs/api) — Complete function reference
- [Buffer](/docs/buffer/overview) — Binary data manipulation for working with raw bytes
- [Archive](/docs/archive/overview) — ZIP, TAR, GZIP compression and archive support
