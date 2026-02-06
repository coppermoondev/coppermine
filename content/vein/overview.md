# Vein Templating

Vein is the templating engine for CopperMoon. It compiles templates into Lua functions for fast rendering, and provides a clean syntax for outputting variables, control flow, template inheritance, components, and filters.

## Key Features

- **Lua-powered** - Templates compile to native Lua functions
- **Auto-escaping** - HTML output is escaped by default (XSS protection)
- **Template inheritance** - Layouts with blocks, extends, and slots
- **Components** - Reusable template pieces with slot support
- **50+ built-in filters** - String, number, date, array transformations
- **Custom delimiters** - Configurable syntax markers
- **Caching** - Compiled templates are cached for performance
- **Metrics** - Optional performance tracking for debugging

## Quick Example

```html
{% extends "layouts/base" %}

{% block content %}
    <h1>{{ title }}</h1>

    {% if posts then %}
        {% for post in posts do %}
            <article>
                <h2>{{ post.title }}</h2>
                <p>{{ post.excerpt | truncate(150) }}</p>
                <span>{{ post.published_at | timeago }}</span>
            </article>
        {% end %}
    {% else %}
        <p>No posts yet.</p>
    {% end %}
{% endblock %}
```

## Template Tags

Vein uses six types of delimiters:

| Tag | Purpose | Example |
|-----|---------|---------|
| `{{ }}` | Output (escaped) | `{{ user.name }}` |
| `{! !}` | Raw output (unescaped) | `{! htmlContent !}` |
| `{% %}` | Code / control flow | `{% if x then %}` |
| `{# #}` | Comments (not rendered) | `{# TODO #}` |
| `{@ @}` | Include template | `{@ include "header" @}` |
| `{> >}` | Render partial with data | `{> partial "card" { title = "Hi" } >}` |

## Creating an Engine

```lua
local vein = require("vein")

local engine = vein.new({
    views = "./views",
    layouts = "./views/layouts",
    components = "./views/components",
    extension = ".vein",
    cache = true,
    autoEscape = true,
    debug = false,
})
```

### Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `views` | `"./views"` | Directory containing template files |
| `layouts` | `nil` | Directory for layout templates |
| `components` | `nil` | Directory for component templates |
| `extension` | `".vein"` | File extension for templates |
| `cache` | `true` | Cache compiled templates |
| `cacheLimit` | `100` | Maximum cached templates |
| `autoEscape` | `true` | HTML-escape `{{ }}` output |
| `debug` | `false` | Enable debug mode |
| `metrics` | `false` | Enable performance tracking |
| `globals` | `{}` | Variables available in all templates |

## Rendering Templates

### From a file

```lua
local html = engine:render("pages/home", {
    title = "Welcome",
    user = { name = "Alice" },
})
```

The engine looks for `./views/pages/home.vein` (path relative to `views` directory, extension added automatically).

### From a string

```lua
local html = engine:renderString("Hello {{ name }}!", { name = "World" })
-- "Hello World!"
```

### One-off render

```lua
local vein = require("vein")
local html = vein.render("{{ x + y }}", { x = 1, y = 2 })
-- "3"
```

## Global Variables

Set variables available in every template:

```lua
-- Single value
engine:global("siteName", "My App")

-- Multiple values
engine:global({
    siteName = "My App",
    version = "1.0",
    year = os.date("%Y"),
})
```

Access in templates:

```html
<footer>&copy; {{ year }} {{ siteName }} v{{ version }}</footer>
```

## Custom Filters

Register filters to transform output:

```lua
engine:filter("shout", function(value)
    return string.upper(value) .. "!!!"
end)

engine:filter("formatPrice", function(price, currency)
    currency = currency or "$"
    return currency .. string.format("%.2f", price)
end)
```

Use in templates:

```html
{{ greeting | shout }}
{{ product.price | formatPrice("EUR ") }}
```

## Custom Helpers

Register helper functions callable from template code:

```lua
engine:helper("formatDate", function(timestamp, format)
    return os.date(format or "%Y-%m-%d", timestamp)
end)
```

Use in templates:

```html
{% set formatted = formatDate(post.created_at, "%d/%m/%Y") %}
<span>{{ formatted }}</span>
```

## How It Works

Vein compiles templates through three stages:

1. **Tokenize** - Parse template string into tokens (TEXT, OUTPUT, CODE, COMMENT, etc.)
2. **Generate** - Transform tokens into a Lua function as source code
3. **Compile** - Load the Lua source into an executable function

The compiled function receives a context table and returns the rendered HTML string. Compiled templates are cached, so subsequent renders skip compilation.

## Next Steps

- [Syntax](/docs/vein/syntax) - Complete syntax reference
- [Filters](/docs/vein/filters) - All 50+ built-in filters
- [Layouts](/docs/vein/layouts) - Template inheritance and blocks
- [Components](/docs/vein/components) - Reusable template components
- [HoneyMoon Integration](/docs/vein/integration) - Using Vein with HoneyMoon
