-- Tailwind CSS Integration for HoneyMoon/CopperMoon
-- Provides easy TailwindCSS integration with automatic class detection
--
-- Usage:
--   local tailwind = require("tailwind")
--   
--   -- In HoneyMoon app
--   app:use(tailwind.middleware({ mode = "cdn" }))
--   
--   -- Or with Play CDN (development)
--   app.views:global("tailwind", tailwind.head())
--
-- @module tailwind
-- @author CopperMoon Team
-- @license MIT

local tailwind = {}

--------------------------------------------------------------------------------
-- Version
--------------------------------------------------------------------------------

tailwind._VERSION = "0.1.0"
tailwind._DESCRIPTION = "TailwindCSS integration for HoneyMoon/CopperMoon"

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

local defaults = {
    -- Mode: "cdn" (Play CDN), "build" (compiled), "jit" (on-demand)
    mode = "cdn",
    
    -- CDN configuration
    cdn = {
        url = "https://cdn.tailwindcss.com",
        version = "3.4",
        plugins = {}, -- e.g., {"forms", "typography", "aspect-ratio"}
    },
    
    -- Build configuration
    build = {
        input = "./src/input.css",
        output = "./public/css/tailwind.css",
        content = {"./views/**/*.vein", "./views/**/*.html"},
        minify = true,
    },
    
    -- Custom theme extensions
    theme = {
        extend = {
            colors = {
                copper = {
                    ["50"] = "#fdf8f3",
                    ["100"] = "#f9ede0",
                    ["200"] = "#f2d7bc",
                    ["300"] = "#e8ba8e",
                    ["400"] = "#dc955d",
                    ["500"] = "#c97c3c",
                    ["600"] = "#b86830",
                    ["700"] = "#99522a",
                    ["800"] = "#7c4428",
                    ["900"] = "#653923",
                    ["950"] = "#361c10",
                },
            },
            fontFamily = {
                sans = {"Inter", "system-ui", "sans-serif"},
                mono = {"JetBrains Mono", "monospace"},
            },
        },
    },
    
    -- Safelist classes that should always be included
    safelist = {},
    
    -- Dark mode strategy: "media" or "class"
    darkMode = "class",
}

--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------

local function merge_tables(t1, t2)
    local result = {}
    for k, v in pairs(t1) do
        result[k] = v
    end
    for k, v in pairs(t2 or {}) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = merge_tables(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

local function table_to_js(tbl, indent)
    indent = indent or 0
    local spaces = string.rep("  ", indent)
    local parts = {}
    
    if #tbl > 0 then
        -- Array
        for _, v in ipairs(tbl) do
            if type(v) == "table" then
                table.insert(parts, table_to_js(v, indent + 1))
            elseif type(v) == "string" then
                table.insert(parts, '"' .. v .. '"')
            else
                table.insert(parts, tostring(v))
            end
        end
        return "[" .. table.concat(parts, ", ") .. "]"
    else
        -- Object
        for k, v in pairs(tbl) do
            local key = k
            if k:match("^%d") or k:match("-") then
                key = '["' .. k .. '"]'
            end
            
            if type(v) == "table" then
                table.insert(parts, spaces .. "  " .. key .. ": " .. table_to_js(v, indent + 1))
            elseif type(v) == "string" then
                table.insert(parts, spaces .. "  " .. key .. ': "' .. v .. '"')
            elseif type(v) == "boolean" then
                table.insert(parts, spaces .. "  " .. key .. ": " .. tostring(v))
            else
                table.insert(parts, spaces .. "  " .. key .. ": " .. tostring(v))
            end
        end
        return "{\n" .. table.concat(parts, ",\n") .. "\n" .. spaces .. "}"
    end
end

--------------------------------------------------------------------------------
-- CDN Mode
--------------------------------------------------------------------------------

--- Generate the Play CDN script tag with configuration
---@param config table Configuration options
---@return string HTML script tags
function tailwind.cdn_script(config)
    config = merge_tables(defaults, config)
    
    local parts = {}
    
    -- Main Tailwind CDN script
    local cdn_url = config.cdn.url
    if config.cdn.version then
        cdn_url = cdn_url .. "?v=" .. config.cdn.version
    end
    
    -- Add plugins if specified
    if config.cdn.plugins and #config.cdn.plugins > 0 then
        local plugins_param = table.concat(config.cdn.plugins, ",")
        if cdn_url:find("?") then
            cdn_url = cdn_url .. "&plugins=" .. plugins_param
        else
            cdn_url = cdn_url .. "?plugins=" .. plugins_param
        end
    end
    
    table.insert(parts, '<script src="' .. cdn_url .. '"></script>')
    
    -- Configuration script
    local theme_config = table_to_js(config.theme)
    local tailwind_config = string.format([[
<script>
tailwind.config = {
  darkMode: "%s",
  theme: %s
}
</script>]], config.darkMode, theme_config)
    
    table.insert(parts, tailwind_config)
    
    return table.concat(parts, "\n")
end

--- Generate head tags for Tailwind (alias for cdn_script in CDN mode)
---@param config table? Configuration options
---@return string HTML for head section
function tailwind.head(config)
    config = merge_tables(defaults, config)
    
    if config.mode == "cdn" then
        return tailwind.cdn_script(config)
    elseif config.mode == "build" then
        return '<link rel="stylesheet" href="' .. config.build.output:gsub("^%.", "") .. '">'
    else
        return tailwind.cdn_script(config)
    end
end

--------------------------------------------------------------------------------
-- HoneyMoon Middleware
--------------------------------------------------------------------------------

--- Create middleware that injects Tailwind into responses
---@param config table? Configuration options
---@return function Middleware function
function tailwind.middleware(config)
    config = merge_tables(defaults, config)
    
    return function(req, res, next)
        -- Store original render function
        local original_render = res.render
        
        -- Override render to inject Tailwind
        res.render = function(self, name, data)
            data = data or {}
            data.__tailwind = tailwind.head(config)
            return original_render(self, name, data)
        end
        
        next()
    end
end

--------------------------------------------------------------------------------
-- View Helpers
--------------------------------------------------------------------------------

--- Create a view helper for HoneyMoon
---@param app table HoneyMoon application
---@param config table? Configuration options
function tailwind.setup(app, config)
    config = merge_tables(defaults, config)
    
    -- Add middleware
    app:use(tailwind.middleware(config))
    
    -- Add global template variable
    app.views:global("__tailwind_head", tailwind.head(config))
    
    -- Add helper function
    app.views:helper("tailwind", function()
        return tailwind.head(config)
    end)
end

--------------------------------------------------------------------------------
-- Class Utilities
--------------------------------------------------------------------------------

--- Merge multiple class strings, filtering out falsy values
---@param ... string|table Class strings or tables
---@return string Merged class string
function tailwind.classes(...)
    local result = {}
    
    for _, arg in ipairs({...}) do
        if type(arg) == "string" and arg ~= "" then
            table.insert(result, arg)
        elseif type(arg) == "table" then
            for class, condition in pairs(arg) do
                if condition then
                    table.insert(result, class)
                end
            end
        end
    end
    
    return table.concat(result, " ")
end

--- Alias for classes
tailwind.cn = tailwind.classes
tailwind.cx = tailwind.classes
tailwind.clsx = tailwind.classes

--------------------------------------------------------------------------------
-- Preset Configurations
--------------------------------------------------------------------------------

tailwind.presets = {
    -- Minimal dark theme (like Vercel)
    vercel = {
        mode = "cdn",
        darkMode = "class",
        theme = {
            extend = {
                colors = {
                    background = "#000000",
                    foreground = "#fafafa",
                    muted = "#a1a1a1",
                    border = "#333333",
                    accent = "#0070f3",
                },
            },
        },
    },
    
    -- CopperMoon theme
    coppermoon = {
        mode = "cdn",
        darkMode = "class",
        theme = {
            extend = {
                colors = {
                    background = "#000000",
                    foreground = "#fafafa",
                    muted = "#a1a1a1",
                    border = "#222222",
                    copper = {
                        ["50"] = "#fdf8f3",
                        ["100"] = "#f9ede0",
                        ["200"] = "#f2d7bc",
                        ["300"] = "#e8ba8e",
                        ["400"] = "#dc955d",
                        ["500"] = "#c97c3c",
                        ["600"] = "#b86830",
                        ["700"] = "#99522a",
                        ["800"] = "#7c4428",
                        ["900"] = "#653923",
                        ["950"] = "#361c10",
                    },
                    accent = "#c97c3c",
                },
                fontFamily = {
                    sans = {"Inter", "system-ui", "sans-serif"},
                    mono = {"JetBrains Mono", "Fira Code", "monospace"},
                },
                animation = {
                    ["fade-in"] = "fadeIn 0.3s ease-out",
                    ["slide-up"] = "slideUp 0.3s ease-out",
                },
                keyframes = {
                    fadeIn = {
                        ["0%"] = { opacity = "0" },
                        ["100%"] = { opacity = "1" },
                    },
                    slideUp = {
                        ["0%"] = { opacity = "0", transform = "translateY(10px)" },
                        ["100%"] = { opacity = "1", transform = "translateY(0)" },
                    },
                },
            },
        },
    },
    
    -- Nothing Phone inspired
    nothing = {
        mode = "cdn",
        darkMode = "class",
        theme = {
            extend = {
                colors = {
                    background = "#000000",
                    foreground = "#ffffff",
                    muted = "#888888",
                    border = "#1a1a1a",
                    accent = "#d71921",
                    ["nothing-red"] = "#d71921",
                },
                fontFamily = {
                    sans = {"Ndot", "Inter", "system-ui", "sans-serif"},
                },
            },
        },
    },
}

--- Get a preset configuration
---@param name string Preset name
---@return table Configuration
function tailwind.preset(name)
    return tailwind.presets[name] or tailwind.presets.coppermoon
end

--------------------------------------------------------------------------------
-- Component Utilities
--------------------------------------------------------------------------------

--- Common component class patterns
tailwind.components = {
    -- Buttons
    btn = "inline-flex items-center justify-center gap-2 px-4 py-2 text-sm font-medium rounded-lg transition-all duration-200",
    btn_primary = "bg-copper-500 text-black hover:bg-copper-400",
    btn_secondary = "bg-transparent border border-zinc-700 text-white hover:bg-zinc-800 hover:border-copper-500",
    btn_ghost = "bg-transparent text-zinc-400 hover:text-white hover:bg-zinc-800",
    
    -- Cards
    card = "bg-zinc-900 border border-zinc-800 rounded-xl p-6 transition-all duration-200 hover:border-copper-500/50",
    card_title = "text-lg font-medium text-white mb-2",
    card_description = "text-sm text-zinc-400",
    
    -- Inputs
    input = "w-full px-4 py-2 bg-zinc-900 border border-zinc-800 rounded-lg text-white placeholder-zinc-500 focus:outline-none focus:border-copper-500 focus:ring-1 focus:ring-copper-500/20",
    
    -- Layout
    container = "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8",
    section = "py-16 lg:py-24",
    
    -- Typography
    heading_1 = "text-4xl lg:text-5xl font-bold tracking-tight",
    heading_2 = "text-3xl font-semibold tracking-tight",
    heading_3 = "text-xl font-medium",
    prose = "prose prose-invert prose-zinc max-w-none",
}

--- Get component classes
---@param name string Component name
---@return string Classes
function tailwind.component(name)
    return tailwind.components[name] or ""
end

return tailwind
