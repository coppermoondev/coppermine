-- Vein Compiler
-- Compiles Vein templates into executable Lua functions
--
-- @module vein.lib.compiler

local compiler = {}

-- Optional sourcemap support
local sourcemap = nil
pcall(function() sourcemap = require("vein.lib.sourcemap") end)

--------------------------------------------------------------------------------
-- Token Types
--------------------------------------------------------------------------------

local TOKEN = {
    TEXT = "TEXT",
    OUTPUT = "OUTPUT",         -- {{ expr }}
    RAW = "RAW",               -- {! expr !}
    CODE = "CODE",             -- {% code %}
    COMMENT = "COMMENT",       -- {# comment #}
    INCLUDE = "INCLUDE",       -- {@ include @}
    PARTIAL = "PARTIAL",       -- {> partial >}
}

--------------------------------------------------------------------------------
-- Lexer
--------------------------------------------------------------------------------

local function escape_pattern(s)
    return s:gsub("([^%w])", "%%%1")
end

--- Tokenize a template string
---@param template string Template source
---@param delimiters table Delimiter configuration
---@param tracker table? Position tracker for source maps
---@return table Tokens
local function tokenize(template, delimiters, tracker)
    local tokens = {}
    local pos = 1
    local len = #template

    -- Build pattern matchers
    local patterns = {
        { type = TOKEN.COMMENT, open = delimiters.comment[1], close = delimiters.comment[2] },
        { type = TOKEN.RAW, open = delimiters.raw[1], close = delimiters.raw[2] },
        { type = TOKEN.CODE, open = delimiters.code[1], close = delimiters.code[2] },
        { type = TOKEN.INCLUDE, open = delimiters.include[1], close = delimiters.include[2] },
        { type = TOKEN.PARTIAL, open = delimiters.partial[1], close = delimiters.partial[2] },
        { type = TOKEN.OUTPUT, open = delimiters.output[1], close = delimiters.output[2] },
    }

    while pos <= len do
        local nextTag = nil
        local nextPos = len + 1
        local nextType = nil
        local nextClose = nil

        -- Find the nearest opening tag
        for _, p in ipairs(patterns) do
            local tagPos = template:find(escape_pattern(p.open), pos, false)
            if tagPos and tagPos < nextPos then
                nextPos = tagPos
                nextType = p.type
                nextTag = p.open
                nextClose = p.close
            end
        end

        -- Add text before the tag
        if nextPos > pos then
            local text = template:sub(pos, nextPos - 1)
            if #text > 0 then
                local token = { type = TOKEN.TEXT, value = text }
                -- Track source position
                if tracker then
                    tracker:setPos(pos)
                    local posInfo = tracker:getPosition()
                    token.line = posInfo.line
                    token.column = posInfo.column
                end
                table.insert(tokens, token)
            end
        end

        -- Process the tag
        if nextTag then
            local closePos = template:find(escape_pattern(nextClose), nextPos + #nextTag, false)
            if not closePos then
                error(string.format("Unclosed tag '%s' at position %d", nextTag, nextPos))
            end

            local content = template:sub(nextPos + #nextTag, closePos - 1)

            -- Track source position for tag
            local tokenLine, tokenColumn
            if tracker then
                tracker:setPos(nextPos)
                local posInfo = tracker:getPosition()
                tokenLine = posInfo.line
                tokenColumn = posInfo.column
            end

            -- Skip comments
            if nextType ~= TOKEN.COMMENT then
                local token = { 
                    type = nextType, 
                    value = content:match("^%s*(.-)%s*$"),
                    line = tokenLine,
                    column = tokenColumn,
                }
                table.insert(tokens, token)
            end

            pos = closePos + #nextClose
        else
            break
        end
    end

    return tokens
end

--------------------------------------------------------------------------------
-- Parser
--------------------------------------------------------------------------------

local function parse_filters(expr)
    -- Parse expression with filters: value | filter1 | filter2(arg)
    local parts = {}
    local current = ""
    local inString = false
    local stringChar = nil
    local parenDepth = 0

    for i = 1, #expr do
        local c = expr:sub(i, i)

        if not inString then
            if c == '"' or c == "'" then
                inString = true
                stringChar = c
                current = current .. c
            elseif c == '(' then
                parenDepth = parenDepth + 1
                current = current .. c
            elseif c == ')' then
                parenDepth = parenDepth - 1
                current = current .. c
            elseif c == '|' and parenDepth == 0 then
                table.insert(parts, current:match("^%s*(.-)%s*$"))
                current = ""
            else
                current = current .. c
            end
        else
            current = current .. c
            if c == stringChar and expr:sub(i - 1, i - 1) ~= '\\' then
                inString = false
            end
        end
    end

    if #current > 0 then
        table.insert(parts, current:match("^%s*(.-)%s*$"))
    end

    return parts
end

local function compile_expression(expr, autoEscape, metricsEnabled)
    local parts = parse_filters(expr)

    if #parts == 0 then
        return "nil", {}
    end

    -- Track filters used
    local filtersUsed = {}

    -- Base expression
    local result = parts[1]

    -- Apply filters
    for i = 2, #parts do
        local filter = parts[i]
        local filterName, filterArgs = filter:match("^(%w+)%((.*)%)$")

        if filterName then
            -- Filter with arguments
            result = string.format("__filters.%s(%s, %s)", filterName, result, filterArgs)
            table.insert(filtersUsed, filterName)
        else
            -- Filter without arguments
            filterName = filter:match("^(%w+)$")
            if filterName then
                result = string.format("__filters.%s(%s)", filterName, result)
                table.insert(filtersUsed, filterName)
            else
                error(string.format("Invalid filter syntax: %s", filter))
            end
        end
    end

    -- Auto-escape if needed (only for OUTPUT, not RAW)
    if autoEscape then
        result = string.format("__filters.escape(%s)", result)
        table.insert(filtersUsed, "escape")
    end

    return result, filtersUsed
end

--------------------------------------------------------------------------------
-- Code Generator
--------------------------------------------------------------------------------

local function generate_code(tokens, engine, options)
    options = options or {}
    local code = {}
    local indent = 0
    local blockStack = {}  -- Track nested blocks
    local currentLine = 1  -- Track generated line number
    local sourceMapData = {}  -- line -> source info
    local allFiltersUsed = {}

    local function emit(line, sourceToken)
        table.insert(code, string.rep("  ", indent) .. line)
        currentLine = currentLine + 1
        
        -- Track source mapping
        if sourceToken and sourceToken.line then
            sourceMapData[currentLine] = {
                templateLine = sourceToken.line,
                templateColumn = sourceToken.column,
                tokenType = sourceToken.type,
            }
        end
    end

    local function emit_raw(line)
        table.insert(code, line)
        currentLine = currentLine + 1
    end

    -- Function header
    emit("return function(__ctx)")
    indent = indent + 1
    emit("local __output = {}")
    emit("local __filters = __ctx.__filters or {}")
    emit("local __helpers = __ctx.__helpers or {}")
    emit("local __blocks = __ctx.__blocks or {}")  -- Block storage for inheritance
    emit("__ctx.__blocks = __blocks")
    
    -- Metrics support
    if options.metrics then
        emit("local __metrics = __ctx.__metrics")
        emit("local __startTime = os.clock and os.clock() or 0")
    end
    
    -- Fragment support
    if options.fragments then
        emit("local __fragment = __ctx.__fragment")
        emit("local __useFragments = __ctx.__useFragments")
    end

    -- Create local variables from context
    emit("setmetatable(__ctx, { __index = _G })")
    emit("local _ENV = __ctx")

    -- Helper function to add output
    emit("local function __write(s)")
    emit("  if s ~= nil then")
    if options.fragments then
        emit("    if __useFragments and __fragment then")
        emit("      __fragment:add(s)")
        emit("    else")
        emit("      __output[#__output + 1] = tostring(s)")
        emit("    end")
    else
        emit("    __output[#__output + 1] = tostring(s)")
    end
    emit("  end")
    emit("end")
    emit("")

    -- Process tokens
    for _, token in ipairs(tokens) do
        if token.type == TOKEN.TEXT then
            -- Escape Lua special characters in text
            local text = token.value
            text = text:gsub("\\", "\\\\")
            text = text:gsub("\n", "\\n")
            text = text:gsub("\r", "\\r")
            text = text:gsub("\t", "\\t")
            text = text:gsub('"', '\\"')
            emit(string.format('__write("%s")', text), token)

        elseif token.type == TOKEN.OUTPUT then
            local expr, filtersUsed = compile_expression(token.value, engine.options.autoEscape, options.metrics)
            for _, f in ipairs(filtersUsed) do
                allFiltersUsed[f] = true
            end
            emit(string.format("__write(%s)", expr), token)

        elseif token.type == TOKEN.RAW then
            local expr, filtersUsed = compile_expression(token.value, false, options.metrics)
            for _, f in ipairs(filtersUsed) do
                allFiltersUsed[f] = true
            end
            emit(string.format("__write(%s)", expr), token)

        elseif token.type == TOKEN.CODE then
            local code_content = token.value

            -- Handle special constructs
            if code_content:match("^extends%s+") then
                -- Layout inheritance
                local layout = code_content:match('^extends%s+["\']([^"\']+)["\']')
                if layout then
                    emit(string.format('__ctx.__extends = "%s"', layout), token)
                end

            elseif code_content:match("^block%s+") then
                -- Block definition
                local blockName = code_content:match("^block%s+(%w+)")
                if blockName then
                    table.insert(blockStack, blockName)  -- Track block name
                    -- Check if this block is being overridden by a child template
                    emit(string.format('if __blocks["%s"] then', blockName), token)
                    emit(string.format('__write(__blocks["%s"])', blockName))
                    emit('else')
                    emit(string.format('local __block_%s_output = {}', blockName))
                    emit(string.format('local __block_%s_saved = __output', blockName))
                    emit(string.format('__output = __block_%s_output', blockName))
                end

            elseif code_content:match("^endblock") then
                -- End block
                if #blockStack > 0 then
                    local blockName = table.remove(blockStack)  -- Pop from stack
                    emit(string.format('__output = __block_%s_saved', blockName), token)
                    emit(string.format('local __block_%s_content = table.concat(__block_%s_output)', blockName, blockName))
                    emit(string.format('__blocks["%s"] = __block_%s_content', blockName, blockName))
                    emit(string.format('__write(__block_%s_content)', blockName))
                    emit('end')
                end

            elseif code_content:match("^slot%s+") then
                -- Slot definition (for components)
                local slotName = code_content:match("^slot%s+(%w+)")
                if slotName then
                    emit(string.format('if __ctx.slots and __ctx.slots.%s then', slotName), token)
                    emit(string.format('  __write(__ctx.slots.%s)', slotName))
                    emit('else')
                end

            elseif code_content:match("^endslot") then
                emit('end', token)

            elseif code_content:match("^component%s+") then
                -- Component usage
                local name, props = code_content:match('^component%s+["\']([^"\']+)["\']%s*(.*)$')
                if name then
                    local propsCode = #props > 0 and props or "{}"
                    emit(string.format('local __comp_output = {}'))
                    emit(string.format('local __comp_props = %s', propsCode))
                    emit('local __parent_output = __output')
                    emit('__output = __comp_output')
                end

            elseif code_content:match("^endcomponent") then
                emit('__output = __parent_output', token)
                emit('local __comp_content = table.concat(__comp_output)')
                emit('__write(__ctx.component(__comp_name, __comp_props, __comp_content))')

            else
                -- Regular Lua code with Jinja2-style transformations
                local transformed = code_content

                -- Transform Jinja2-style control structures to Lua

                -- endif/endfor/endwhile → end
                if transformed:match("^endif%s*$") or transformed:match("^endfor%s*$") or transformed:match("^endwhile%s*$") then
                    transformed = "end"

                -- set x = value → local x = value
                elseif transformed:match("^set%s+") then
                    transformed = transformed:gsub("^set%s+", "local ")

                -- for k, v in table (without do) → for k, v in pairs(table) do
                elseif transformed:match("^for%s+[%w_]+%s*,%s*[%w_]+%s+in%s+[^%s]+%s*$") then
                    local k, v, tbl = transformed:match("^for%s+([%w_]+)%s*,%s*([%w_]+)%s+in%s+([^%s]+)%s*$")
                    if k and v and tbl then
                        transformed = string.format("for %s, %s in pairs(%s) do", k, v, tbl)
                    end

                -- for x in table (without do) → for _, x in ipairs(table) do
                elseif transformed:match("^for%s+[%w_]+%s+in%s+[^%s]+%s*$") then
                    local var, tbl = transformed:match("^for%s+([%w_]+)%s+in%s+([^%s]+)%s*$")
                    if var and tbl then
                        transformed = string.format("for _, %s in ipairs(%s) do", var, tbl)
                    end

                -- for x in table do (with do) → for _, x in ipairs(table) do
                elseif transformed:match("^for%s+([%w_]+)%s+in%s+([%w_.%[%]\"']+)%s+do$") then
                    local var, tbl = transformed:match("^for%s+([%w_]+)%s+in%s+([%w_.%[%]\"']+)%s+do$")
                    if var and tbl then
                        transformed = string.format("for _, %s in ipairs(%s) do", var, tbl)
                    end

                -- if condition (without then) → if condition then
                elseif transformed:match("^if%s+.+") and not transformed:match("%s+then%s*$") then
                    transformed = transformed .. " then"

                -- elseif condition (without then) → elseif condition then
                elseif transformed:match("^elseif%s+.+") and not transformed:match("%s+then%s*$") then
                    transformed = transformed .. " then"
                end

                emit(transformed, token)
            end

        elseif token.type == TOKEN.INCLUDE then
            -- Include another template
            local path = token.value:match('^include%s+["\']([^"\']+)["\']') or
                         token.value:match('^["\']([^"\']+)["\']')
            if path then
                if options.metrics then
                    emit(string.format('local __inc_start = os.clock and os.clock() or 0'), token)
                    emit(string.format('__write(__ctx.include("%s", __ctx))', path))
                    emit(string.format('if __metrics then __metrics:recordInclude(__ctx.__templateName or "unknown", "%s", (os.clock and os.clock() or 0) - __inc_start) end', path))
                else
                    emit(string.format('__write(__ctx.include("%s", __ctx))', path), token)
                end
            end

        elseif token.type == TOKEN.PARTIAL then
            -- Render partial with data
            local name, data = token.value:match('^partial%s+["\']([^"\']+)["\']%s*(.*)$')
            if not name then
                name = token.value:match('^["\']([^"\']+)["\']')
            end
            if name then
                local dataCode = data and #data > 0 and data or "{}"
                emit(string.format('__write(__ctx.partial("%s", %s))', name, dataCode), token)
            end
        end
    end

    -- Return output
    emit("")
    
    -- Metrics recording at end
    if options.metrics then
        emit('if __metrics then')
        emit('  local __endTime = os.clock and os.clock() or 0')
        emit('  -- Metrics recorded by caller')
        emit('end')
    end
    
    -- If extends is used, return empty string (parent will be rendered)
    -- Otherwise return the output
    emit('if __ctx.__extends then')
    emit('  return ""')
    emit('else')
    if options.fragments then
        emit('  if __useFragments and __fragment then')
        emit('    return __fragment')
        emit('  else')
        emit('    return table.concat(__output)')
        emit('  end')
    else
        emit('  return table.concat(__output)')
    end
    emit('end')
    indent = indent - 1
    emit("end")

    return table.concat(code, "\n"), {
        sourceMap = sourceMapData,
        filtersUsed = allFiltersUsed,
        lineCount = currentLine,
        tokenCount = #tokens,
    }
end

--------------------------------------------------------------------------------
-- Compile Function
--------------------------------------------------------------------------------

--- Compile a template string into a function
---@param template string Template source
---@param engine table Vein engine instance
---@param options table? Compilation options
---@return function Compiled template function
---@return table? Compilation metadata
function compiler.compile(template, engine, options)
    options = options or {}
    
    -- Default delimiters if no engine provided
    local delimiters = engine and engine.options.delimiters or {
        output = { "{{", "}}" },
        raw = { "{!", "!}" },
        code = { "{%", "%}" },
        comment = { "{#", "#}" },
        include = { "{@", "@}" },
        partial = { "{>", ">}" },
    }

    -- Create position tracker for source maps
    local tracker = nil
    if options.sourceMap and sourcemap then
        tracker = sourcemap.createTracker(template)
    end

    -- Tokenize
    local tokens = tokenize(template, delimiters, tracker)

    -- Generate code
    local engineOpts = engine and engine.options or { autoEscape = true }
    local code, metadata = generate_code(tokens, { options = engineOpts }, {
        metrics = options.metrics or (engine and engine.options.metrics),
        fragments = options.fragments or (engine and engine.options.fragments),
        sourceMap = options.sourceMap or (engine and engine.options.sourceMap),
    })

    -- Create source map if enabled
    local smap = nil
    if options.sourceMap and sourcemap and options.templateName then
        smap = sourcemap.new(options.templateName, template)
        for genLine, info in pairs(metadata.sourceMap) do
            smap:addMapping(genLine, info.templateLine, info.templateColumn, info.tokenType)
        end
        -- Track generated lines
        local lineNum = 1
        for line in (code .. "\n"):gmatch("([^\n]*)\n") do
            smap:trackGeneratedLine(lineNum, line)
            lineNum = lineNum + 1
        end
    end

    -- Append source map comment if debug mode
    if options.sourceMap and smap and options.debug then
        code = code .. "\n\n" .. smap:toComment()
    end

    -- Compile to function
    local fn, err = load(code, "vein_template", "t")

    if not fn then
        local errorInfo = nil
        if smap then
            errorInfo = smap:resolveError(err or "")
        end
        
        if engine and engine.options.debug then
            local errorMsg = string.format("Vein compilation error: %s", err)
            if errorInfo then
                errorMsg = errorMsg .. "\n\n" .. smap:formatError(errorInfo)
            end
            errorMsg = errorMsg .. "\n\nGenerated code:\n" .. code
            error(errorMsg)
        else
            error(string.format("Template compilation error: %s", err))
        end
    end

    -- Return the template function (result of calling fn())
    local ok, template_fn = pcall(fn)
    if not ok then
        error(string.format("Template initialization error: %s", template_fn))
    end

    -- Attach metadata to function
    if options.returnMetadata then
        return template_fn, {
            sourceMap = smap,
            filtersUsed = metadata.filtersUsed,
            lineCount = metadata.lineCount,
            tokenCount = metadata.tokenCount,
            generatedCode = options.debug and code or nil,
        }
    end

    return template_fn
end

--- Generate Lua code from template (for debugging)
---@param template string Template source
---@param engine table? Vein engine instance
---@param options table? Options
---@return string Generated Lua code
---@return table? Metadata
function compiler.generateCode(template, engine, options)
    options = options or {}
    
    local delimiters = engine and engine.options.delimiters or {
        output = { "{{", "}}" },
        raw = { "{!", "!}" },
        code = { "{%", "%}" },
        comment = { "{#", "#}" },
        include = { "{@", "@}" },
        partial = { "{>", ">}" },
    }

    local tracker = nil
    if options.sourceMap and sourcemap then
        tracker = sourcemap.createTracker(template)
    end

    local tokens = tokenize(template, delimiters, tracker)
    return generate_code(tokens, engine or { options = { autoEscape = true } }, options)
end

--- Get token list from template (for debugging/analysis)
---@param template string Template source
---@param delimiters table? Delimiter configuration
---@return table Tokens
function compiler.tokenize(template, delimiters)
    delimiters = delimiters or {
        output = { "{{", "}}" },
        raw = { "{!", "!}" },
        code = { "{%", "%}" },
        comment = { "{#", "#}" },
        include = { "{@", "@}" },
        partial = { "{>", ">}" },
    }
    
    local tracker = nil
    if sourcemap then
        tracker = sourcemap.createTracker(template)
    end
    
    return tokenize(template, delimiters, tracker)
end

return compiler
