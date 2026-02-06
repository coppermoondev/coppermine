# CLI Tools

CopperMoon includes `term` and `console` modules for building interactive command-line tools, admin scripts, and developer utilities.

## Quick Example

```lua
print(term.bold("My CLI Tool v1.0"))
print()

local name = console.prompt("Project name: ", "my-app")
local _, db_choice = console.select("Database:", {"SQLite", "MySQL", "None"})
local install = console.confirm("Install dependencies?", true)

print()
print(term.green("Creating project: ") .. term.bold(name))
print(term.dim("Database: " .. db_choice))
if install then
    print(term.yellow("Installing dependencies..."))
end
print(term.bold(term.green("Done!")))
```

## Terminal Colors and Styles

The `term` module provides functions that wrap text in ANSI escape codes. Each returns a string you can print, concatenate, or store.

### Colors

```lua
print(term.red("Error: something went wrong"))
print(term.green("Success!"))
print(term.yellow("Warning: disk space low"))
print(term.blue("Info: server started"))
print(term.magenta("Debug: query took 42ms"))
print(term.cyan("Hint: try --help"))
print(term.gray("-- skipped --"))
```

Available colors: `black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`, `gray` (alias: `grey`)

Bright variants: `bright_red`, `bright_green`, `bright_yellow`, `bright_blue`, `bright_magenta`, `bright_cyan`, `bright_white`

### Text Decorations

```lua
print(term.bold("Important message"))
print(term.dim("Less important"))
print(term.italic("Emphasized text"))
print(term.underline("Underlined text"))
print(term.strikethrough("Deprecated"))
```

### Background Colors

```lua
print(term.bg_red(term.white(" ERROR ")))
print(term.bg_green(term.black(" OK ")))
print(term.bg_yellow(term.black(" WARN ")))
print(term.bg_blue(term.white(" INFO ")))
```

Available: `bg_black`, `bg_red`, `bg_green`, `bg_yellow`, `bg_blue`, `bg_magenta`, `bg_cyan`, `bg_white`

### Composing Styles

Styles are just strings, so you can nest and combine them:

```lua
-- Bold red text
print(term.bold(term.red("Error!")))

-- Yellow text on blue background
print(term.bg_blue(term.yellow("Highlighted")))

-- Build status line
local status = term.bold("[") ..
    term.green("PASS") .. " " ..
    term.red("FAIL") .. " " ..
    term.yellow("SKIP") ..
    term.bold("]")
print(status)
```

### RGB and 256-Color

```lua
-- True color (24-bit RGB)
print(term.rgb(255, 128, 0, "Orange text"))
print(term.bg_rgb(0, 0, 128, "Navy background"))

-- 256-color palette
print(term.color256(196, "Color 196"))
print(term.bg_color256(57, "Background 57"))
```

### Stripping Colors

Remove all ANSI codes for plain text output (log files, etc.):

```lua
local colored = term.bold(term.red("Error: ")) .. "something failed"
local plain = term.strip(colored)
-- plain = "Error: something failed"
```

## Interactive Input

The `console` module provides functions for getting user input.

### Prompt

Read a line of text from the user:

```lua
local name = console.prompt("Enter your name: ")
print("Hello, " .. name)

-- With default value
local host = console.prompt("Host: ", "localhost")
local port = console.prompt("Port: ", "3000")
```

### Password

Read input without displaying it (characters are hidden):

```lua
local password = console.password("Password: ")
local confirm = console.password("Confirm password: ")

if password ~= confirm then
    print(term.red("Passwords do not match"))
    process.exit(1)
end
```

### Confirm

Ask a yes/no question:

```lua
if console.confirm("Delete all data?") then
    -- user typed y/yes
    db:exec("DELETE FROM users")
end

-- With default (Y/n means default is yes)
if console.confirm("Continue?", true) then
    -- user pressed Enter (defaults to yes)
end
```

### Select

Let the user pick from a list:

```lua
local idx, value = console.select("Choose environment:", {
    "development",
    "staging",
    "production",
})
print("Selected: " .. value .. " (index " .. idx .. ")")
```

Output:
```
Choose environment:
  1) development
  2) staging
  3) production
> _
```

### Multi-Select

Let the user pick multiple items:

```lua
local indices, values = console.multiselect("Select features:", {
    "Authentication",
    "Database",
    "Redis cache",
    "Email sending",
})

for _, feature in ipairs(values) do
    print("  Installing: " .. feature)
end
```

## Terminal Control

### Screen and Cursor

```lua
-- Clear screen
term.clear()

-- Clear just the current line
term.clear_line()

-- Move cursor
term.cursor_to(1, 1)       -- top-left (1-indexed)
term.cursor_up(2)           -- move up 2 lines
term.cursor_down(1)         -- move down 1 line

-- Hide cursor (for animations/progress)
term.cursor_hide()
-- ... do work ...
term.cursor_show()

-- Save and restore position
term.cursor_save()
-- move and write elsewhere
term.cursor_restore()
```

### Terminal Info

```lua
local width, height = term.size()
print("Terminal: " .. width .. " x " .. height)

if term.is_tty() then
    -- Running in a real terminal, safe to use colors
    print(term.green("Interactive mode"))
else
    -- Output is piped or redirected
    print("Non-interactive mode")
end
```

## Practical Examples

### Progress Indicator

```lua
local items = {"users", "posts", "comments", "tags"}

for i, item in ipairs(items) do
    io.write("\r" .. term.yellow("Processing: ") .. item ..
        term.dim(" [" .. i .. "/" .. #items .. "]") .. "   ")
    io.flush()
    time.sleep(500) -- simulate work
end
print("\r" .. term.green("Done!") .. string.rep(" ", 40))
```

### Log Formatter

```lua
local function log(level, message)
    local colors = {
        error = "red",
        warn = "yellow",
        info = "blue",
        debug = "gray",
    }

    local color_fn = term[colors[level]] or term.white
    local timestamp = time.format(time.now(), "%H:%M:%S")

    print(
        term.dim(timestamp) .. " " ..
        color_fn(string.pad_right(level:upper(), 5)) .. " " ..
        message
    )
end

log("info", "Server starting on port 3000")
log("debug", "Loading configuration")
log("warn", "Cache miss for key user:42")
log("error", "Connection refused: database")
```

### Table Display

```lua
local function print_table(headers, rows)
    -- Calculate column widths
    local widths = {}
    for i, h in ipairs(headers) do
        widths[i] = #h
    end
    for _, row in ipairs(rows) do
        for i, cell in ipairs(row) do
            widths[i] = math.max(widths[i] or 0, #tostring(cell))
        end
    end

    -- Print header
    local header_line = ""
    for i, h in ipairs(headers) do
        header_line = header_line .. string.pad_right(h, widths[i] + 2)
    end
    print(term.bold(header_line))
    print(string.rep("-", #header_line))

    -- Print rows
    for _, row in ipairs(rows) do
        local line = ""
        for i, cell in ipairs(row) do
            line = line .. string.pad_right(tostring(cell), widths[i] + 2)
        end
        print(line)
    end
end

print_table(
    {"Name", "Role", "Status"},
    {
        {"Alice", "Admin", "Active"},
        {"Bob", "User", "Active"},
        {"Charlie", "User", "Inactive"},
    }
)
```

### Admin Script

```lua
print(term.bold("Database Admin Tool"))
print()

local _, action = console.select("Action:", {
    "List users",
    "Create user",
    "Reset password",
    "Export data",
})

if action == "List users" then
    local users = db:query("SELECT id, name, email, role FROM users")
    for _, u in ipairs(users) do
        local role_color = u.role == "admin" and term.yellow or term.dim
        print("  " .. term.bold("#" .. u.id) .. " " .. u.name ..
            " " .. term.dim(u.email) .. " " .. role_color(u.role))
    end

elseif action == "Create user" then
    local name = console.prompt("Name: ")
    local email = console.prompt("Email: ")
    local password = console.password("Password: ")

    db:execute("INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)",
        name, email, crypto.sha256(password))
    print(term.green("User created!"))

elseif action == "Reset password" then
    local email = console.prompt("User email: ")
    local new_pass = console.password("New password: ")

    if console.confirm("Reset password for " .. email .. "?") then
        db:execute("UPDATE users SET password_hash = ? WHERE email = ?",
            crypto.sha256(new_pass), email)
        print(term.green("Password reset!"))
    end

elseif action == "Export data" then
    local users = db:query("SELECT * FROM users")
    local data = json.pretty(users)
    fs.write("export.json", data)
    print(term.green("Exported " .. #users .. " users to export.json"))
end
```

## Next Steps

- [Configuration](/docs/backend-services/configuration) - Environment variables and config
- [REST APIs](/docs/backend-services/rest-api) - Build API services
- [Built-in Modules](/docs/coppermoon/built-in-modules) - Full module reference
