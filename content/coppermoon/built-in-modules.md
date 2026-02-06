# Built-in Modules

Complete reference of all modules available in CopperMoon. All modules are global and do not require `require()`.

## fs - File System

| Function | Returns | Description |
|----------|---------|-------------|
| `fs.read(path)` | string | Read entire file contents |
| `fs.write(path, content)` | boolean | Write content to file (overwrites) |
| `fs.append(path, content)` | boolean | Append content to file |
| `fs.exists(path)` | boolean | Check if path exists |
| `fs.remove(path)` | boolean | Delete file |
| `fs.copy(src, dest)` | integer | Copy file (returns bytes copied) |
| `fs.rename(src, dest)` | boolean | Rename or move file |
| `fs.mkdir(path)` | boolean | Create directory |
| `fs.mkdir_all(path)` | boolean | Create directories recursively |
| `fs.rmdir(path)` | boolean | Remove empty directory |
| `fs.rmdir_all(path)` | boolean | Remove directory recursively |
| `fs.readdir(path)` | table | List directory contents (array of names) |
| `fs.stat(path)` | table | Get file metadata |
| `fs.is_file(path)` | boolean | Check if path is a file |
| `fs.is_dir(path)` | boolean | Check if path is a directory |

See [File System](/docs/coppermoon/filesystem) for details.

## path - Path Manipulation

| Function | Returns | Description |
|----------|---------|-------------|
| `path.join(...)` | string | Join path components |
| `path.dirname(path)` | string/nil | Get directory part |
| `path.basename(path)` | string/nil | Get filename |
| `path.extname(path)` | string/nil | Get extension (with dot) |
| `path.resolve(path)` | string | Convert to absolute path |
| `path.normalize(path)` | string | Normalize (resolve `..` and `.`) |
| `path.is_absolute(path)` | boolean | Check if absolute |
| `path.is_relative(path)` | boolean | Check if relative |
| `path.sep` | string | Path separator (`/` or `\`) |

## json - JSON

| Function | Returns | Description |
|----------|---------|-------------|
| `json.encode(value)` | string | Encode to JSON string |
| `json.decode(string)` | any | Decode JSON string to Lua value |
| `json.pretty(value)` | string | Encode to formatted JSON |

See [JSON](/docs/coppermoon/json) for details.

## crypto - Cryptography

### Hashing

| Function | Returns | Description |
|----------|---------|-------------|
| `crypto.sha256(data)` | string | SHA-256 hash (hex) |
| `crypto.sha1(data)` | string | SHA-1 hash (hex) |
| `crypto.md5(data)` | string | MD5 hash (hex) |
| `crypto.hmac(algo, key, data)` | string | HMAC signature (hex). algo: `"sha256"` or `"sha1"` |

### Encoding

| Function | Returns | Description |
|----------|---------|-------------|
| `crypto.base64_encode(data)` | string | Encode to base64 |
| `crypto.base64_decode(data)` | string | Decode from base64 |
| `crypto.hex_encode(data)` | string | Encode to hexadecimal |
| `crypto.hex_decode(data)` | string | Decode from hexadecimal |

### Utilities

| Function | Returns | Description |
|----------|---------|-------------|
| `crypto.random_bytes(n)` | string | Generate n random bytes |
| `crypto.uuid()` | string | Generate UUID v4 |

## time - Time & Timers

| Function | Returns | Description |
|----------|---------|-------------|
| `time.now()` | number | Unix timestamp in seconds |
| `time.now_ms()` | integer | Unix timestamp in milliseconds |
| `time.monotonic()` | number | Monotonic time in seconds |
| `time.monotonic_ms()` | integer | Monotonic time in milliseconds |
| `time.sleep(ms)` | nil | Sleep for milliseconds (blocking) |
| `time.format(timestamp, format?)` | string | Format timestamp (default: `"%Y-%m-%d %H:%M:%S"`) |
| `time.parse(string, format?)` | number | Parse ISO 8601 string to timestamp |

See [Time & Date](/docs/coppermoon/time) for details.

## http - HTTP Client & Server

### Client

| Function | Returns | Description |
|----------|---------|-------------|
| `http.get(url, options?)` | response | GET request |
| `http.post(url, body?, options?)` | response | POST request |
| `http.put(url, body?, options?)` | response | PUT request |
| `http.delete(url, options?)` | response | DELETE request |
| `http.patch(url, body?, options?)` | response | PATCH request |
| `http.request(options)` | response | Generic request |
| `http.create_session()` | session | Create persistent HTTP session |

### Server

| Function | Returns | Description |
|----------|---------|-------------|
| `http.server.new()` | server | Create HTTP server |

See [HTTP Server](/docs/coppermoon/http-server) for details.

## process - Process Management

| Function | Returns | Description |
|----------|---------|-------------|
| `process.exit(code?)` | - | Exit process (default: 0) |
| `process.pid()` | integer | Get process ID |
| `process.exec(cmd)` | table | Execute shell command |
| `process.spawn(cmd, args?)` | table | Spawn process with arguments |

`exec()` and `spawn()` return a table with:

| Field | Type | Description |
|-------|------|-------------|
| `stdout` | string | Standard output |
| `stderr` | string | Standard error |
| `status` | integer | Exit code |
| `success` | boolean | true if exit code 0 |

## os_ext - Extended OS

| Function | Returns | Description |
|----------|---------|-------------|
| `os_ext.env(key)` | string/nil | Get environment variable |
| `os_ext.setenv(key, value)` | nil | Set environment variable |
| `os_ext.unsetenv(key)` | nil | Unset environment variable |
| `os_ext.cwd()` | string | Current working directory |
| `os_ext.chdir(path)` | boolean | Change working directory |
| `os_ext.platform()` | string | OS name (`"linux"`, `"windows"`, `"macos"`) |
| `os_ext.arch()` | string | CPU architecture (`"x86_64"`, `"aarch64"`) |
| `os_ext.homedir()` | string/nil | Home directory |
| `os_ext.tmpdir()` | string | Temp directory |
| `os_ext.hostname()` | string | Machine hostname |
| `os_ext.cpus()` | integer | Number of CPU cores |

## net - Networking

### TCP

| Function | Returns | Description |
|----------|---------|-------------|
| `net.tcp.connect(host, port)` | connection | Connect to TCP server |
| `net.tcp.listen(host?, port)` | server | Create TCP server (default host: `"0.0.0.0"`) |

**Connection methods:** `read(n?)`, `read_line()`, `read_all()`, `write(data)`, `write_all(data)`, `flush()`, `close()`, `set_timeout(ms?)`, `peer_addr()`, `local_addr()`

**Server methods:** `accept()`, `local_addr()`, `set_nonblocking(bool)`

### UDP

| Function | Returns | Description |
|----------|---------|-------------|
| `net.udp.bind(host?, port)` | socket | Create UDP socket (default host: `"0.0.0.0"`) |

**Socket methods:** `send(data, host, port)`, `recv(n?)`, `connect(host, port)`, `send_connected(data)`, `set_timeout(ms?)`, `local_addr()`, `set_broadcast(bool)`

### DNS

| Function | Returns | Description |
|----------|---------|-------------|
| `net.resolve(hostname)` | table | Resolve hostname to IP addresses (array of strings) |

## sqlite - SQLite Database

| Function | Returns | Description |
|----------|---------|-------------|
| `sqlite.open(path)` | db | Open database file |
| `sqlite.memory()` | db | Create in-memory database |
| `sqlite.version()` | string | SQLite version |

**Database methods:** `exec(sql)`, `execute(sql, params...)`, `query(sql, params?)`, `query_row(sql, params?)`, `last_insert_id()`, `changes()`, `begin()`, `commit()`, `rollback()`, `transaction(fn)`, `table_exists(name)`, `table_info(name)`, `close()`

## mysql - MySQL Database

| Function | Returns | Description |
|----------|---------|-------------|
| `mysql.connect(options)` | db | Connect with options table |
| `mysql.open(url)` | db | Connect with URL string |
| `mysql.version()` | string | Client version |

**Database methods:** Same as SQLite, plus `ping()`, `server_version()`, `index_list(name)`

## postgresql - PostgreSQL Database

| Function | Returns | Description |
|----------|---------|-------------|
| `postgresql.connect(options\|url)` | db | Connect with options table or URL string |
| `postgresql.open(url)` | db | Connect with URL string (alias) |
| `postgresql.version()` | string | Driver version |

**Database methods:** Same as SQLite, plus `ping()`, `server_version()`, `index_list(name)`

Note: Use `?` placeholders in queries — they are automatically converted to PostgreSQL's `$1, $2, ...` format.

## term - Terminal Styling & Control

### Colors

| Function | Returns | Description |
|----------|---------|-------------|
| `term.red(text)` | string | Red text |
| `term.green(text)` | string | Green text |
| `term.yellow(text)` | string | Yellow text |
| `term.blue(text)` | string | Blue text |
| `term.magenta(text)` | string | Magenta text |
| `term.cyan(text)` | string | Cyan text |
| `term.white(text)` | string | White text |
| `term.black(text)` | string | Black text |
| `term.gray(text)` | string | Gray text (alias: `grey`) |

Bright variants: `bright_red`, `bright_green`, `bright_yellow`, `bright_blue`, `bright_magenta`, `bright_cyan`, `bright_white`

Background colors: `bg_red`, `bg_green`, `bg_yellow`, `bg_blue`, `bg_magenta`, `bg_cyan`, `bg_white`, `bg_black`

### Decorations

| Function | Returns | Description |
|----------|---------|-------------|
| `term.bold(text)` | string | Bold text |
| `term.dim(text)` | string | Dimmed text |
| `term.italic(text)` | string | Italic text |
| `term.underline(text)` | string | Underlined text |
| `term.strikethrough(text)` | string | Strikethrough text |

### Advanced Colors

| Function | Returns | Description |
|----------|---------|-------------|
| `term.rgb(r, g, b, text)` | string | 24-bit RGB foreground |
| `term.bg_rgb(r, g, b, text)` | string | 24-bit RGB background |
| `term.color256(code, text)` | string | 256-color foreground |
| `term.bg_color256(code, text)` | string | 256-color background |

### Utilities

| Function | Returns | Description |
|----------|---------|-------------|
| `term.strip(text)` | string | Remove all ANSI escape codes |
| `term.reset()` | string | Return the ANSI reset code |

### Terminal Control

| Function | Returns | Description |
|----------|---------|-------------|
| `term.clear()` | nil | Clear screen and move to top-left |
| `term.clear_line()` | nil | Clear current line |
| `term.size()` | width, height | Terminal dimensions in columns/rows |
| `term.is_tty()` | boolean | Check if stdout is a terminal |
| `term.cursor_to(col, row)` | nil | Move cursor (1-indexed) |
| `term.cursor_up(n?)` | nil | Move cursor up |
| `term.cursor_down(n?)` | nil | Move cursor down |
| `term.cursor_left(n?)` | nil | Move cursor left |
| `term.cursor_right(n?)` | nil | Move cursor right |
| `term.cursor_hide()` | nil | Hide cursor |
| `term.cursor_show()` | nil | Show cursor |
| `term.cursor_save()` | nil | Save cursor position |
| `term.cursor_restore()` | nil | Restore saved position |

See [CLI Tools](/docs/backend-services/cli-tools) for usage examples.

## console - Interactive Input

| Function | Returns | Description |
|----------|---------|-------------|
| `console.prompt(message, default?)` | string | Read user input with optional default |
| `console.password(message)` | string | Read input without echo |
| `console.confirm(message, default?)` | boolean | Yes/no prompt |
| `console.select(message, options)` | index, value | Numbered menu selection |
| `console.multiselect(message, options)` | indices, values | Multi-pick selection |

See [CLI Tools](/docs/backend-services/cli-tools) for usage examples.

## String Extensions

Extensions added to Lua's built-in `string` table. All work as methods: `("hello"):trim()`.

| Function | Returns | Description |
|----------|---------|-------------|
| `string.split(s, sep)` | table | Split by separator |
| `string.trim(s)` | string | Trim whitespace from both ends |
| `string.ltrim(s)` | string | Trim whitespace from left |
| `string.rtrim(s)` | string | Trim whitespace from right |
| `string.starts_with(s, prefix)` | boolean | Check prefix |
| `string.ends_with(s, suffix)` | boolean | Check suffix |
| `string.contains(s, substr)` | boolean | Check substring |
| `string.pad_left(s, width, fill?)` | string | Left-pad to width |
| `string.pad_right(s, width, fill?)` | string | Right-pad to width |
| `string.pad_center(s, width, fill?)` | string | Center-pad to width |
| `string.truncate(s, max, suffix?)` | string | Truncate with optional suffix |
| `string.lines(s)` | table | Split into lines |
| `string.chars(s)` | table | Split into characters |
| `string.replace_all(s, old, new)` | string | Replace all occurrences |
| `string.count(s, substr)` | integer | Count substring occurrences |
| `string.slug(s)` | string | URL-friendly slug |

## Table Extensions

Extensions added to Lua's built-in `table` table.

### Iteration

| Function | Returns | Description |
|----------|---------|-------------|
| `table.keys(t)` | table | Array of all keys |
| `table.values(t)` | table | Array of all values |
| `table.count(t)` | integer | Count all entries (hash tables too) |
| `table.is_empty(t)` | boolean | Check if table has no entries |
| `table.contains(t, value)` | boolean | Check if value exists |

### Transformation

| Function | Returns | Description |
|----------|---------|-------------|
| `table.map(t, fn)` | table | Apply function to each element |
| `table.filter(t, fn)` | table | Keep elements where function returns true |
| `table.find(t, fn)` | any/nil | First element where function returns true |
| `table.reduce(t, fn, init?)` | any | Accumulate with function |
| `table.reverse(t)` | table | Reverse array order |
| `table.flat(t, depth?)` | table | Flatten nested arrays |
| `table.slice(t, from, to?)` | table | Sub-array (1-indexed, inclusive) |

### Copying

| Function | Returns | Description |
|----------|---------|-------------|
| `table.merge(a, b, ...)` | table | Shallow merge (later overwrites) |
| `table.clone(t)` | table | Shallow copy |

### Freezing

| Function | Returns | Description |
|----------|---------|-------------|
| `table.freeze(t)` | table | Make table read-only |
| `table.is_frozen(t)` | boolean | Check if table is frozen |

## Global Timer Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `setTimeout(fn, ms)` | integer | Schedule callback after delay |
| `setInterval(fn, ms)` | integer | Schedule callback repeatedly |
| `clearTimeout(id)` | nil | Cancel timeout |
| `clearInterval(id)` | nil | Cancel interval |
