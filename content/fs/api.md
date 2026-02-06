# API Reference

Complete API reference for the CopperMoon `fs` module.

## Reading Files

### `fs.read(path)`

Read a file as a UTF-8 string.

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Path to the file |

**Returns:** string

**Raises:** error if file not found or not valid UTF-8

```lua
local content = fs.read("config.json")
```

### `fs.read_bytes(path)`

Read a file as a Buffer object. Use this for binary files that may not be valid UTF-8.

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Path to the file |

**Returns:** Buffer object

**Raises:** error if file not found

```lua
local buf = fs.read_bytes("image.png")
print(buf:len())
```

## Writing Files

### `fs.write(path, content)`

Write a string to a file. Creates the file if it doesn't exist, overwrites if it does.

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Path to the file |
| `content` | string | Content to write |

**Returns:** boolean (`true` on success)

```lua
fs.write("output.txt", "Hello, World!")
```

### `fs.write_bytes(path, data)`

Write binary data to a file. Accepts both strings and Buffer objects.

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Path to the file |
| `data` | string \| Buffer | Data to write |

**Returns:** boolean (`true` on success)

```lua
local buf = archive.gzip.compress_buffer(data)
fs.write_bytes("data.gz", buf)
fs.write_bytes("raw.bin", "\x00\x01\x02\x03")
```

### `fs.append(path, content)`

Append a string to a file. Creates the file if it doesn't exist.

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Path to the file |
| `content` | string | Content to append |

**Returns:** boolean (`true` on success)

```lua
fs.append("log.txt", "New entry\n")
```

## Existence and Type Checks

### `fs.exists(path)`

Check if a path exists.

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Path to check |

**Returns:** boolean

```lua
if fs.exists("config.lua") then
    -- file exists
end
```

### `fs.is_file(path)`

Check if a path is a regular file.

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Path to check |

**Returns:** boolean

```lua
if fs.is_file("main.lua") then
    local code = fs.read("main.lua")
end
```

### `fs.is_dir(path)`

Check if a path is a directory.

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Path to check |

**Returns:** boolean

```lua
if fs.is_dir("src/") then
    local files = fs.readdir("src/")
end
```

### `fs.is_symlink(path)`

Check if a path is a symbolic link.

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Path to check |

**Returns:** boolean

```lua
if fs.is_symlink("link.txt") then
    print("This is a symlink")
end
```

## File Operations

### `fs.remove(path)`

Delete a file.

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Path to the file |

**Returns:** boolean (`true` on success)

**Raises:** error if file not found or permission denied

```lua
fs.remove("temp.txt")
```

### `fs.copy(src, dest)`

Copy a single file.

| Parameter | Type | Description |
|-----------|------|-------------|
| `src` | string | Source file path |
| `dest` | string | Destination file path |

**Returns:** number (bytes copied)

```lua
local bytes = fs.copy("original.txt", "backup.txt")
```

### `fs.rename(src, dest)`

Rename or move a file (same filesystem only).

| Parameter | Type | Description |
|-----------|------|-------------|
| `src` | string | Current path |
| `dest` | string | New path |

**Returns:** boolean (`true` on success)

**Raises:** error if cross-filesystem (use `fs.move` instead)

```lua
fs.rename("draft.txt", "final.txt")
```

### `fs.move(src, dest)`

Move a file or directory. Works across filesystems — tries a fast rename first, falls back to copy + delete.

| Parameter | Type | Description |
|-----------|------|-------------|
| `src` | string | Source path |
| `dest` | string | Destination path |

**Returns:** boolean (`true` on success)

```lua
fs.move("downloads/report.pdf", "documents/report.pdf")
fs.move("old_project/", "archive/old_project/")
```

### `fs.touch(path)`

Create an empty file if it doesn't exist, or update the modification time if it does. Creates parent directories automatically.

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Path to the file |

**Returns:** boolean (`true` on success)

```lua
fs.touch("data/cache/.ready")
```

### `fs.size(path)`

Get the size of a file in bytes.

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Path to the file |

**Returns:** number (size in bytes)

```lua
local bytes = fs.size("data.bin")
print(string.format("%.2f KB", bytes / 1024))
```

## Directory Operations

### `fs.mkdir(path)`

Create a single directory.

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Directory path |

**Returns:** boolean (`true` on success)

**Raises:** error if parent doesn't exist (use `fs.mkdir_all`)

```lua
fs.mkdir("logs")
```

### `fs.mkdir_all(path)`

Create a directory and all parent directories.

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Directory path |

**Returns:** boolean (`true` on success)

```lua
fs.mkdir_all("data/cache/images")
```

### `fs.rmdir(path)`

Remove an empty directory.

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Directory path |

**Returns:** boolean (`true` on success)

**Raises:** error if directory is not empty (use `fs.rmdir_all`)

```lua
fs.rmdir("empty_dir")
```

### `fs.rmdir_all(path)`

Remove a directory and all its contents recursively.

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Directory path |

**Returns:** boolean (`true` on success)

```lua
fs.rmdir_all("build/")
```

### `fs.readdir(path)`

List all entries in a directory.

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Directory path |

**Returns:** array of strings (entry names)

```lua
local entries = fs.readdir("src/")
for _, name in ipairs(entries) do
    print(name)
end
```

### `fs.copy_dir(src, dest)`

Copy a directory and all its contents recursively. Creates the destination if it doesn't exist.

| Parameter | Type | Description |
|-----------|------|-------------|
| `src` | string | Source directory |
| `dest` | string | Destination directory |

**Returns:** boolean (`true` on success)

```lua
fs.copy_dir("src/", "backup/src/")
```

## Metadata

### `fs.stat(path)`

Get detailed metadata about a file or directory.

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Path to inspect |

**Returns:** table with metadata fields

| Field | Type | Description |
|-------|------|-------------|
| `size` | number | File size in bytes |
| `is_file` | boolean | Whether it's a regular file |
| `is_dir` | boolean | Whether it's a directory |
| `is_symlink` | boolean | Whether it's a symbolic link |
| `readonly` | boolean | Whether it's read-only |
| `modified` | number | Last modified time (Unix timestamp) |
| `created` | number | Creation time (Unix timestamp) |
| `accessed` | number | Last accessed time (Unix timestamp) |

```lua
local stat = fs.stat("app.lua")
print(stat.size, stat.modified)
```

## Path Utilities

### `fs.abs(path)`

Resolve a path to an absolute path using the real filesystem.

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Path to resolve |

**Returns:** string (absolute path)

**Raises:** error if path doesn't exist

On Windows, the `\\?\` prefix is automatically stripped.

```lua
local abs = fs.abs(".")         -- "/home/user/project"
local abs = fs.abs("../other")  -- "/home/user/other"
```

### `fs.join(...)`

Join path components using the OS-appropriate separator. Accepts any number of string arguments.

| Parameter | Type | Description |
|-----------|------|-------------|
| `...` | strings | Path components |

**Returns:** string (joined path)

```lua
local path = fs.join("src", "lib", "utils.lua")
-- Linux: "src/lib/utils.lua"
-- Windows: "src\\lib\\utils.lua"
```

### `fs.basename(path)`

Get the filename from a path (last component).

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | File path |

**Returns:** string (filename)

```lua
fs.basename("/app/src/main.lua")  -- "main.lua"
fs.basename("file.txt")           -- "file.txt"
```

### `fs.dirname(path)`

Get the parent directory from a path.

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | File path |

**Returns:** string (parent directory, empty string if none)

```lua
fs.dirname("/app/src/main.lua")  -- "/app/src"
fs.dirname("file.txt")           -- ""
```

### `fs.ext(path)`

Get the file extension (without the dot).

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | File path |

**Returns:** string (extension, empty string if none)

```lua
fs.ext("main.lua")          -- "lua"
fs.ext("archive.tar.gz")    -- "gz"
fs.ext("Makefile")           -- ""
```

## Search

### `fs.glob(pattern)`

Find files matching a glob pattern.

| Parameter | Type | Description |
|-----------|------|-------------|
| `pattern` | string | Glob pattern |

**Returns:** array of strings (matching file paths)

Pattern syntax:

| Pattern | Description |
|---------|-------------|
| `*` | Matches any characters except `/` |
| `**` | Matches any number of directories |
| `?` | Matches a single character |
| `{a,b}` | Matches either `a` or `b` |
| `[abc]` | Matches one of the characters |

```lua
local files = fs.glob("src/*.lua")
local all_lua = fs.glob("**/*.lua")
local configs = fs.glob("config/*.{json,yaml}")

for _, path in ipairs(files) do
    print(path)
end
```

## Environment

### `fs.cwd()`

Get the current working directory.

**Returns:** string

```lua
local cwd = fs.cwd()
print(cwd)  -- "/home/user/project"
```

### `fs.temp_dir()`

Get the system temporary directory.

**Returns:** string

```lua
local tmp = fs.temp_dir()
fs.write(fs.join(tmp, "myapp.tmp"), "temp data")
```
