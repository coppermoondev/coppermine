# HoneyMoon Integration

Vein integrates directly with HoneyMoon, the CopperMoon web framework. This page explains how to set up and use Vein as the view engine for your HoneyMoon application.

## Setup

Configure Vein through the `app.views` interface:

```lua
local honeymoon = require("honeymoon")
local vein = require("vein")

local app = honeymoon.new()

-- Register Vein as the view engine
app.views:use("vein")

-- Configure view settings
app.views:set("views", "./views")
app.views:set("cache", false)     -- Disable cache during development
app.views:set("debug", true)      -- Enable debug mode
```

## Rendering Pages

Use `res:render()` in your route handlers to render a Vein template:

```lua
app:get("/", function(req, res)
    res:render("pages/home", {
        title = "Home",
        user = req.session.user,
    })
end)
```

The first argument is the template path relative to the `views` directory (without the `.vein` extension). The second argument is the data context passed to the template.

## Global Template Variables

Set variables that are available in every template:

```lua
app.views:global("site", {
    name = "My App",
    tagline = "Built with CopperMoon",
    version = "1.0.0",
})

app.views:global("year", os.date("%Y"))
```

Access them in any template:

```html
<title>{{ title }} - {{ site.name }}</title>
<footer>&copy; {{ year }} {{ site.name }}</footer>
```

## Custom Filters

Register filters through the views interface:

```lua
app.views:filter("markdown", function(text)
    -- Convert markdown to HTML
    return markdownToHtml(text)
end)

app.views:filter("excerpt", function(text, length)
    length = length or 200
    if #text <= length then return text end
    return text:sub(1, length) .. "..."
end)
```

Use them in templates:

```html
{! post.content | markdown !}
<p>{{ post.body | excerpt(150) }}</p>
```

## Complete Example

Here is how CopperMine (this documentation site) is configured:

### Application setup

```lua
local honeymoon = require("honeymoon")
local vein = require("vein")
local tailwind = require("tailwind")
local lantern = require("lantern")

local app = honeymoon.new()

-- Configuration
app:set("env", os_ext.env("NODE_ENV") or "development")
app.views:use("vein")
app.views:set("views", "./views")
app.views:set("cache", false)
app.views:set("debug", true)
app.views:set("metrics", true)

-- Tailwind CSS
local tailwindConfig = tailwind.preset("coppermoon")
tailwindConfig.cdn = { plugins = {"typography"} }
tailwind.setup(app, tailwindConfig)

-- Global variables
app.views:global("site", {
    name = "CopperMine",
    tagline = "Documentation for CopperMoon Ecosystem",
    version = "0.1.0",
})

-- Custom markdown filter
app.views:filter("markdown", function(text)
    -- Convert markdown to HTML...
    return html
end)

-- Middleware
app:use(honeymoon.logger())
app:use(honeymoon.responseTime())
app:use(honeymoon.helmet())
app:use(honeymoon.cors())
app:use("/public", honeymoon.static("./public"))

-- Lantern debug toolbar
lantern.setup(app, {
    enabled = app:get_setting("env") ~= "production",
    vein = app.views.engine,
})
```

### Route handler

```lua
app:get("/docs/:section/:page", function(req, res)
    local sectionId = req.params.section
    local pageId = req.params.page

    -- Load markdown content from file
    local contentPath = "./content/" .. sectionId .. "/" .. pageId .. ".md"
    local ok, content = pcall(fs.read, contentPath)
    if not ok then
        return res:status(404):render("pages/404")
    end

    res:render("pages/doc", {
        title = page.title,
        currentSection = section,
        currentPage = page,
        content = content,
    })
end)
```

### Template

```html
{# views/pages/doc.vein #}
{% extends "layouts/base" %}

{! content !}
    <div class="sidebar">
        {% for section in docs.sections do %}
            <h3>{{ section.title }}</h3>
            <ul>
            {% for page in section.pages do %}
                <li>
                    <a href="/docs/{{ section.id }}/{{ page.id }}">
                        {{ page.title }}
                    </a>
                </li>
            {% end %}
            </ul>
        {% end %}
    </div>

    <div class="content prose">
        {! content | markdown !}
    </div>
{! end !}
```

## Metrics and Debugging

Enable metrics to track template rendering performance:

```lua
app.views:set("metrics", true)
```

When combined with Lantern (the debug toolbar), you get a visual panel showing:

- Which templates were rendered
- Compilation and render times
- Template cache status

Pass the Vein engine to Lantern:

```lua
lantern.setup(app, {
    enabled = true,
    vein = app.views.engine,
})
```

## Express-Style API

For advanced use cases, you can create a Vein view engine directly:

```lua
local vein = require("vein")

local viewEngine = vein.express({
    views = "./views",
    layouts = "./views/layouts",
    components = "./views/components",
    cache = true,
    debug = false,
})
```

The express adapter returns a function with the signature `viewEngine(filepath, data, callback)` that can be plugged into any Express-style framework.

## Tips

- Disable cache during development (`app.views:set("cache", false)`) so template changes are reflected immediately without restarting the server.
- Use global variables for data that every page needs (site name, navigation, current year).
- Register custom filters for domain-specific transformations (markdown rendering, date formatting, currency).
- Enable Lantern in development to debug template rendering issues.
