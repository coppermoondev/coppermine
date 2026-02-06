# File System

The `fs` module provides file and directory operations. It is available globally without `require()`.

## Reading Files

### fs.read(path)

Read the entire contents of a file.

```lua
local content = fs.read("config.toml")
print(content)
```

Throws an error if the file does not exist. Use `pcall()` to handle missing files:

```lua
local ok, content = pcall(fs.read, "optional.txt")
if ok then
    print(content)
else
    print("File not found")
end
```

## Writing Files

### fs.write(path, content)

Write content to a file. Creates the file if it doesn't exist, overwrites if it does.

```lua
fs.write("output.txt", "Hello, World!")
fs.write("data.json", json.encode({ name = "Alice", age = 30 }))
```

### fs.append(path, content)

Append content to the end of a file. Creates the file if it doesn't exist.

```lua
fs.append("log.txt", "[" .. os.date() .. "] Server started\n")
fs.append("log.txt", "[" .. os.date() .. "] Request received\n")
```

## File Operations

### fs.copy(src, dest)

Copy a file. Returns the number of bytes copied.

```lua
local bytes = fs.copy("original.txt", "backup.txt")
print("Copied " .. bytes .. " bytes")
```

### fs.rename(src, dest)

Rename or move a file.

```lua
fs.rename("old-name.txt", "new-name.txt")
fs.rename("file.txt", "archive/file.txt")
```

### fs.remove(path)

Delete a file.

```lua
fs.remove("temp.txt")
```

## Directory Operations

### fs.mkdir(path)

Create a single directory. The parent directory must exist.

```lua
fs.mkdir("logs")
```

### fs.mkdir_all(path)

Create directories recursively, including any missing parent directories.

```lua
fs.mkdir_all("data/backups/2025")
```

### fs.rmdir(path)

Remove an empty directory.

```lua
fs.rmdir("empty-dir")
```

### fs.rmdir_all(path)

Remove a directory and all its contents recursively.

```lua
fs.rmdir_all("temp-data")
```

### fs.readdir(path)

List the contents of a directory. Returns an array of filenames.

```lua
local files = fs.readdir(".")
for _, name in ipairs(files) do
    print(name)
end
```

The returned array contains filenames only (not full paths). It does not include `.` or `..`.

## File Information

### fs.exists(path)

Check if a file or directory exists.

```lua
if fs.exists("config.toml") then
    local config = fs.read("config.toml")
end
```

### fs.is_file(path)

Check if a path is a regular file.

```lua
if fs.is_file("app.lua") then
    print("It's a file")
end
```

### fs.is_dir(path)

Check if a path is a directory.

```lua
if fs.is_dir("views") then
    print("It's a directory")
end
```

### fs.stat(path)

Get detailed metadata about a file or directory.

```lua
local info = fs.stat("app.lua")
print(info.size)       -- File size in bytes
print(info.is_file)    -- true
print(info.is_dir)     -- false
print(info.readonly)   -- false
print(info.modified)   -- Unix timestamp
print(info.created)    -- Unix timestamp
```

Returns a table with:

| Field | Type | Description |
|-------|------|-------------|
| `size` | integer | File size in bytes |
| `is_file` | boolean | Is a regular file |
| `is_dir` | boolean | Is a directory |
| `readonly` | boolean | Is read-only |
| `modified` | integer | Last modified time (Unix timestamp) |
| `created` | integer | Creation time (Unix timestamp) |

## Path Module

The `path` module complements `fs` with path string manipulation:

```lua
-- Join path components
local filepath = path.join("views", "pages", "home.vein")
-- "views/pages/home.vein"

-- Get parts of a path
path.dirname("/home/user/app.lua")     -- "/home/user"
path.basename("/home/user/app.lua")    -- "app.lua"
path.extname("app.lua")               -- ".lua"

-- Resolve to absolute path
local abs = path.resolve("app.lua")

-- Normalize (resolve .. and .)
path.normalize("views/../public/./css")  -- "public/css"

-- Check path type
path.is_absolute("/etc/config")   -- true
path.is_relative("app.lua")      -- true

-- Platform separator
print(path.sep)   -- "/" on Unix, "\" on Windows
```

## Practical Examples

### Read and parse JSON config

```lua
local content = fs.read("config.json")
local config = json.decode(content)
print(config.database.host)
```

### Write log file

```lua
local function log(message)
    local timestamp = time.format(time.now())
    fs.append("app.log", "[" .. timestamp .. "] " .. message .. "\n")
end

log("Application started")
log("Listening on port 3000")
```

### Copy directory contents

```lua
local function copyDir(src, dest)
    fs.mkdir_all(dest)
    for _, name in ipairs(fs.readdir(src)) do
        local srcPath = path.join(src, name)
        local destPath = path.join(dest, name)
        if fs.is_dir(srcPath) then
            copyDir(srcPath, destPath)
        else
            fs.copy(srcPath, destPath)
        end
    end
end

copyDir("public", "dist/public")
```

### Find files by extension

```lua
local function findFiles(dir, ext)
    local results = {}
    for _, name in ipairs(fs.readdir(dir)) do
        local filepath = path.join(dir, name)
        if fs.is_dir(filepath) then
            for _, f in ipairs(findFiles(filepath, ext)) do
                table.insert(results, f)
            end
        elseif name:match("%." .. ext .. "$") then
            table.insert(results, filepath)
        end
    end
    return results
end

local luaFiles = findFiles("src", "lua")
for _, f in ipairs(luaFiles) do
    print(f)
end
```
