-- Vein Template Loader
-- Handles loading templates from files and various sources
--
-- @module vein.lib.loader

local loader = {}

--------------------------------------------------------------------------------
-- File System Loader
--------------------------------------------------------------------------------

--- Load a template from file
---@param name string Template name or path
---@param options table Engine options
---@return string Template content
function loader.load(name, options)
    options = options or {}

    local viewsDir = options.views or "./views"
    local extension = options.extension or ".vein"

    -- Build full path
    local path = name

    -- Add extension if not present
    if not path:match("%.[^/\\]+$") then
        path = path .. extension
    end

    -- Make relative to views directory if not absolute
    if not path:match("^[/\\]") and not path:match("^%a:") then
        path = viewsDir .. "/" .. path
    end

    -- Normalize path separators
    path = path:gsub("\\", "/")
    path = path:gsub("//+", "/")

    -- Try to read file
    local file, err = io.open(path, "r")

    if not file then
        -- Try without views prefix
        file, err = io.open(name .. extension, "r")
    end

    if not file then
        -- Try exact name
        file, err = io.open(name, "r")
    end

    if not file then
        error(string.format("Template not found: %s (tried: %s)", name, path))
    end

    local content = file:read("*all")
    file:close()

    return content
end

--------------------------------------------------------------------------------
-- Custom Loaders
--------------------------------------------------------------------------------

--- Create a memory loader (for testing or dynamic templates)
---@param templates table Table of name -> content
---@return function Loader function
function loader.memory(templates)
    return function(name, options)
        local template = templates[name]
        if not template then
            error(string.format("Template not found in memory: %s", name))
        end
        return template
    end
end

--- Create a loader that tries multiple sources
---@param loaders table Array of loader functions
---@return function Combined loader
function loader.chain(loaders)
    return function(name, options)
        local errors = {}

        for _, load_fn in ipairs(loaders) do
            local ok, result = pcall(load_fn, name, options)
            if ok then
                return result
            end
            table.insert(errors, result)
        end

        error(string.format("Template not found: %s\nTried:\n%s", name, table.concat(errors, "\n")))
    end
end

--- Create a loader with prefix
---@param prefix string Path prefix
---@param baseLoader function? Base loader (default: file loader)
---@return function Prefixed loader
function loader.prefix(prefix, baseLoader)
    baseLoader = baseLoader or loader.load

    return function(name, options)
        return baseLoader(prefix .. "/" .. name, options)
    end
end

--------------------------------------------------------------------------------
-- Path Utilities
--------------------------------------------------------------------------------

--- Resolve relative path from base
---@param base string Base path
---@param relative string Relative path
---@return string Resolved path
function loader.resolve(base, relative)
    -- If relative is absolute, return as-is
    if relative:match("^[/\\]") or relative:match("^%a:") then
        return relative
    end

    -- Get directory of base
    local baseDir = base:match("^(.+)[/\\]") or "."

    -- Handle ../ and ./
    local parts = {}
    for part in baseDir:gmatch("[^/\\]+") do
        table.insert(parts, part)
    end

    for part in relative:gmatch("[^/\\]+") do
        if part == ".." then
            table.remove(parts)
        elseif part ~= "." then
            table.insert(parts, part)
        end
    end

    return table.concat(parts, "/")
end

--- Check if path is safe (no directory traversal)
---@param path string Path to check
---@param root string? Root directory
---@return boolean is_safe
function loader.isSafe(path, root)
    -- Normalize path
    local normalized = path:gsub("\\", "/")

    -- Check for directory traversal
    if normalized:match("%.%.") then
        return false
    end

    -- Check for absolute paths if root is specified
    if root then
        if normalized:match("^/") or normalized:match("^%a:") then
            return false
        end
    end

    return true
end

return loader
