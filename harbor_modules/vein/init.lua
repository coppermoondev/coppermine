-- Vein - Templating Engine for CopperMoon
-- A powerful, Lua-inspired templating system
--
-- Syntax:
--   {{ expression }}           - Output escaped expression
--   {! expression !}           - Output raw/unescaped expression
--   {% code %}                 - Execute Lua code
--   {# comment #}              - Comment (not rendered)
--   {@ include "file" @}       - Include another template
--   {> partial "name" data >}  - Render partial with data
--
-- Control structures (Lua-style):
--   {% for item in items do %}...{% end %}
--   {% for i = 1, 10 do %}...{% end %}
--   {% if condition then %}...{% elseif x then %}...{% else %}...{% end %}
--   {% while condition do %}...{% end %}
--
-- Filters (pipe syntax):
--   {{ name | upper }}
--   {{ text | truncate(100) | escape }}
--   {{ price | currency("$") }}
--
-- Blocks and inheritance:
--   {% extends "base.vein" %}
--   {% block name %}...{% endblock %}
--   {% slot name %}default{% endslot %}
--
-- Components:
--   {% component "card" { title = "Hello" } %}
--     Content here
--   {% endcomponent %}
--
-- @module vein
-- @author CopperMoon Team
-- @license MIT

local vein = {}

--------------------------------------------------------------------------------
-- Version
--------------------------------------------------------------------------------

vein._VERSION = "0.2.0"
vein._DESCRIPTION = "A powerful, Lua-inspired templating engine for CopperMoon"

--------------------------------------------------------------------------------
-- Core Modules
--------------------------------------------------------------------------------

local compiler = require("vein.lib.compiler")
local runtime = require("vein.lib.runtime")
local filters = require("vein.lib.filters")
local loader = require("vein.lib.loader")
local cache = require("vein.lib.cache")
local metrics = require("vein.lib.metrics")
local fragment = require("vein.lib.fragment")

-- Optional sourcemap (may not be available)
local sourcemap = nil
pcall(function() sourcemap = require("vein.lib.sourcemap") end)

--------------------------------------------------------------------------------
-- Engine Class
--------------------------------------------------------------------------------

local Engine = {}
Engine.__index = Engine

--- Create a new Vein engine
---@param options table? Engine options
---@return Engine
function vein.new(options)
    options = options or {}

    local self = setmetatable({}, Engine)

    -- Configuration
    self.options = {
        -- Template directories
        views = options.views or "./views",
        partials = options.partials or "./views/partials",
        layouts = options.layouts or "./views/layouts",
        components = options.components or "./views/components",

        -- File extension
        extension = options.extension or ".vein",

        -- Caching
        cache = options.cache ~= false,
        cacheLimit = options.cacheLimit or 100,

        -- Development mode (detailed errors)
        debug = options.debug or false,

        -- Auto-escape by default
        autoEscape = options.autoEscape ~= false,

        -- Delimiters (customizable)
        delimiters = options.delimiters or {
            output = { "{{", "}}" },
            raw = { "{!", "!}" },
            code = { "{%", "%}" },
            comment = { "{#", "#}" },
            include = { "{@", "@}" },
            partial = { "{>", ">}" },
        },

        -- Global data available in all templates
        globals = options.globals or {},
        
        -- Metrics collection
        metrics = options.metrics or false,
        
        -- Fragment support (return arrays instead of strings)
        fragments = options.fragments or false,
        
        -- Source map generation
        sourceMap = options.sourceMap or false,
    }

    -- Template cache
    self.cache = cache.new(self.options.cacheLimit)

    -- Compiled template cache
    self.compiled = {}
    
    -- Source maps cache
    self.sourceMaps = {}

    -- Registered filters
    self.filters = filters.defaults()

    -- Registered components
    self.components = {}

    -- Registered helpers
    self.helpers = {}

    -- Layout stack for inheritance
    self.layoutStack = {}

    -- Block definitions
    self.blocks = {}
    
    -- Metrics collector
    if self.options.metrics then
        self.metrics = metrics.new()
    end

    return self
end

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

--- Set a configuration option
---@param key string Option name
---@param value any Option value
---@return Engine self
function Engine:set(key, value)
    if key == "views" or key == "partials" or key == "layouts" or key == "components" then
        self.options[key] = value
    elseif key == "extension" then
        self.options.extension = value
    elseif key == "cache" then
        self.options.cache = value
    elseif key == "debug" then
        self.options.debug = value
    elseif key == "autoEscape" then
        self.options.autoEscape = value
    elseif key == "metrics" then
        self.options.metrics = value
        if value and not self.metrics then
            self.metrics = metrics.new()
        elseif not value then
            self.metrics = nil
        end
    elseif key == "fragments" then
        self.options.fragments = value
    elseif key == "sourceMap" then
        self.options.sourceMap = value
    else
        self.options[key] = value
    end
    return self
end

--- Add global data
---@param key string|table Key or table of globals
---@param value any? Value if key is string
---@return Engine self
function Engine:global(key, value)
    if type(key) == "table" then
        for k, v in pairs(key) do
            self.options.globals[k] = v
        end
    else
        self.options.globals[key] = value
    end
    return self
end

--------------------------------------------------------------------------------
-- Filters
--------------------------------------------------------------------------------

--- Register a custom filter
---@param name string Filter name
---@param fn function Filter function
---@return Engine self
function Engine:filter(name, fn)
    self.filters[name] = fn
    return self
end

--- Register multiple filters
---@param filters table Table of name -> function
---@return Engine self
function Engine:filters(filtersTable)
    for name, fn in pairs(filtersTable) do
        self.filters[name] = fn
    end
    return self
end

--------------------------------------------------------------------------------
-- Components
--------------------------------------------------------------------------------

--- Register a component
---@param name string Component name
---@param template string|function Template string or render function
---@return Engine self
function Engine:component(name, template)
    self.components[name] = template
    return self
end

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

--- Register a helper function
---@param name string Helper name
---@param fn function Helper function
---@return Engine self
function Engine:helper(name, fn)
    self.helpers[name] = fn
    return self
end

--------------------------------------------------------------------------------
-- Rendering
--------------------------------------------------------------------------------

--- Render a template file
---@param name string Template name (without extension)
---@param data table? Data to pass to template
---@param options table? Render options
---@return string|Fragment Rendered output
function Engine:render(name, data, options)
    data = data or {}
    options = options or {}
    
    local startTime = os.clock and os.clock() or 0

    -- Merge with globals
    local context = self:_createContext(data, name)
    
    -- Fragment support
    local useFragments = options.fragments or self.options.fragments
    if useFragments then
        context.__fragment = fragment.new()
        context.__useFragments = true
    end

    -- Get compiled template
    local compiled, compileMeta = self:_getCompiled(name, options)

    -- Execute template
    local ok, result = pcall(compiled, context)

    if not ok then
        local errorMsg = result
        
        -- Try to resolve with source map
        if self.sourceMaps[name] and sourcemap then
            local smap = self.sourceMaps[name]
            local errorInfo = smap:resolveError(errorMsg)
            if errorInfo then
                errorMsg = smap:formatError(errorInfo)
            end
        end
        
        -- Record error in metrics
        if self.metrics then
            self.metrics:recordError(name, errorMsg)
        end
        
        if self.options.debug then
            error(string.format("Vein render error in '%s': %s", name, errorMsg))
        else
            error(string.format("Template render error: %s", name))
        end
    end

    -- Record render metrics
    local endTime = os.clock and os.clock() or 0
    if self.metrics then
        self.metrics:recordRender(name, startTime, endTime, data)
    end

    -- Handle template inheritance (extends)
    if context.__extends then
        -- Pass blocks from child to parent
        local parentData = {}
        for k, v in pairs(data) do
            parentData[k] = v
        end
        parentData.__blocks = context.__blocks or {}
        
        -- Render parent layout with child's blocks
        local layoutPath = context.__extends
        return self:render(layoutPath, parentData, options)
    end

    return result
end

--- Render a template string directly
---@param template string Template string
---@param data table? Data to pass to template
---@param options table? Render options
---@return string|Fragment Rendered output
function Engine:renderString(template, data, options)
    data = data or {}
    options = options or {}
    
    local startTime = os.clock and os.clock() or 0

    -- Merge with globals
    local context = self:_createContext(data, options.templateName or "inline")
    
    -- Fragment support
    local useFragments = options.fragments or self.options.fragments
    if useFragments then
        context.__fragment = fragment.new()
        context.__useFragments = true
    end

    -- Compile template
    local compiled, compileMeta = compiler.compile(template, self, {
        metrics = self.options.metrics,
        fragments = useFragments,
        sourceMap = self.options.sourceMap,
        templateName = options.templateName,
        debug = self.options.debug,
        returnMetadata = true,
    })

    -- Execute
    local ok, result = pcall(compiled, context)

    if not ok then
        if self.metrics then
            self.metrics:recordError(options.templateName or "inline", result)
        end
        
        if self.options.debug then
            error(string.format("Vein render error: %s", result))
        else
            error("Template render error")
        end
    end
    
    local endTime = os.clock and os.clock() or 0
    if self.metrics then
        self.metrics:recordRender(options.templateName or "inline", startTime, endTime, data)
    end

    return result
end

--- Compile a template for later use
---@param name string Template name
---@param options table? Compilation options
---@return function Compiled template function
---@return table? Metadata
function Engine:compile(name, options)
    return self:_getCompiled(name, options or {})
end

--- Compile a template string
---@param template string Template string
---@param options table? Compilation options
---@return function Compiled template function
---@return table? Metadata
function Engine:compileString(template, options)
    options = options or {}
    return compiler.compile(template, self, {
        metrics = self.options.metrics,
        fragments = self.options.fragments,
        sourceMap = self.options.sourceMap,
        templateName = options.templateName,
        debug = self.options.debug,
        returnMetadata = options.returnMetadata,
    })
end

--------------------------------------------------------------------------------
-- Metrics API
--------------------------------------------------------------------------------

--- Get metrics collector
---@return Collector? Metrics collector
function Engine:getMetrics()
    return self.metrics
end

--- Get metrics summary
---@return table? Summary
function Engine:getMetricsSummary()
    if self.metrics then
        return self.metrics:getSummary()
    end
    return nil
end

--- Export all metrics
---@return table? All metrics
function Engine:exportMetrics()
    if self.metrics then
        return self.metrics:export()
    end
    return nil
end

--- Reset metrics
function Engine:resetMetrics()
    if self.metrics then
        self.metrics:reset()
    end
end

--- Enable metrics
function Engine:enableMetrics()
    if not self.metrics then
        self.metrics = metrics.new()
    end
    self.metrics:enable()
    self.options.metrics = true
end

--- Disable metrics
function Engine:disableMetrics()
    if self.metrics then
        self.metrics:disable()
    end
    self.options.metrics = false
end

--------------------------------------------------------------------------------
-- Source Map API
--------------------------------------------------------------------------------

--- Get source map for a template
---@param name string Template name
---@return SourceMap? Source map
function Engine:getSourceMap(name)
    return self.sourceMaps[name]
end

--- Resolve an error to template location
---@param name string Template name
---@param errorMsg string Error message
---@return table? Error info with context
function Engine:resolveError(name, errorMsg)
    local smap = self.sourceMaps[name]
    if smap then
        return smap:resolveError(errorMsg)
    end
    return nil
end

--------------------------------------------------------------------------------
-- Fragment API
--------------------------------------------------------------------------------

--- Create a new fragment
---@param parts table? Initial parts
---@return Fragment
function Engine:createFragment(parts)
    return fragment.new(parts)
end

--- Check if value is a fragment
---@param value any Value to check
---@return boolean
function Engine:isFragment(value)
    return fragment.isFragment(value)
end

--------------------------------------------------------------------------------
-- Debug API
--------------------------------------------------------------------------------

--- Get debug info for a template
---@param name string Template name
---@return table Debug info
function Engine:getDebugInfo(name)
    local info = {
        name = name,
        cached = self.compiled[name] ~= nil,
        sourceMap = self.sourceMaps[name] ~= nil,
    }
    
    if self.metrics then
        info.renderStats = self.metrics:getRenderStats(name)
        info.compilationStats = self.metrics.compilations[name]
        info.includes = self.metrics:getIncludeTree(name)
    end
    
    return info
end

--- Get all debug info
---@return table All debug info
function Engine:getAllDebugInfo()
    return {
        options = self.options,
        cachedTemplates = self:_getKeys(self.compiled),
        sourceMaps = self:_getKeys(self.sourceMaps),
        metrics = self.metrics and self.metrics:export() or nil,
        filters = self:_getKeys(self.filters),
        components = self:_getKeys(self.components),
        helpers = self:_getKeys(self.helpers),
    }
end

--------------------------------------------------------------------------------
-- Internal Methods
--------------------------------------------------------------------------------

--- Create render context with globals and helpers
---@param data table User data
---@param templateName string? Template name for tracking
---@return table Context
function Engine:_createContext(data, templateName)
    local context = {}

    -- Add globals
    for k, v in pairs(self.options.globals) do
        context[k] = v
    end

    -- Add user data (overrides globals)
    for k, v in pairs(data) do
        context[k] = v
    end

    -- Add engine reference for includes/partials
    context.__engine = self
    context.__filters = self.filters
    context.__helpers = self.helpers
    context.__components = self.components
    context.__templateName = templateName
    context.__metrics = self.metrics

    -- Add built-in functions
    context.include = function(name, includeData)
        local startTime = os.clock and os.clock() or 0
        
        -- Create clean data without __extends to avoid infinite loops
        local cleanData = {}
        local sourceData = includeData or data
        for k, v in pairs(sourceData) do
            if k ~= "__extends" then
                cleanData[k] = v
            end
        end
        local result = self:render(name, cleanData)
        
        -- Record include
        if self.metrics and templateName then
            local endTime = os.clock and os.clock() or 0
            self.metrics:recordInclude(templateName, name, (endTime - startTime) * 1000)
        end
        
        return result
    end

    context.partial = function(name, partialData)
        local partialPath = self.options.partials .. "/" .. name
        -- Create clean data without __extends
        local cleanData = {}
        local sourceData = partialData or {}
        for k, v in pairs(sourceData) do
            if k ~= "__extends" then
                cleanData[k] = v
            end
        end
        return self:render(partialPath, cleanData)
    end

    context.component = function(name, props, content)
        return self:_renderComponent(name, props, content, data)
    end
    
    -- Fragment helper
    context.fragment = function(parts)
        return fragment.new(parts)
    end

    return context
end

--- Get or compile template
---@param name string Template name
---@param options table? Options
---@return function Compiled template
---@return table? Metadata
function Engine:_getCompiled(name, options)
    options = options or {}
    
    -- Check cache
    if self.options.cache and self.compiled[name] then
        if self.metrics then
            self.metrics:recordCacheHit(name)
        end
        return self.compiled[name]
    end
    
    if self.metrics then
        self.metrics:recordCacheMiss(name)
    end

    local startTime = os.clock and os.clock() or 0

    -- Load template
    local template = loader.load(name, self.options)

    -- Compile with options
    local compiled, compileMeta = compiler.compile(template, self, {
        metrics = self.options.metrics,
        fragments = self.options.fragments,
        sourceMap = self.options.sourceMap,
        templateName = name,
        debug = self.options.debug,
        returnMetadata = true,
    })
    
    local endTime = os.clock and os.clock() or 0
    
    -- Record compilation metrics
    if self.metrics and compileMeta then
        self.metrics:recordCompilation(
            name, 
            startTime, 
            endTime, 
            compileMeta.tokenCount or 0,
            compileMeta.lineCount or 0
        )
    end
    
    -- Store source map
    if compileMeta and compileMeta.sourceMap then
        self.sourceMaps[name] = compileMeta.sourceMap
    end

    -- Cache
    if self.options.cache then
        self.compiled[name] = compiled
    end

    return compiled, compileMeta
end

--- Render a component
---@param name string Component name
---@param props table Component properties
---@param content string? Slot content
---@param parentData table Parent context data
---@return string Rendered component
function Engine:_renderComponent(name, props, content, parentData)
    local component = self.components[name]

    if not component then
        -- Try to load from file
        local componentPath = self.options.components .. "/" .. name
        local ok, template = pcall(loader.load, componentPath, self.options)
        if ok then
            component = template
            self.components[name] = component
        else
            error(string.format("Component not found: %s", name))
        end
    end

    -- Prepare component context
    local context = {}
    for k, v in pairs(props or {}) do
        context[k] = v
    end
    context.slot = content or ""
    context.children = content or ""

    -- Merge parent data
    for k, v in pairs(parentData or {}) do
        if context[k] == nil then
            context[k] = v
        end
    end

    if type(component) == "function" then
        return component(context)
    else
        return self:renderString(component, context)
    end
end

--- Clear template cache
function Engine:clearCache()
    self.compiled = {}
    self.sourceMaps = {}
    self.cache:clear()
end

--- Get keys from table
function Engine:_getKeys(tbl)
    local keys = {}
    for k in pairs(tbl) do
        table.insert(keys, k)
    end
    return keys
end

--------------------------------------------------------------------------------
-- Express-style view engine interface
--------------------------------------------------------------------------------

--- Create a view engine for HoneyMoon/Express-style apps
---@param options table? Engine options
---@return function View engine function
function vein.express(options)
    local engine = vein.new(options)

    return function(filepath, data, callback)
        local ok, result = pcall(function()
            return engine:render(filepath, data)
        end)

        if callback then
            if ok then
                callback(nil, result)
            else
                callback(result)
            end
        else
            if ok then
                return result
            else
                error(result)
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Convenience Methods
--------------------------------------------------------------------------------

--- Quick render a template string
---@param template string Template string
---@param data table? Data
---@return string Rendered output
function vein.render(template, data)
    local engine = vein.new({ cache = false })
    return engine:renderString(template, data)
end

--------------------------------------------------------------------------------
-- Export modules
--------------------------------------------------------------------------------

vein.filters = filters
vein.loader = loader
vein.compiler = compiler
vein.runtime = runtime
vein.cache = cache
vein.metrics = metrics
vein.fragment = fragment
vein.sourcemap = sourcemap

return vein
