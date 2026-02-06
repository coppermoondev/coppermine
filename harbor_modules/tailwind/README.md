# Tailwind

> **TailwindCSS integration for HoneyMoon / CopperMoon**

Tailwind provides seamless TailwindCSS integration for HoneyMoon web applications. It supports the Play CDN for development, custom theme configuration, preset themes (including a CopperMoon brand theme), conditional class merging utilities, and pre-built component class helpers.

## Installation

```bash
harbor install tailwind
```

## Quick Start

```lua
local honeymoon = require("honeymoon")
local tailwind = require("tailwind")

local app = honeymoon.new()

-- One-line setup
tailwind.setup(app)

app:get("/", function(req, res)
    res:render("index", { title = "My App" })
end)

app:listen(3000)
```

In your Vein template, include `{! __tailwind_head !}` in the `<head>`:

```html
<!DOCTYPE html>
<html>
<head>
    {! __tailwind_head !}
</head>
<body class="bg-black text-white">
    <h1 class="text-4xl font-bold text-copper-500">{{ title }}</h1>
</body>
</html>
```

## Configuration

```lua
tailwind.setup(app, {
    mode = "cdn",               -- "cdn" (Play CDN) or "build" (compiled CSS)
    darkMode = "class",         -- "media" or "class"

    cdn = {
        url = "https://cdn.tailwindcss.com",
        version = "3.4",
        plugins = { "forms", "typography" },  -- CDN plugins
    },

    theme = {
        extend = {
            colors = {
                primary = "#c97c3c",
                secondary = "#1e1e2e",
            },
            fontFamily = {
                sans = { "Inter", "system-ui", "sans-serif" },
            },
        },
    },

    safelist = { "bg-red-500", "text-green-400" },  -- Always include these classes
})
```

## Preset Themes

```lua
-- CopperMoon branded theme (default)
tailwind.setup(app, tailwind.preset("coppermoon"))

-- Vercel-inspired minimal dark theme
tailwind.setup(app, tailwind.preset("vercel"))

-- Nothing Phone inspired
tailwind.setup(app, tailwind.preset("nothing"))
```

The `coppermoon` preset includes copper brand colors, Inter + JetBrains Mono fonts, and fade-in/slide-up animations.

## Usage Modes

### CDN Mode (Development)

Injects the Tailwind Play CDN script tag with your configuration. No build step required.

```lua
tailwind.setup(app, { mode = "cdn" })
```

### Build Mode (Production)

References a pre-compiled CSS file:

```lua
tailwind.setup(app, {
    mode = "build",
    build = {
        input = "./src/input.css",
        output = "./public/css/tailwind.css",
        content = { "./views/**/*.vein", "./views/**/*.html" },
        minify = true,
    },
})
```

## Manual Usage

If you don't want the middleware, generate head tags manually:

```lua
-- Get the script/link tags
local headHtml = tailwind.head({ mode = "cdn" })

-- Or just the CDN script
local scriptHtml = tailwind.cdn_script({ theme = { ... } })

-- Pass to templates
app.views:global("tailwind", headHtml)
```

## Class Utilities

### Conditional Classes

Merge class strings with conditional logic — similar to `clsx` / `cn` in the JavaScript ecosystem:

```lua
local tw = require("tailwind")

-- Simple merge
tw.classes("px-4 py-2", "bg-blue-500", "text-white")
-- "px-4 py-2 bg-blue-500 text-white"

-- Conditional classes
tw.classes("btn", {
    ["bg-blue-500"] = true,
    ["bg-gray-500"] = false,
    ["opacity-50"] = isDisabled,
})

-- Aliases
tw.cn(...)    -- Same as classes
tw.cx(...)    -- Same as classes
tw.clsx(...)  -- Same as classes
```

### Pre-built Component Classes

```lua
local tw = require("tailwind")

-- Buttons
tw.components.btn                -- Base button classes
tw.components.btn_primary        -- Primary variant
tw.components.btn_secondary      -- Secondary variant
tw.components.btn_ghost          -- Ghost variant

-- Cards
tw.components.card               -- Card container
tw.components.card_title         -- Card title
tw.components.card_description   -- Card description

-- Inputs
tw.components.input              -- Input field

-- Layout
tw.components.container          -- Centered container with padding
tw.components.section            -- Section with vertical padding

-- Typography
tw.components.heading_1          -- h1 styles
tw.components.heading_2          -- h2 styles
tw.components.heading_3          -- h3 styles
tw.components.prose              -- Prose content
```

### Component Helpers (with variants)

The `tailwind.lib.components` module provides parameterized component classes:

```lua
local components = require("tailwind.lib.components")

-- Buttons with variant and size
components.btn("primary", "md")   -- Primary, medium
components.btn("danger", "lg")    -- Danger, large
components.btn("ghost", "sm")     -- Ghost, small

-- Cards with variant and padding
components.cardClass("default", "md")
components.cardClass("interactive", "lg")
components.cardClass("elevated", "sm")

-- Inputs with variant and size
components.inputClass("default", "md")
components.inputClass("filled", "lg")

-- Badges with variant and size
components.badgeClass("success", "sm")
components.badgeClass("danger", "md")

-- Alerts
components.alertClass("warning")
components.alertClass("info")

-- Layout helpers
components.layout.container
components.layout.stack_md
components.layout.center

-- Typography
components.typography.h1
components.typography.body
components.typography.lead
```

## Example: Full Page Template

```html
<!DOCTYPE html>
<html class="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    {! __tailwind_head !}
</head>
<body class="bg-black text-white min-h-screen">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
        <h1 class="text-4xl lg:text-5xl font-bold tracking-tight text-copper-500">
            {{ title }}
        </h1>
        <p class="text-lg text-zinc-400 mt-4">
            {{ description }}
        </p>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mt-12">
            {% for item in items do %}
            <div class="bg-zinc-900 border border-zinc-800 rounded-xl p-6 hover:border-copper-500/50 transition-all">
                <h3 class="text-xl font-medium text-white">{{ item.title }}</h3>
                <p class="text-sm text-zinc-400 mt-2">{{ item.description }}</p>
            </div>
            {% end %}
        </div>
    </div>
</body>
</html>
```

## Related

- [CopperMoon](https://github.com/coppermoondev/coppermoon) — The Lua runtime
- [Harbor](https://github.com/coppermoondev/harbor) — Package manager (`harbor install tailwind`)
- [HoneyMoon](https://github.com/coppermoondev/honeymoon) — Web framework
- [Vein](https://github.com/coppermoondev/vein) — Templating engine

## Documentation

For full documentation, visit [coppermoon.dev](https://coppermoon.dev).

## License

MIT License — CopperMoon Contributors
