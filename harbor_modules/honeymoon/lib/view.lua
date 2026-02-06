-- HoneyMoon View Engine Integration
-- Integrates Vein templating with HoneyMoon
--
-- @module honeymoon.lib.view

local view = {}

--------------------------------------------------------------------------------
-- View Engine Class
--------------------------------------------------------------------------------

local ViewEngine = {}
ViewEngine.__index = ViewEngine

--- Create a new view engine
---@param app table HoneyMoon application
---@return ViewEngine
function view.new(app)
    local self = setmetatable({}, ViewEngine)

    self.app = app
    self.engine = nil
    self.engineName = nil
    self.options = {
        views = "./views",
        layouts = "./views/layouts",
        partials = "./views/partials",
        components = "./views/components",
        cache = true,
        extension = ".vein",
    }

    return self
end

--- Configure the view engine
---@param option string|table Option name or table of options
---@param value any? Option value
---@return ViewEngine self
function ViewEngine:set(option, value)
    if type(option) == "table" then
        for k, v in pairs(option) do
            self.options[k] = v
        end
    else
        self.options[option] = value
    end

    -- Update engine if already initialized
    if self.engine and self.engine.set then
        self.engine:set(option, value)
    end

    return self
end

--- Set the view engine
---@param name string Engine name ('vein' supported)
---@param engine table? Custom engine instance
---@return ViewEngine self
function ViewEngine:use(name, engine)
    self.engineName = name

    if engine then
        -- Use provided engine
        self.engine = engine
    else
        -- Load built-in engine
        if name == "vein" then
            local ok, vein = pcall(require, "vein")
            if ok then
                self.engine = vein.new(self.options)
            else
                error("Vein templating engine not found. Install it with: harbor install vein")
            end
        else
            error(string.format("Unknown view engine: %s", name))
        end
    end

    return self
end

--- Add a global variable to views
---@param key string|table Variable name or table
---@param value any? Variable value
---@return ViewEngine self
function ViewEngine:global(key, value)
    if self.engine and self.engine.global then
        self.engine:global(key, value)
    end
    return self
end

--- Add a custom filter
---@param name string Filter name
---@param fn function Filter function
---@return ViewEngine self
function ViewEngine:filter(name, fn)
    if self.engine and self.engine.filter then
        self.engine:filter(name, fn)
    end
    return self
end

--- Add a custom helper
---@param name string Helper name
---@param fn function Helper function
---@return ViewEngine self
function ViewEngine:helper(name, fn)
    if self.engine and self.engine.helper then
        self.engine:helper(name, fn)
    end
    return self
end

--- Register a component
---@param name string Component name
---@param template string|function Template or render function
---@return ViewEngine self
function ViewEngine:component(name, template)
    if self.engine and self.engine.component then
        self.engine:component(name, template)
    end
    return self
end

--- Render a template
---@param name string Template name
---@param data table? Data to pass
---@return string Rendered HTML
function ViewEngine:render(name, data)
    if not self.engine then
        error("No view engine configured. Use app.views:use('vein') first.")
    end

    -- Add app-level globals
    local context = data or {}
    context.app = self.app

    return self.engine:render(name, context)
end

--- Render a string template
---@param template string Template string
---@param data table? Data to pass
---@return string Rendered HTML
function ViewEngine:renderString(template, data)
    if not self.engine then
        error("No view engine configured. Use app.views:use('vein') first.")
    end

    local context = data or {}
    context.app = self.app

    return self.engine:renderString(template, context)
end

--- Clear template cache
function ViewEngine:clearCache()
    if self.engine and self.engine.clearCache then
        self.engine:clearCache()
    end
end

return view
