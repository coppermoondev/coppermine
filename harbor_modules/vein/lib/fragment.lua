-- Vein Fragments
-- Support for returning arrays/iterators instead of concatenated strings
--
-- @module vein.lib.fragment

local fragment = {}

--------------------------------------------------------------------------------
-- Fragment Class
--------------------------------------------------------------------------------

local Fragment = {}
Fragment.__index = Fragment

--- Create a new fragment
---@param parts table? Initial parts array
---@return Fragment
function fragment.new(parts)
    local self = setmetatable({}, Fragment)
    self.parts = parts or {}
    self.metadata = {}
    return self
end

--- Check if value is a Fragment
---@param value any Value to check
---@return boolean
function fragment.isFragment(value)
    return type(value) == "table" and getmetatable(value) == Fragment
end

--------------------------------------------------------------------------------
-- Building Methods
--------------------------------------------------------------------------------

--- Add a part to the fragment
---@param value any Value to add
---@return Fragment self
function Fragment:add(value)
    if value ~= nil then
        if fragment.isFragment(value) then
            -- Merge fragments
            for _, part in ipairs(value.parts) do
                table.insert(self.parts, part)
            end
        else
            table.insert(self.parts, tostring(value))
        end
    end
    return self
end

--- Add raw HTML (marked as safe)
---@param html string HTML content
---@return Fragment self
function Fragment:raw(html)
    table.insert(self.parts, {
        type = "raw",
        content = html,
    })
    return self
end

--- Add text (will be escaped when rendered)
---@param text string Text content
---@return Fragment self
function Fragment:text(text)
    table.insert(self.parts, {
        type = "text",
        content = text,
    })
    return self
end

--- Add a component placeholder
---@param name string Component name
---@param props table? Component properties
---@return Fragment self
function Fragment:component(name, props)
    table.insert(self.parts, {
        type = "component",
        name = name,
        props = props or {},
    })
    return self
end

--- Add a slot placeholder
---@param name string Slot name
---@param defaultContent string? Default content
---@return Fragment self
function Fragment:slot(name, defaultContent)
    table.insert(self.parts, {
        type = "slot",
        name = name,
        default = defaultContent,
    })
    return self
end

--- Add metadata to the fragment
---@param key string Metadata key
---@param value any Metadata value
---@return Fragment self
function Fragment:meta(key, value)
    self.metadata[key] = value
    return self
end

--------------------------------------------------------------------------------
-- Rendering Methods
--------------------------------------------------------------------------------

--- Convert fragment to string
---@param options table? Render options
---@return string Rendered string
function Fragment:toString(options)
    options = options or {}
    local escape = options.escape or function(s)
        return tostring(s)
            :gsub("&", "&amp;")
            :gsub("<", "&lt;")
            :gsub(">", "&gt;")
            :gsub('"', "&quot;")
            :gsub("'", "&#39;")
    end
    
    local result = {}
    
    for _, part in ipairs(self.parts) do
        if type(part) == "string" then
            table.insert(result, part)
        elseif type(part) == "table" then
            if part.type == "raw" then
                table.insert(result, part.content)
            elseif part.type == "text" then
                table.insert(result, escape(part.content))
            elseif part.type == "slot" then
                -- Slot handling (should be resolved by renderer)
                table.insert(result, part.default or "")
            elseif part.type == "component" then
                -- Component placeholder (should be resolved by renderer)
                table.insert(result, string.format("<!-- component:%s -->", part.name))
            end
        end
    end
    
    return table.concat(result)
end

--- Alias for toString
function Fragment:render(options)
    return self:toString(options)
end

--- Get string representation (for tostring())
function Fragment:__tostring()
    return self:toString()
end

--- Concatenation operator
function Fragment:__concat(other)
    local result = fragment.new()
    result:add(self)
    result:add(other)
    return result
end

--------------------------------------------------------------------------------
-- Iteration Methods
--------------------------------------------------------------------------------

--- Get iterator over parts
---@return function Iterator
function Fragment:iter()
    local i = 0
    return function()
        i = i + 1
        if self.parts[i] then
            return i, self.parts[i]
        end
    end
end

--- Get parts array
---@return table Parts
function Fragment:getParts()
    return self.parts
end

--- Get part count
---@return number Count
function Fragment:count()
    return #self.parts
end

--- Check if empty
---@return boolean Is empty
function Fragment:isEmpty()
    return #self.parts == 0
end

--------------------------------------------------------------------------------
-- Transformation Methods
--------------------------------------------------------------------------------

--- Map over parts
---@param fn function Transform function
---@return Fragment New fragment
function Fragment:map(fn)
    local result = fragment.new()
    for i, part in ipairs(self.parts) do
        local transformed = fn(part, i)
        if transformed ~= nil then
            result:add(transformed)
        end
    end
    return result
end

--- Filter parts
---@param fn function Predicate function
---@return Fragment New fragment
function Fragment:filter(fn)
    local result = fragment.new()
    for i, part in ipairs(self.parts) do
        if fn(part, i) then
            table.insert(result.parts, part)
        end
    end
    return result
end

--- Find first matching part
---@param fn function Predicate function
---@return any? Found part
function Fragment:find(fn)
    for i, part in ipairs(self.parts) do
        if fn(part, i) then
            return part
        end
    end
    return nil
end

--------------------------------------------------------------------------------
-- Streaming Support
--------------------------------------------------------------------------------

--- Create a streaming fragment (for chunked output)
---@return StreamingFragment
function fragment.stream()
    local stream = {
        parts = {},
        callbacks = {},
        finished = false,
    }
    
    --- Add a part and notify listeners
    function stream:write(value)
        if self.finished then return end
        table.insert(self.parts, value)
        for _, cb in ipairs(self.callbacks) do
            cb(value)
        end
    end
    
    --- Subscribe to new parts
    function stream:onPart(callback)
        table.insert(self.callbacks, callback)
    end
    
    --- Mark stream as finished
    function stream:finish()
        self.finished = true
        for _, cb in ipairs(self.callbacks) do
            cb(nil, true) -- nil value, finished flag
        end
    end
    
    --- Get all parts so far
    function stream:collect()
        return self.parts
    end
    
    --- Convert to string
    function stream:toString()
        local result = {}
        for _, part in ipairs(self.parts) do
            table.insert(result, tostring(part))
        end
        return table.concat(result)
    end
    
    return stream
end

--------------------------------------------------------------------------------
-- Fragment Builder (fluent API)
--------------------------------------------------------------------------------

--- Create a fragment builder
---@return FragmentBuilder
function fragment.builder()
    local builder = {
        frag = fragment.new(),
    }
    
    setmetatable(builder, {
        __index = function(t, key)
            -- Proxy common fragment methods
            if key == "build" then
                return function() return t.frag end
            elseif type(t.frag[key]) == "function" then
                return function(_, ...)
                    t.frag[key](t.frag, ...)
                    return t
                end
            end
        end
    })
    
    return builder
end

--------------------------------------------------------------------------------
-- HTML helpers
--------------------------------------------------------------------------------

--- Create an HTML element fragment
---@param tag string Tag name
---@param attrs table? Attributes
---@param content any? Content (string, Fragment, or function)
---@return Fragment
function fragment.element(tag, attrs, content)
    local frag = fragment.new()
    
    -- Opening tag
    local attrStr = ""
    if attrs then
        local attrParts = {}
        for k, v in pairs(attrs) do
            if v == true then
                table.insert(attrParts, k)
            elseif v then
                table.insert(attrParts, string.format('%s="%s"', k, tostring(v)))
            end
        end
        if #attrParts > 0 then
            attrStr = " " .. table.concat(attrParts, " ")
        end
    end
    
    -- Self-closing tags
    local selfClosing = {
        area = true, base = true, br = true, col = true,
        embed = true, hr = true, img = true, input = true,
        link = true, meta = true, source = true, track = true, wbr = true,
    }
    
    if selfClosing[tag:lower()] then
        frag:raw(string.format("<%s%s />", tag, attrStr))
    else
        frag:raw(string.format("<%s%s>", tag, attrStr))
        
        if content then
            if type(content) == "function" then
                frag:add(content())
            else
                frag:add(content)
            end
        end
        
        frag:raw(string.format("</%s>", tag))
    end
    
    return frag
end

--- Shorthand for div
---@param attrs table? Attributes
---@param content any? Content
---@return Fragment
function fragment.div(attrs, content)
    return fragment.element("div", attrs, content)
end

--- Shorthand for span
---@param attrs table? Attributes
---@param content any? Content
---@return Fragment
function fragment.span(attrs, content)
    return fragment.element("span", attrs, content)
end

return fragment
