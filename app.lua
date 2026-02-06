-- CopperMine - Documentation for CopperMoon Ecosystem
-- Built with HoneyMoon + Vein + Tailwind + Lantern

local honeymoon = require("honeymoon")
local vein = require("vein")
local tailwind = require("tailwind")
local lantern = require("lantern")
local ember = require("ember")

local app = honeymoon.new()

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

app:set("env", os_ext.env("NODE_ENV") or "development")
app:set("views", "./views")

-- Setup Vein templating engine with metrics enabled for Lantern
app.views:use("vein")
app.views:set("views", "./views")
app.views:set("cache", false)
app.views:set("debug", true)
app.views:set("metrics", true)  -- Enable metrics for Lantern debug panel

-- Setup Tailwind CSS with CopperMoon preset + typography plugin
local tailwindConfig = tailwind.preset("coppermoon")
tailwindConfig.cdn = { plugins = {"typography"} }
tailwind.setup(app, tailwindConfig)

-- Add global template variables
app.views:global("site", {
    name = "CopperMine",
    tagline = "Documentation for CopperMoon Ecosystem",
    description = "Comprehensive documentation for the CopperMoon ecosystem — runtime, web framework, ORM, templating, tooling, and community packages.",
    version = "0.1.0",
    url = os_ext.env("SITE_URL") or "https://docs.coppermoon.dev",
    year = os.date("%Y"),
    github = "https://github.com/coppermoondev/coppermoon",
})

-- Add custom filters
-- Slugify a heading text for use as an anchor ID
local function slugify(text)
    -- Strip inline markdown formatting
    text = text:gsub("%*%*(.-)%*%*", "%1")
    text = text:gsub("%*(.-)%*", "%1")
    text = text:gsub("`([^`]+)`", "%1")
    text = text:gsub("%[(.-)%]%(.-%)%)", "%1")
    return text:lower():gsub("%s+", "-"):gsub("[^%w%-]", ""):gsub("%-%-+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
end

-- Extract table of contents (h2 and h3) from raw markdown
local function extractToc(text)
    if not text then return {} end
    text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
    local toc = {}
    local in_code = false
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        if line:match("^```") then
            in_code = not in_code
        elseif not in_code then
            local h2 = line:match("^##%s(.+)")
            local h3 = not h2 and line:match("^###%s(.+)")
            if h2 then
                table.insert(toc, { level = 2, title = h2:match("^%s*(.-)%s*$"), id = slugify(h2) })
            elseif h3 then
                table.insert(toc, { level = 3, title = h3:match("^%s*(.-)%s*$"), id = slugify(h3) })
            end
        end
    end
    return toc
end

app.views:filter("markdown", function(text)
    if not text then return "" end

    -- Normalize line endings (Windows \r\n → \n)
    text = text:gsub("\r\n", "\n"):gsub("\r", "\n")

    local html = {}
    local in_code_block = false
    local code_block_lang = ""
    local code_block_content = {}
    local in_list = false
    local list_type = nil
    local in_table = false
    local table_rows = {}
    local table_has_header = false
    local paragraph_lines = {}
    
    local function escape_html(str)
        return str:gsub("&", "&amp;")
                  :gsub("<", "&lt;")
                  :gsub(">", "&gt;")
    end
    
    local function process_inline(line)
        -- Bold
        line = line:gsub("%*%*(.-)%*%*", "<strong>%1</strong>")
        -- Italic
        line = line:gsub("%*(.-)%*", "<em>%1</em>")
        -- Inline code (escape HTML inside backticks)
        line = line:gsub("`([^`]+)`", function(code)
            return "<code>" .. escape_html(code) .. "</code>"
        end)
        -- Links
        line = line:gsub("%[(.-)%]%((.-)%)", '<a href="%2">%1</a>')
        return line
    end
    
    local function flush_paragraph()
        if #paragraph_lines > 0 then
            local content = table.concat(paragraph_lines, " ")
            content = process_inline(content)
            table.insert(html, "<p>" .. content .. "</p>")
            paragraph_lines = {}
        end
    end
    
    local function close_list()
        if in_list then
            if list_type == "ul" then
                table.insert(html, "</ul>")
            else
                table.insert(html, "</ol>")
            end
            in_list = false
            list_type = nil
        end
    end

    local function parse_table_cells(line)
        local cells = {}
        -- Remove leading/trailing pipes and split by |
        local inner = line:match("^%s*|(.+)|%s*$")
        if not inner then return nil end
        for cell in inner:gmatch("([^|]*)") do
            table.insert(cells, cell:match("^%s*(.-)%s*$") or "")
        end
        return cells
    end

    local function is_separator_row(line)
        return line:match("^%s*|[%s%-:|]+|%s*$") ~= nil
    end

    local function close_table()
        if not in_table or #table_rows == 0 then return end
        table.insert(html, "<table>")
        for i, row in ipairs(table_rows) do
            if i == 1 and table_has_header then
                table.insert(html, "<thead><tr>")
                for _, cell in ipairs(row) do
                    table.insert(html, "<th>" .. process_inline(cell) .. "</th>")
                end
                table.insert(html, "</tr></thead><tbody>")
            else
                table.insert(html, "<tr>")
                for _, cell in ipairs(row) do
                    table.insert(html, "<td>" .. process_inline(cell) .. "</td>")
                end
                table.insert(html, "</tr>")
            end
        end
        if table_has_header then
            table.insert(html, "</tbody>")
        end
        table.insert(html, "</table>")
        table_rows = {}
        in_table = false
        table_has_header = false
    end
    
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        -- Code blocks
        local code_start = line:match("^```(%w*)")
        if code_start and not in_code_block then
            flush_paragraph()
            close_list()
            close_table()
            in_code_block = true
            code_block_lang = code_start
            code_block_content = {}
        elseif line:match("^```$") and in_code_block then
            local code = escape_html(table.concat(code_block_content, "\n"))
            if code_block_lang ~= "" then
                table.insert(html, '<pre><code class="language-' .. code_block_lang .. '">' .. code .. '</code></pre>')
            else
                table.insert(html, '<pre><code>' .. code .. '</code></pre>')
            end
            in_code_block = false
            code_block_lang = ""
        elseif in_code_block then
            table.insert(code_block_content, line)
        -- Headers (with anchor IDs)
        elseif line:match("^######%s") then
            flush_paragraph()
            close_list()
            close_table()
            local txt = line:sub(8)
            table.insert(html, '<h6 id="' .. slugify(txt) .. '">' .. process_inline(txt) .. "</h6>")
        elseif line:match("^#####%s") then
            flush_paragraph()
            close_list()
            close_table()
            local txt = line:sub(7)
            table.insert(html, '<h5 id="' .. slugify(txt) .. '">' .. process_inline(txt) .. "</h5>")
        elseif line:match("^####%s") then
            flush_paragraph()
            close_list()
            close_table()
            local txt = line:sub(6)
            table.insert(html, '<h4 id="' .. slugify(txt) .. '">' .. process_inline(txt) .. "</h4>")
        elseif line:match("^###%s") then
            flush_paragraph()
            close_list()
            close_table()
            local txt = line:sub(5)
            table.insert(html, '<h3 id="' .. slugify(txt) .. '">' .. process_inline(txt) .. "</h3>")
        elseif line:match("^##%s") then
            flush_paragraph()
            close_list()
            close_table()
            local txt = line:sub(4)
            table.insert(html, '<h2 id="' .. slugify(txt) .. '">' .. process_inline(txt) .. "</h2>")
        elseif line:match("^#%s") then
            flush_paragraph()
            close_list()
            close_table()
            local txt = line:sub(3)
            table.insert(html, '<h1 id="' .. slugify(txt) .. '">' .. process_inline(txt) .. "</h1>")
        -- Table rows
        elseif line:match("^%s*|.+|%s*$") then
            flush_paragraph()
            close_list()
            if is_separator_row(line) then
                -- Separator row: mark header and skip storing
                if in_table and #table_rows == 1 then
                    table_has_header = true
                end
            else
                local cells = parse_table_cells(line)
                if cells then
                    in_table = true
                    table.insert(table_rows, cells)
                end
            end
        -- Unordered lists
        elseif line:match("^%s*[%-%*]%s") then
            flush_paragraph()
            close_table()
            local content = line:gsub("^%s*[%-%*]%s*", "")
            if not in_list or list_type ~= "ul" then
                close_list()
                table.insert(html, "<ul>")
                in_list = true
                list_type = "ul"
            end
            table.insert(html, "<li>" .. process_inline(content) .. "</li>")
        -- Ordered lists
        elseif line:match("^%s*%d+%.%s") then
            flush_paragraph()
            close_table()
            local content = line:gsub("^%s*%d+%.%s*", "")
            if not in_list or list_type ~= "ol" then
                close_list()
                table.insert(html, "<ol>")
                in_list = true
                list_type = "ol"
            end
            table.insert(html, "<li>" .. process_inline(content) .. "</li>")
        -- Blockquote
        elseif line:match("^>%s?") then
            flush_paragraph()
            close_list()
            close_table()
            local content = line:gsub("^>%s?", "")
            table.insert(html, "<blockquote><p>" .. process_inline(content) .. "</p></blockquote>")
        -- Empty line
        elseif line:match("^%s*$") then
            flush_paragraph()
            close_list()
            close_table()
        -- Regular text (paragraph)
        else
            close_list()
            close_table()
            table.insert(paragraph_lines, line)
        end
    end

    flush_paragraph()
    close_list()
    close_table()
    
    return table.concat(html, "\n")
end)

--------------------------------------------------------------------------------
-- Middleware
--------------------------------------------------------------------------------

-- Ember structured logger
local log = ember({
    level = "debug",
    name = "coppermine",
    transports = {
        ember.transports.console({ colors = true }),
    },
})

app:use(ember.honeymoon(log))
app:use(honeymoon.responseTime())
app:use(honeymoon.helmet())
app:use(honeymoon.cors())

-- Lantern debug toolbar (only in development)
--[[
lantern.setup(app, {
    enabled = app:get_setting("env") ~= "production",
    ignorePaths = { "/api/", "/public/" },  -- Don't inject into API or static routes
    vein = app.views.engine,  -- Pass vein engine explicitly for template metrics
})

-- Bridge Ember logs to Lantern debug panel
app:use(ember.lantern())

]]--

-- Static files
app:use("/public", honeymoon.static("./public"))

--------------------------------------------------------------------------------
-- Documentation Structure
--------------------------------------------------------------------------------

local docs = {
    -- Main sections
    sections = {
        {
            id = "getting-started",
            title = "Getting Started",
            icon = "rocket",
            pages = {
                { id = "introduction", title = "Introduction" },
                { id = "installation", title = "Installation" },
                { id = "quickstart", title = "Quick Start" },
                { id = "project-structure", title = "Project Structure" },
            }
        },
        {
            id = "coppermoon",
            title = "CopperMoon Runtime",
            icon = "moon",
            pages = {
                { id = "overview", title = "Overview" },
                { id = "lua-differences", title = "Lua Differences" },
                { id = "built-in-modules", title = "Built-in Modules" },
                { id = "http-server", title = "HTTP Server" },
                { id = "filesystem", title = "File System" },
                { id = "json", title = "JSON" },
            }
        },
        {
            id = "honeymoon",
            title = "HoneyMoon Framework",
            icon = "honey",
            pages = {
                { id = "overview", title = "Overview" },
                { id = "routing", title = "Routing" },
                { id = "middleware", title = "Middleware" },
                { id = "request-response", title = "Request & Response" },
                { id = "validation", title = "Validation" },
                { id = "sessions", title = "Sessions" },
                { id = "authentication", title = "Authentication" },
                { id = "security", title = "Security" },
                { id = "error-handling", title = "Error Handling" },
            }
        },
        {
            id = "vein",
            title = "Vein Templating",
            icon = "code",
            pages = {
                { id = "overview", title = "Overview" },
                { id = "syntax", title = "Syntax" },
                { id = "filters", title = "Filters" },
                { id = "components", title = "Components" },
                { id = "layouts", title = "Layouts" },
                { id = "integration", title = "HoneyMoon Integration" },
            }
        },
        {
            id = "shipyard",
            title = "Shipyard CLI",
            icon = "terminal",
            pages = {
                { id = "overview", title = "Overview" },
                { id = "commands", title = "Commands" },
                { id = "configuration", title = "Configuration" },
                { id = "templates", title = "Project Templates" },
            }
        },
        {
            id = "harbor",
            title = "Harbor Package Manager",
            icon = "package",
            pages = {
                { id = "overview", title = "Overview" },
                { id = "installing-packages", title = "Installing Packages" },
                { id = "creating-packages", title = "Creating Packages" },
                { id = "native-modules", title = "Native Modules" },
                { id = "harbor-toml", title = "harbor.toml Reference" },
            }
        },
        {
            id = "quarry",
            title = "Quarry Process Manager",
            icon = "bolt",
            pages = {
                { id = "overview", title = "Overview" },
                { id = "commands", title = "Commands" },
                { id = "git-deploy", title = "Git Deployment" },
                { id = "configuration", title = "Configuration" },
                { id = "process-management", title = "Process Management" },
            }
        },
        {
            id = "freight",
            title = "Freight ORM",
            icon = "database",
            pages = {
                { id = "overview", title = "Overview" },
                { id = "models", title = "Models" },
                { id = "queries", title = "Query Builder" },
                { id = "relationships", title = "Relationships" },
                { id = "migrations", title = "Migrations" },
            }
        },
        {
            id = "assay",
            title = "Assay Testing",
            icon = "check",
            pages = {
                { id = "overview", title = "Overview" },
                { id = "assertions", title = "Assertions" },
                { id = "mocking", title = "Mocking" },
            }
        },
        {
            id = "ember",
            title = "Ember Logging",
            icon = "flame",
            pages = {
                { id = "overview", title = "Overview" },
                { id = "getting-started", title = "Getting Started" },
                { id = "loggers", title = "Loggers & Children" },
                { id = "transports", title = "Transports" },
                { id = "formatters", title = "Formatters" },
                { id = "integrations", title = "Integrations" },
                { id = "api", title = "API Reference" },
            }
        },
        {
            id = "buffer",
            title = "Buffer",
            icon = "binary",
            pages = {
                { id = "overview", title = "Overview" },
                { id = "getting-started", title = "Getting Started" },
                { id = "reading-writing", title = "Reading & Writing" },
                { id = "operations", title = "Operations" },
                { id = "api", title = "API Reference" },
            }
        },
        {
            id = "net",
            title = "Network",
            icon = "globe",
            pages = {
                { id = "overview", title = "Overview" },
                { id = "api", title = "API Reference" },
            }
        },
        {
            id = "fs",
            title = "File System",
            icon = "folder",
            pages = {
                { id = "overview", title = "Overview" },
                { id = "api", title = "API Reference" },
            }
        },
        {
            id = "archive",
            title = "Archive",
            icon = "archive",
            pages = {
                { id = "overview", title = "Overview" },
                { id = "api", title = "API Reference" },
            }
        },
        {
            id = "time",
            title = "Time & DateTime",
            icon = "clock",
            pages = {
                { id = "overview", title = "Overview" },
                { id = "api", title = "API Reference" },
            }
        },
        {
            id = "regex",
            title = "Regex",
            icon = "search",
            pages = {
                { id = "overview", title = "Overview" },
                { id = "api", title = "API Reference" },
            }
        },
        {
            id = "lantern",
            title = "Lantern DevTools",
            icon = "bug",
            pages = {
                { id = "overview", title = "Overview" },
                { id = "setup", title = "Setup" },
                { id = "panels", title = "Panels" },
                { id = "freight-integration", title = "Freight Integration" },
                { id = "logging", title = "Logging & Events" },
                { id = "api", title = "API Reference" },
            }
        },
        {
            id = "redis",
            title = "Redis",
            icon = "plug",
            pages = {
                { id = "overview", title = "Overview" },
                { id = "commands", title = "Commands Reference" },
            }
        },
        {
            id = "mqtt",
            title = "MQTT",
            icon = "signal",
            pages = {
                { id = "overview", title = "Overview" },
                { id = "api", title = "API Reference" },
            }
        },
        {
            id = "s3",
            title = "S3 Storage",
            icon = "cloud",
            pages = {
                { id = "overview", title = "Overview" },
                { id = "api", title = "API Reference" },
            }
        },
        {
            id = "backend-services",
            title = "Backend Services",
            icon = "server",
            pages = {
                { id = "overview", title = "Overview" },
                { id = "rest-api", title = "REST APIs" },
                { id = "middleware-patterns", title = "Middleware Patterns" },
                { id = "database", title = "Database Integration" },
                { id = "cli-tools", title = "CLI Tools" },
                { id = "configuration", title = "Configuration" },
            }
        },
        {
            id = "guides",
            title = "Guides",
            icon = "book",
            pages = {
                { id = "rest-api", title = "Building a REST API" },
                { id = "web-app", title = "Building a Web App" },
                { id = "authentication", title = "Adding Authentication" },
                { id = "deployment", title = "Deployment" },
            }
        },
    }
}

-- Group sections for sidebar organization
docs.groups = {
    {
        label = nil,
        sectionIds = { "getting-started" },
    },
    {
        label = "Core",
        sectionIds = { "coppermoon", "fs", "buffer", "net", "archive", "time", "regex" },
    },
    {
        label = "Framework",
        sectionIds = { "honeymoon", "vein" },
    },
    {
        label = "Tooling",
        sectionIds = { "shipyard", "harbor", "quarry" },
    },
    {
        label = "Packages",
        sectionIds = { "freight", "assay", "ember", "lantern" },
    },
    {
        label = "Community",
        sectionIds = { "redis", "mqtt", "s3" },
    },
    {
        label = "Backend",
        sectionIds = { "backend-services" },
    },
    {
        label = "Resources",
        sectionIds = { "guides" },
    },
}

-- Build section lookup by ID (for sidebar group rendering)
docs.sectionById = {}
for _, section in ipairs(docs.sections) do
    docs.sectionById[section.id] = section
end

-- SVG icons for sidebar sections (Heroicons outline, 24x24 viewBox)
docs.icons = {
    rocket = [[<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M15.59 14.37a6 6 0 01-5.84 7.38v-4.8m5.84-2.58a14.98 14.98 0 006.16-12.12A14.98 14.98 0 009.63 8.41m5.96 5.96a14.926 14.926 0 01-5.841 2.58m-.119-8.54a6 6 0 00-7.381 5.84h4.8m2.581-5.84a14.927 14.927 0 00-2.58 5.841m2.699 2.7c-.103.021-.207.041-.311.06a15.09 15.09 0 01-2.448-2.448 14.9 14.9 0 01.06-.312m-2.24 2.39a4.493 4.493 0 00-1.757 4.306 4.493 4.493 0 004.306-1.758M16.5 9a1.5 1.5 0 11-3 0 1.5 1.5 0 013 0z"/></svg>]],
    moon = [[<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M21.752 15.002A9.718 9.718 0 0118 15.75c-5.385 0-9.75-4.365-9.75-9.75 0-1.33.266-2.597.748-3.752A9.753 9.753 0 003 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 006.002-2.998z"/></svg>]],
    honey = [[<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z"/></svg>]],
    code = [[<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M17.25 6.75L22.5 12l-5.25 5.25m-10.5 0L1.5 12l5.25-5.25m7.5-3l-4.5 16.5"/></svg>]],
    terminal = [[<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M6.75 7.5l3 2.25-3 2.25m4.5 0h3m-9 8.25h13.5A2.25 2.25 0 0021 18V6a2.25 2.25 0 00-2.25-2.25H5.25A2.25 2.25 0 003 6v12a2.25 2.25 0 002.25 2.25z"/></svg>]],
    package = [[<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M21 7.5l-9-5.25L3 7.5m18 0l-9 5.25m9-5.25v9l-9 5.25M3 7.5l9 5.25M3 7.5v9l9 5.25m0-9v9"/></svg>]],
    database = [[<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M20.25 6.375c0 2.278-3.694 4.125-8.25 4.125S3.75 8.653 3.75 6.375m16.5 0c0-2.278-3.694-4.125-8.25-4.125S3.75 4.097 3.75 6.375m16.5 0v11.25c0 2.278-3.694 4.125-8.25 4.125s-8.25-1.847-8.25-4.125V6.375m16.5 0v3.75m-16.5-3.75v3.75m16.5 0v3.75C20.25 16.153 16.556 18 12 18s-8.25-1.847-8.25-4.125v-3.75m16.5 0c0 2.278-3.694 4.125-8.25 4.125s-8.25-1.847-8.25-4.125"/></svg>]],
    check = [[<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>]],
    flame = [[<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M15.362 5.214A8.252 8.252 0 0112 21 8.25 8.25 0 016.038 7.048 8.287 8.287 0 009 9.6a8.983 8.983 0 013.361-6.867 8.21 8.21 0 003 2.48z"/><path stroke-linecap="round" stroke-linejoin="round" d="M12 18a3.75 3.75 0 00.495-7.467 5.99 5.99 0 00-1.925 3.546 5.974 5.974 0 01-2.133-1.001A3.75 3.75 0 0012 18z"/></svg>]],
    binary = [[<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M14.25 9.75L16.5 12l-2.25 2.25m-4.5 0L7.5 12l2.25-2.25M6 20.25h12A2.25 2.25 0 0020.25 18V6A2.25 2.25 0 0018 3.75H6A2.25 2.25 0 003.75 6v12A2.25 2.25 0 006 20.25z"/></svg>]],
    bug = [[<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M12 12.75c1.148 0 2.278.08 3.383.237 1.037.146 1.866.966 1.866 2.013 0 3.728-2.35 6.75-5.25 6.75S6.75 18.728 6.75 15c0-1.046.83-1.867 1.866-2.013A24.204 24.204 0 0112 12.75zm0 0c2.883 0 5.647.508 8.207 1.44a23.91 23.91 0 01-1.152-6.135c-.22-2.581-2.205-4.555-4.555-4.555h-1c-2.35 0-4.335 1.974-4.555 4.555a23.91 23.91 0 01-1.152 6.135A24.099 24.099 0 0112 12.75z"/></svg>]],
    plug = [[<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M13.19 8.688a4.5 4.5 0 011.242 7.244l-4.5 4.5a4.5 4.5 0 01-6.364-6.364l1.757-1.757m13.35-.622l1.757-1.757a4.5 4.5 0 00-6.364-6.364l-4.5 4.5a4.5 4.5 0 001.242 7.244"/></svg>]],
    book = [[<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M12 6.042A8.967 8.967 0 006 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 016 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 016-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0018 18a8.967 8.967 0 00-6 2.292m0-14.25v14.25"/></svg>]],
    server = [[<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M5.25 14.25h13.5m-13.5 0a3 3 0 01-3-3m3 3a3 3 0 100 6h13.5a3 3 0 100-6m-16.5-3a3 3 0 013-3h13.5a3 3 0 013 3m-19.5 0a4.5 4.5 0 01.9-2.7L5.737 5.1a3.375 3.375 0 012.7-1.35h7.126c1.062 0 2.062.5 2.7 1.35l2.587 3.45a4.5 4.5 0 01.9 2.7m0 0a3 3 0 01-3 3m0 3h.008v.008h-.008v-.008zm0-6h.008v.008h-.008v-.008zm-3 6h.008v.008h-.008v-.008zm0-6h.008v.008h-.008v-.008z"/></svg>]],
    signal = [[<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M9.348 14.652a3.75 3.75 0 010-5.304m5.304 0a3.75 3.75 0 010 5.304m-7.425 2.121a6.75 6.75 0 010-9.546m9.546 0a6.75 6.75 0 010 9.546M5.106 18.894c-3.808-3.807-3.808-9.98 0-13.788m13.788 0c3.808 3.807 3.808 9.98 0 13.788M12 12h.008v.008H12V12zm.375 0a.375.375 0 11-.75 0 .375.375 0 01.75 0z"/></svg>]],
    globe = [[<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M12 21a9.004 9.004 0 008.716-6.747M12 21a9.004 9.004 0 01-8.716-6.747M12 21c2.485 0 4.5-4.03 4.5-9S14.485 3 12 3m0 18c-2.485 0-4.5-4.03-4.5-9S9.515 3 12 3m0 0a8.997 8.997 0 017.843 4.582M12 3a8.997 8.997 0 00-7.843 4.582m15.686 0A11.953 11.953 0 0112 10.5c-2.998 0-5.74-1.1-7.843-2.918m15.686 0A8.959 8.959 0 0121 12c0 .778-.099 1.533-.284 2.253m0 0A17.919 17.919 0 0112 16.5c-3.162 0-6.133-.815-8.716-2.247m0 0A9.015 9.015 0 013 12c0-1.605.42-3.113 1.157-4.418"/></svg>]],
    folder = [[<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12.75V12A2.25 2.25 0 014.5 9.75h15A2.25 2.25 0 0121.75 12v.75m-8.69-6.44l-2.12-2.12a1.5 1.5 0 00-1.061-.44H4.5A2.25 2.25 0 002.25 6v12a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9a2.25 2.25 0 00-2.25-2.25h-5.379a1.5 1.5 0 01-1.06-.44z"/></svg>]],
    archive = [[<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M20.25 7.5l-.625 10.632a2.25 2.25 0 01-2.247 2.118H6.622a2.25 2.25 0 01-2.247-2.118L3.75 7.5m8.25 3v6.75m0 0l-3-3m3 3l3-3M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125z"/></svg>]],
    clock = [[<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>]],
    cloud = [[<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M2.25 15a4.5 4.5 0 004.5 4.5H18a3.75 3.75 0 001.332-7.257 3 3 0 00-3.758-3.848 5.25 5.25 0 00-10.233 2.33A4.502 4.502 0 002.25 15z"/></svg>]],
    search = [[<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m5.231 13.481L15 17.25m-4.5-15H5.625c-.621 0-1.125.504-1.125 1.125v16.5c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9zm3.75 11.625a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z"/></svg>]],
    bolt = [[<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z"/></svg>]],
}

-- Add docs to global template context
app.views:global("docs", docs)

--------------------------------------------------------------------------------
-- Routes
--------------------------------------------------------------------------------

-- robots.txt
app:get("/robots.txt", function(req, res)
    res:header("Content-Type", "text/plain; charset=utf-8")
    res:send("User-agent: *\nAllow: /\n\nSitemap: " .. (os_ext.env("SITE_URL") or "https://docs.coppermoon.dev") .. "/sitemap.xml\n")
end)

-- sitemap.xml (dynamic based on docs structure)
app:get("/sitemap.xml", function(req, res)
    local baseUrl = os_ext.env("SITE_URL") or "https://docs.coppermoon.dev"
    local urls = {
        '  <url>\n    <loc>' .. baseUrl .. '/</loc>\n    <changefreq>weekly</changefreq>\n    <priority>1.0</priority>\n  </url>',
    }
    for _, section in ipairs(docs.sections) do
        for _, page in ipairs(section.pages) do
            table.insert(urls, '  <url>\n    <loc>' .. baseUrl .. '/docs/' .. section.id .. '/' .. page.id .. '</loc>\n    <changefreq>weekly</changefreq>\n    <priority>0.8</priority>\n  </url>')
        end
    end
    res:header("Content-Type", "application/xml; charset=utf-8")
    res:send('<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' .. table.concat(urls, "\n") .. '\n</urlset>')
end)

-- Home page
app:get("/", function(req, res)
    res:render("pages/home", {
        title = "CopperMine — Documentation for CopperMoon",
        canonical_path = "/",
        currentSection = nil,
        currentPage = nil,
    })
end)

-- Documentation pages
app:get("/docs/:section", function(req, res)
    local sectionId = req.params.section

    -- Find section
    local section = nil
    for _, s in ipairs(docs.sections) do
        if s.id == sectionId then
            section = s
            break
        end
    end

    if not section then
        return res:status(404):render("pages/404", {
            title = "Page Not Found"
        })
    end

    -- Redirect to first page
    if section.pages and #section.pages > 0 then
        return res:redirect("/docs/" .. sectionId .. "/" .. section.pages[1].id)
    end

    res:render("pages/doc", {
        title = section.title .. " - CopperMine",
        currentSection = section,
        currentPage = nil,
        content = "Select a page from the sidebar."
    })
end)

app:get("/docs/:section/:page", function(req, res)
    local sectionId = req.params.section
    local pageId = req.params.page

    -- Find section
    local section = nil
    for _, s in ipairs(docs.sections) do
        if s.id == sectionId then
            section = s
            break
        end
    end

    if not section then
        return res:status(404):render("pages/404", {
            title = "Page Not Found"
        })
    end

    -- Find page
    local page = nil
    for _, p in ipairs(section.pages) do
        if p.id == pageId then
            page = p
            break
        end
    end

    if not page then
        return res:status(404):render("pages/404", {
            title = "Page Not Found"
        })
    end

    -- Load content from file
    local contentPath = "./content/" .. sectionId .. "/" .. pageId .. ".md"
    local ok, content = pcall(fs.read, contentPath)
    if not ok then
        content = "# " .. page.title .. "\n\nContent coming soon..."
    end

    local toc = extractToc(content)

    res:render("pages/doc", {
        title = page.title .. " — " .. section.title .. " — CopperMine",
        meta_description = section.title .. ": " .. page.title .. " — CopperMoon documentation.",
        canonical_path = "/docs/" .. sectionId .. "/" .. pageId,
        og_title = page.title .. " — " .. section.title,
        currentSection = section,
        currentPage = page,
        content = content,
        toc = toc
    })
end)

-- Search API
app:get("/api/search", function(req, res)
    local query = req.query.q or ""

    -- Simple search (in production, use a proper search engine)
    local results = {}

    if #query >= 2 then
        for _, section in ipairs(docs.sections) do
            for _, page in ipairs(section.pages) do
                if page.title:lower():find(query:lower(), 1, true) then
                    table.insert(results, {
                        section = section.title,
                        sectionId = section.id,
                        page = page.title,
                        pageId = page.id,
                        url = "/docs/" .. section.id .. "/" .. page.id
                    })
                end
            end
        end
    end

    res:json({ results = results, query = query })
end)

-- 404 handler
app:all("*", function(req, res)
    res:status(404):render("pages/404", {
        title = "Page Not Found - CopperMine"
    })
end)

--------------------------------------------------------------------------------
-- Error Handler
--------------------------------------------------------------------------------

app:error(function(err, req, res, stack)
    print("[CopperMine Error]", tostring(err))
    if app:get_setting("env") ~= "production" then
        print(stack)
    end
end)

--------------------------------------------------------------------------------
-- Start Server
--------------------------------------------------------------------------------

local port = tonumber(os_ext.env("PORT")) or 3002
print("CopperMine Documentation running on http://localhost:" .. port)
app:listen(port)
