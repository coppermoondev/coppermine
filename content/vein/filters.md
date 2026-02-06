# Filters

Filters transform values in template output. They are applied with the pipe `|` syntax and can be chained.

## Syntax

```html
{{ value | filter }}
{{ value | filter(arg1, arg2) }}
{{ value | filter1 | filter2 | filter3 }}
```

Filters are processed left to right. The output of each filter becomes the input of the next.

```html
{{ "  <b>Hello World</b>  " | trim | striptags | upper }}
{# Result: "HELLO WORLD" #}
```

## String Filters

### upper

Convert to uppercase.

```html
{{ "hello" | upper }}
{# "HELLO" #}
```

### lower

Convert to lowercase.

```html
{{ "HELLO" | lower }}
{# "hello" #}
```

### capitalize

Capitalize the first letter.

```html
{{ "hello world" | capitalize }}
{# "Hello world" #}
```

### title

Capitalize the first letter of each word.

```html
{{ "hello world" | title }}
{# "Hello World" #}
```

### trim

Remove leading and trailing whitespace.

```html
{{ "  hello  " | trim }}
{# "hello" #}
```

### truncate(length, suffix)

Truncate to a maximum byte length, appending a suffix (default `"..."`).

```html
{{ "Hello World" | truncate(8) }}
{# "Hello..." #}

{{ "Hello World" | truncate(8, "~") }}
{# "Hello W~" #}
```

### truncatewords(count)

Truncate to a maximum number of words.

```html
{{ "The quick brown fox jumps" | truncatewords(3) }}
{# "The quick brown..." #}
```

### striptags

Remove all HTML tags.

```html
{{ "<p>Hello <b>World</b></p>" | striptags }}
{# "Hello World" #}
```

### nl2br

Convert newlines to `<br>` tags.

```html
{{ "Line 1\nLine 2\nLine 3" | nl2br }}
{# "Line 1<br>Line 2<br>Line 3" #}
```

### replace(search, replacement)

Replace all occurrences.

```html
{{ "hello world" | replace("world", "Lua") }}
{# "hello Lua" #}
```

### split(separator)

Split a string into an array.

```html
{% set parts = "a,b,c" | split(",") %}
{% for part in parts do %}
    {{ part }}
{% end %}
```

### reverse

Reverse a string (or array).

```html
{{ "hello" | reverse }}
{# "olleh" #}
```

### slug

Convert to a URL-friendly slug.

```html
{{ "Hello World!" | slug }}
{# "hello-world" #}
```

### padleft(width, char) / lpad

Pad string to the left.

```html
{{ "42" | padleft(5, "0") }}
{# "00042" #}
```

### padright(width, char) / rpad

Pad string to the right.

```html
{{ "hi" | padright(10, ".") }}
{# "hi........" #}
```

### center(width, char)

Center a string within a given width.

```html
{{ "hi" | center(10) }}
{# "    hi    " #}
```

## Escaping Filters

### escape / e

HTML-escape special characters. This is applied automatically on `{{ }}` output when `autoEscape` is enabled.

```html
{{ "<script>alert('xss')</script>" | escape }}
{# "&lt;script&gt;alert('xss')&lt;/script&gt;" #}
```

### url

URL-encode a string.

```html
{{ "hello world" | url }}
{# "hello%20world" #}
```

### urldecode

URL-decode a string.

```html
{{ "hello%20world" | urldecode }}
{# "hello world" #}
```

### json

Encode a value as JSON.

```html
{{ data | json }}
{# '{"name":"Alice","age":30}' #}
```

## Number Filters

### number(decimals, decSep, thousandSep)

Format a number with grouping.

```html
{{ 1234567.89 | number(2) }}
{# "1,234,567.89" #}

{{ 1234.5 | number(2, ",", ".") }}
{# "1.234,50" #}
```

### currency(symbol)

Format as currency.

```html
{{ 99.99 | currency("$") }}
{# "$99.99" #}

{{ 49.9 | currency("EUR ") }}
{# "EUR 49.90" #}
```

### percent(decimals)

Format as percentage.

```html
{{ 0.85 | percent }}
{# "85%" #}

{{ 0.8567 | percent(1) }}
{# "85.7%" #}
```

### bytes(decimals)

Format as human-readable file size.

```html
{{ 1024 | bytes }}
{# "1.00 KB" #}

{{ 1048576 | bytes(0) }}
{# "1 MB" #}
```

### round(decimals)

Round a number.

```html
{{ 3.7 | round }}
{# 4 #}

{{ 3.14159 | round(2) }}
{# 3.14 #}
```

### floor

Round down.

```html
{{ 3.9 | floor }}
{# 3 #}
```

### ceil

Round up.

```html
{{ 3.1 | ceil }}
{# 4 #}
```

### abs

Absolute value.

```html
{{ -42 | abs }}
{# 42 #}
```

## Date Filters

### date(format)

Format a timestamp. Uses `os.date` format strings.

```html
{{ timestamp | date }}
{# "2025-02-04" #}

{{ timestamp | date("%d/%m/%Y") }}
{# "04/02/2025" #}
```

### datetime

Format as date and time.

```html
{{ timestamp | datetime }}
{# "2025-02-04 14:30:45" #}
```

### time

Format as time only.

```html
{{ timestamp | time }}
{# "14:30:45" #}
```

### timeago / ago

Display a relative time.

```html
{{ pastTimestamp | timeago }}
{# "5 minutes ago" #}

{{ futureTimestamp | ago }}
{# "in 3 hours" #}
```

## Array & Table Filters

### length / count

Get the length of an array or string.

```html
{{ items | length }}
{# 5 #}
```

### first

Get the first element.

```html
{{ items | first }}
```

### last

Get the last element.

```html
{{ items | last }}
```

### join(separator)

Join array elements into a string.

```html
{{ tags | join(", ") }}
{# "lua, web, template" #}
```

### sort(key)

Sort an array. Optionally sort objects by a key.

```html
{{ numbers | sort }}
{{ users | sort("name") }}
```

### keys

Get all keys of a table.

```html
{% set k = config | keys %}
```

### values

Get all values of a table.

```html
{% set v = config | values %}
```

### slice(start, stop)

Get a sub-array.

```html
{{ items | slice(1, 3) }}
```

### pluck(key)

Extract a single property from each object in an array.

```html
{{ users | pluck("name") | join(", ") }}
{# "Alice, Bob, Charlie" #}
```

### groupby(key)

Group an array of objects by a property.

```html
{% set grouped = posts | groupby("category") %}
{% for category, posts in pairs(grouped) do %}
    <h2>{{ category }}</h2>
    {% for post in posts do %}
        <p>{{ post.title }}</p>
    {% end %}
{% end %}
```

## Conditional Filters

### default(value) / d

Use a default value when the input is nil or empty.

```html
{{ user.nickname | default(user.name) }}
{{ subtitle | d("No subtitle") }}
```

### ternary(trueValue, falseValue)

Output one of two values based on truthiness.

```html
{{ user.active | ternary("Active", "Inactive") }}
```

## Debug Filters

### dump

Pretty-print a value for debugging.

```html
<pre>{{ data | dump }}</pre>
```

### typeof

Get the Lua type name.

```html
{{ value | typeof }}
{# "table" #}
```

## Custom Filters

Register your own filters on the engine:

```lua
local engine = vein.new({ views = "./views" })

engine:filter("double", function(value)
    return value * 2
end)

engine:filter("wrap", function(value, tag)
    tag = tag or "span"
    return "<" .. tag .. ">" .. tostring(value) .. "</" .. tag .. ">"
end)
```

Use them like built-in filters:

```html
{{ price | double | currency("$") }}
{{ username | wrap("strong") }}
```
