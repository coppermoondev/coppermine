# Vein

> **A powerful, Lua-inspired templating engine for CopperMoon**

Vein is a full-featured templating engine with Lua-style control flow, filter pipelines, template inheritance, components, partials, and first-class HoneyMoon integration. It includes a metrics system for performance monitoring and source map support for debugging.

## Features

- 🎯 **Lua-native syntax** — `{% if %}`, `{% for %}`, Lua expressions
- 🔗 **Filter pipelines** — `{{ name | upper | truncate(20) }}`
- 📐 **Template inheritance** — `{% extends "base" %}` with blocks
- 🧩 **Components** — reusable, slottable components
- 📁 **Partials & includes** — `{@ include "header" @}`
- 🛡️ **Auto-escaping** — HTML-safe output by default
- ⚡ **Compiled templates** — templates compile to Lua functions
- 💾 **Template caching** — LRU cache for compiled templates
- 📊 **Metrics** — render times, cache rates, filter usage
- 🗺️ **Source maps** — map errors back to template lines

## Installation

```bash
harbor install vein
```

## Quick Start

```lua
local vein = require("vein")

-- Quick one-off render
local html = vein.render("Hello, {{ name }}!", { name = "World" })
print(html)  -- "Hello, World!"

-- Engine with configuration
local engine = vein.new({
    views = "./views",
    cache = true,
})

local html = engine:render("home", {
    title = "Welcome",
    items = { "Alpha", "Beta", "Gamma" },
})
```

## Template Syntax

### Output

```html
<!-- Escaped output (auto HTML-escape) -->
{{ user.name }}
{{ price | currency("$") }}

<!-- Raw/unescaped output -->
{! rawHtml !}

<!-- Comments (not rendered) -->
{# This is a comment #}
```

### Control Flow

```html
<!-- If/else -->
{% if user then %}
    <p>Hello, {{ user.name }}!</p>
{% elseif guest then %}
    <p>Hello, guest!</p>
{% else %}
    <p>Please log in.</p>
{% end %}

<!-- For loops -->
{% for item in items do %}
    <li>{{ item }}</li>
{% end %}

{% for i = 1, 10 do %}
    <span>{{ i }}</span>
{% end %}

<!-- While -->
{% while condition do %}
    ...
{% end %}

<!-- Local variables -->
{% set greeting = "Hello, " .. name %}
{{ greeting }}
```

### Filters

Filters transform output values using the pipe (`|`) syntax:

```html
{{ name | upper }}
{{ text | truncate(100) }}
{{ price | currency("$") }}
{{ items | join(", ") }}
{{ content | striptags | truncate(200, "…") }}
```

#### Built-in Filters

**Escaping & Encoding:**

| Filter | Description |
|--------|-------------|
| `escape` / `e` / `html` | HTML escape |
| `url` / `urlencode` | URL encode |
| `urldecode` | URL decode |
| `json` | JSON encode |

**String Transformations:**

| Filter | Description |
|--------|-------------|
| `upper` / `uppercase` | Uppercase |
| `lower` / `lowercase` | Lowercase |
| `capitalize` | Capitalize first letter |
| `title` | Title Case |
| `trim` | Trim whitespace |
| `striptags` | Strip HTML tags |
| `nl2br` | Newlines to `<br>` |
| `truncate(len, suffix?)` | Truncate to length |
| `truncatewords(count, suffix?)` | Truncate by word count |
| `padleft(len, char?)` / `lpad` | Pad left |
| `padright(len, char?)` / `rpad` | Pad right |
| `center(len, char?)` | Center string |
| `replace(search, replace)` | String replace |
| `split(delimiter?)` | Split to array |
| `reverse` | Reverse string |
| `slug` / `slugify` | URL-safe slug |

**Number Formatting:**

| Filter | Description |
|--------|-------------|
| `number(decimals?, decSep?, thousandsSep?)` | Format number |
| `currency(symbol?, decimals?)` / `money` | Format currency |
| `percent(decimals?)` | Format percentage |
| `bytes(decimals?)` / `filesize` | Format bytes (KB, MB, GB) |
| `round(decimals?)` | Round |
| `floor` | Floor |
| `ceil` | Ceiling |
| `abs` | Absolute value |

**Date & Time:**

| Filter | Description |
|--------|-------------|
| `date(format?)` | Format date |
| `datetime(format?)` | Format datetime |
| `time(format?)` | Format time |
| `timeago` / `ago` | Relative time ("5 minutes ago") |

**Arrays & Tables:**

| Filter | Description |
|--------|-------------|
| `length` / `count` / `size` | Get length |
| `first` | First element |
| `last` | Last element |
| `join(separator?)` | Join array to string |
| `sort(key?)` | Sort array |
| `keys` | Get table keys |
| `values` | Get table values |
| `slice(start, stop?)` | Slice array |
| `pluck(key)` | Extract key from array of tables |
| `groupby(key)` | Group by key |

**Conditional:**

| Filter | Description |
|--------|-------------|
| `default(value)` / `d` | Default if nil/empty |
| `ternary(trueVal, falseVal)` | Conditional value |

**Debug:**

| Filter | Description |
|--------|-------------|
| `dump` | Debug dump in `<pre>` tag |
| `typeof` | Get type name |

#### Custom Filters

```lua
engine:filter("initials", function(name)
    local parts = {}
    for word in name:gmatch("%S+") do
        table.insert(parts, word:sub(1, 1):upper())
    end
    return table.concat(parts)
end)

-- Usage: {{ "John Doe" | initials }}  →  "JD"
```

### Template Inheritance

**base.vein:**
```html
<!DOCTYPE html>
<html>
<head>
    <title>{% block title %}Default Title{% endblock %}</title>
</head>
<body>
    <nav>{% block nav %}...{% endblock %}</nav>
    <main>{% block content %}{% endblock %}</main>
    <footer>{% block footer %}© 2024{% endblock %}</footer>
</body>
</html>
```

**home.vein:**
```html
{% extends "layouts/base" %}

{% block title %}Home Page{% endblock %}

{% block content %}
    <h1>Welcome!</h1>
    <p>This is the home page.</p>
{% endblock %}
```

### Includes & Partials

```html
<!-- Include another template (shares context) -->
{@ include "header" @}

<!-- Render a partial with specific data -->
{> partial "user-card" { name = user.name, avatar = user.avatar } >}
```

### Components

```lua
-- Register a component
engine:component("alert", [[
    <div class="alert alert-{{ variant | default("info") }}">
        {{ slot }}
    </div>
]])
```

```html
{% component "alert" { variant = "success" } %}
    Operation completed!
{% endcomponent %}
```

## HoneyMoon Integration

```lua
local honeymoon = require("honeymoon")
local vein = require("vein")

local app = honeymoon.new()

-- Configure view engine
app.views:use("vein")
app.views:set({
    views = "./views",
    layouts = "./views/layouts",
    partials = "./views/partials",
    cache = true,
})

-- Add global template variables
app.views:global("siteName", "My App")
app.views:global("year", os.date("%Y"))

-- Add custom filters
app.views:filter("highlight", function(text, term)
    return text:gsub(term, "<mark>" .. term .. "</mark>")
end)

-- Render in routes
app:get("/", function(req, res)
    res:render("home", {
        title = "Welcome",
        users = User:findAll(),
    })
end)

app:listen(3000)
```

## Metrics

Enable metrics to track template performance:

```lua
local engine = vein.new({ metrics = true })

-- After some renders...
local summary = engine:getMetricsSummary()
print(summary.renders.total)       -- Total render count
print(summary.renders.totalTime)   -- Total render time (ms)
print(summary.cache.hitRate)       -- Cache hit rate (0-100)

-- Detailed export
local all = engine:exportMetrics()
-- all.renders, all.compilations, all.cache, all.includes, all.errors

-- Reset
engine:resetMetrics()
```

Metrics integrate with [Lantern](https://github.com/coppermoondev/lantern) for in-browser visualization.

## Engine API Reference

### Constructor

```lua
local engine = vein.new({
    views = "./views",              -- Template directory
    partials = "./views/partials",  -- Partials directory
    layouts = "./views/layouts",    -- Layouts directory
    components = "./views/components", -- Components directory
    extension = ".vein",            -- File extension
    cache = true,                   -- Enable caching
    cacheLimit = 100,               -- Max cached templates
    debug = false,                  -- Debug mode (detailed errors)
    autoEscape = true,              -- Auto HTML-escape output
    metrics = false,                -- Enable metrics
    fragments = false,              -- Fragment support
    sourceMap = false,              -- Source map generation
    globals = {},                   -- Global template variables
})
```

### Methods

| Method | Description |
|--------|-------------|
| `engine:render(name, data?)` | Render a template file |
| `engine:renderString(template, data?)` | Render a template string |
| `engine:compile(name)` | Pre-compile a template |
| `engine:compileString(template)` | Pre-compile a string |
| `engine:global(key, value)` | Add global variable |
| `engine:filter(name, fn)` | Register a filter |
| `engine:component(name, template)` | Register a component |
| `engine:helper(name, fn)` | Register a helper function |
| `engine:set(key, value)` | Set configuration option |
| `engine:clearCache()` | Clear template cache |
| `engine:getMetrics()` | Get metrics collector |
| `engine:enableMetrics()` | Enable metrics |
| `engine:disableMetrics()` | Disable metrics |

### Convenience

```lua
-- Quick one-off render (no engine needed)
vein.render("Hello {{ name }}", { name = "World" })

-- Express-style engine factory
local renderFn = vein.express({ views = "./views" })
```

## Related

- [CopperMoon](https://github.com/coppermoondev/coppermoon) — The Lua runtime
- [Harbor](https://github.com/coppermoondev/harbor) — Package manager (`harbor install vein`)
- [HoneyMoon](https://github.com/coppermoondev/honeymoon) — Web framework
- [Lantern](https://github.com/coppermoondev/lantern) — Debug toolbar (visualizes Vein metrics)
- [Tailwind](https://github.com/coppermoondev/tailwind) — TailwindCSS integration

## Documentation

For full documentation, visit [coppermoon.dev](https://coppermoon.dev).

## License

MIT License — CopperMoon Contributors
