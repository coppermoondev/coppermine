-- Vein Source Maps
-- Maps generated Lua code back to original template lines
--
-- @module vein.lib.sourcemap

local sourcemap = {}

--------------------------------------------------------------------------------
-- Source Map Class
--------------------------------------------------------------------------------

local SourceMap = {}
SourceMap.__index = SourceMap

--- Create a new source map
---@param templateName string Template name/path
---@param templateSource string Original template source
---@return SourceMap
function sourcemap.new(templateName, templateSource)
    local self = setmetatable({}, SourceMap)
    
    self.templateName = templateName
    self.templateSource = templateSource
    self.templateLines = {}
    
    -- Parse template into lines
    for line in (templateSource .. "\n"):gmatch("([^\n]*)\n") do
        table.insert(self.templateLines, line)
    end
    
    -- Mappings: generated line -> { templateLine, column, tokenType, content }
    self.mappings = {}
    
    -- Current position tracking during compilation
    self.currentTemplateLine = 1
    self.currentTemplateColumn = 1
    
    -- Generated code tracking
    self.generatedLines = {}
    
    return self
end

--------------------------------------------------------------------------------
-- Mapping Methods
--------------------------------------------------------------------------------

--- Add a mapping from generated line to template position
---@param generatedLine number Line in generated Lua code
---@param templateLine number Line in original template
---@param templateColumn number? Column in original template
---@param tokenType string? Type of token (TEXT, OUTPUT, CODE, etc.)
---@param content string? Original content
function SourceMap:addMapping(generatedLine, templateLine, templateColumn, tokenType, content)
    self.mappings[generatedLine] = {
        templateLine = templateLine,
        templateColumn = templateColumn or 1,
        tokenType = tokenType,
        content = content,
    }
end

--- Set current template position (for tracking during tokenization)
---@param line number Template line
---@param column number? Template column
function SourceMap:setPosition(line, column)
    self.currentTemplateLine = line
    self.currentTemplateColumn = column or 1
end

--- Get current template position
---@return number, number Line and column
function SourceMap:getPosition()
    return self.currentTemplateLine, self.currentTemplateColumn
end

--- Track a generated line
---@param generatedLine number Line number
---@param code string Generated code
function SourceMap:trackGeneratedLine(generatedLine, code)
    self.generatedLines[generatedLine] = code
end

--------------------------------------------------------------------------------
-- Lookup Methods
--------------------------------------------------------------------------------

--- Get template position for a generated line
---@param generatedLine number Line in generated code
---@return table? Mapping info
function SourceMap:getMapping(generatedLine)
    return self.mappings[generatedLine]
end

--- Get template line content
---@param line number Template line number
---@return string? Line content
function SourceMap:getTemplateLine(line)
    return self.templateLines[line]
end

--- Get generated code line
---@param line number Generated line number
---@return string? Line content
function SourceMap:getGeneratedLine(line)
    return self.generatedLines[line]
end

--- Find template position from error message
---@param errorMsg string Error message containing line number
---@return table? Position info with context
function SourceMap:resolveError(errorMsg)
    -- Extract line number from error like "[string "..."]:42: error message"
    local generatedLine = tonumber(errorMsg:match(":(%d+):"))
    
    if not generatedLine then
        return nil
    end
    
    local mapping = self.mappings[generatedLine]
    if not mapping then
        -- Try nearby lines
        for offset = 1, 5 do
            mapping = self.mappings[generatedLine - offset] or self.mappings[generatedLine + offset]
            if mapping then break end
        end
    end
    
    if not mapping then
        return nil
    end
    
    -- Get context lines
    local contextBefore = {}
    local contextAfter = {}
    
    for i = math.max(1, mapping.templateLine - 3), mapping.templateLine - 1 do
        table.insert(contextBefore, {
            line = i,
            content = self.templateLines[i] or "",
        })
    end
    
    for i = mapping.templateLine + 1, math.min(#self.templateLines, mapping.templateLine + 3) do
        table.insert(contextAfter, {
            line = i,
            content = self.templateLines[i] or "",
        })
    end
    
    return {
        templateName = self.templateName,
        templateLine = mapping.templateLine,
        templateColumn = mapping.templateColumn,
        tokenType = mapping.tokenType,
        lineContent = self.templateLines[mapping.templateLine],
        generatedLine = generatedLine,
        generatedCode = self.generatedLines[generatedLine],
        contextBefore = contextBefore,
        contextAfter = contextAfter,
        originalError = errorMsg,
    }
end

--------------------------------------------------------------------------------
-- Export Methods
--------------------------------------------------------------------------------

--- Export source map as JSON-compatible table
---@return table Source map data
function SourceMap:export()
    return {
        version = 1,
        templateName = self.templateName,
        templateLineCount = #self.templateLines,
        generatedLineCount = #self.generatedLines,
        mappings = self.mappings,
    }
end

--- Generate inline source map comment (for debugging)
---@return string Comment to append to generated code
function SourceMap:toComment()
    local lines = {
        "-- Source Map for: " .. self.templateName,
        "-- Template lines: " .. #self.templateLines,
        "-- Mappings:",
    }
    
    for genLine, mapping in pairs(self.mappings) do
        table.insert(lines, string.format(
            "--   L%d -> %s:%d (%s)",
            genLine,
            self.templateName,
            mapping.templateLine,
            mapping.tokenType or "?"
        ))
    end
    
    return table.concat(lines, "\n")
end

--- Format error with source context
---@param errorInfo table From resolveError()
---@return string Formatted error message
function SourceMap:formatError(errorInfo)
    if not errorInfo then
        return "Unknown error location"
    end
    
    local lines = {
        string.format("Error in template '%s' at line %d:", 
            errorInfo.templateName, 
            errorInfo.templateLine),
        "",
    }
    
    -- Context before
    for _, ctx in ipairs(errorInfo.contextBefore) do
        table.insert(lines, string.format("  %4d | %s", ctx.line, ctx.content))
    end
    
    -- Error line with marker
    table.insert(lines, string.format("> %4d | %s", errorInfo.templateLine, errorInfo.lineContent or ""))
    
    -- Column marker if available
    if errorInfo.templateColumn and errorInfo.templateColumn > 1 then
        local marker = string.rep(" ", errorInfo.templateColumn + 8) .. "^"
        table.insert(lines, marker)
    end
    
    -- Context after
    for _, ctx in ipairs(errorInfo.contextAfter) do
        table.insert(lines, string.format("  %4d | %s", ctx.line, ctx.content))
    end
    
    -- Token info
    if errorInfo.tokenType then
        table.insert(lines, "")
        table.insert(lines, string.format("Token type: %s", errorInfo.tokenType))
    end
    
    return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- Factory with position tracking
--------------------------------------------------------------------------------

--- Create a position tracker for tokenization
---@param source string Template source
---@return table Tracker with methods
function sourcemap.createTracker(source)
    local tracker = {
        source = source,
        pos = 1,
        line = 1,
        column = 1,
    }
    
    --- Advance position by n characters
    function tracker:advance(n)
        for i = 1, n do
            local char = self.source:sub(self.pos + i - 1, self.pos + i - 1)
            if char == "\n" then
                self.line = self.line + 1
                self.column = 1
            else
                self.column = self.column + 1
            end
        end
        self.pos = self.pos + n
    end
    
    --- Set position directly
    function tracker:setPos(pos)
        -- Recalculate line/column from start
        self.line = 1
        self.column = 1
        for i = 1, pos - 1 do
            local char = self.source:sub(i, i)
            if char == "\n" then
                self.line = self.line + 1
                self.column = 1
            else
                self.column = self.column + 1
            end
        end
        self.pos = pos
    end
    
    --- Get current position info
    function tracker:getPosition()
        return {
            pos = self.pos,
            line = self.line,
            column = self.column,
        }
    end
    
    return tracker
end

return sourcemap
