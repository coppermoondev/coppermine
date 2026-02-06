-- Vein Metrics
-- Performance and debug metrics collection for templates
--
-- @module vein.lib.metrics

local metrics = {}

--------------------------------------------------------------------------------
-- Metrics Collector Class
--------------------------------------------------------------------------------

local Collector = {}
Collector.__index = Collector

--- Create a new metrics collector
---@return Collector
function metrics.new()
    local self = setmetatable({}, Collector)
    
    -- Render metrics
    self.renders = {}
    self.totalRenders = 0
    self.totalRenderTime = 0
    
    -- Compilation metrics
    self.compilations = {}
    self.totalCompilations = 0
    self.totalCompileTime = 0
    
    -- Cache metrics
    self.cacheHits = 0
    self.cacheMisses = 0
    
    -- Error tracking
    self.errors = {}
    self.totalErrors = 0
    
    -- Filter usage
    self.filterUsage = {}
    
    -- Include/partial tracking
    self.includes = {}
    
    -- Block tracking
    self.blocks = {}
    
    -- Enable/disable
    self.enabled = true
    
    -- Max history size
    self.maxHistory = 100
    
    return self
end

--------------------------------------------------------------------------------
-- Recording Methods
--------------------------------------------------------------------------------

--- Record a template render
---@param name string Template name
---@param startTime number Start time (os.clock())
---@param endTime number End time
---@param data table? Additional data
function Collector:recordRender(name, startTime, endTime, data)
    if not self.enabled then return end
    
    local duration = (endTime - startTime) * 1000 -- ms
    
    local record = {
        name = name,
        duration = duration,
        timestamp = os.time(),
        dataKeys = data and self:_getKeys(data) or {},
        memory = collectgarbage("count"),
    }
    
    -- Update totals
    self.totalRenders = self.totalRenders + 1
    self.totalRenderTime = self.totalRenderTime + duration
    
    -- Per-template stats
    if not self.renders[name] then
        self.renders[name] = {
            count = 0,
            totalTime = 0,
            minTime = math.huge,
            maxTime = 0,
            history = {},
        }
    end
    
    local stats = self.renders[name]
    stats.count = stats.count + 1
    stats.totalTime = stats.totalTime + duration
    stats.minTime = math.min(stats.minTime, duration)
    stats.maxTime = math.max(stats.maxTime, duration)
    stats.lastRender = record
    
    -- Keep history (limited)
    table.insert(stats.history, record)
    while #stats.history > self.maxHistory do
        table.remove(stats.history, 1)
    end
end

--- Record a template compilation
---@param name string Template name
---@param startTime number Start time
---@param endTime number End time
---@param tokenCount number Number of tokens
---@param codeLines number Generated code lines
function Collector:recordCompilation(name, startTime, endTime, tokenCount, codeLines)
    if not self.enabled then return end
    
    local duration = (endTime - startTime) * 1000
    
    local record = {
        name = name,
        duration = duration,
        timestamp = os.time(),
        tokenCount = tokenCount,
        codeLines = codeLines,
    }
    
    self.totalCompilations = self.totalCompilations + 1
    self.totalCompileTime = self.totalCompileTime + duration
    
    if not self.compilations[name] then
        self.compilations[name] = {
            count = 0,
            totalTime = 0,
            lastCompilation = nil,
        }
    end
    
    local stats = self.compilations[name]
    stats.count = stats.count + 1
    stats.totalTime = stats.totalTime + duration
    stats.lastCompilation = record
end

--- Record a cache hit
---@param name string Template name
function Collector:recordCacheHit(name)
    if not self.enabled then return end
    self.cacheHits = self.cacheHits + 1
end

--- Record a cache miss
---@param name string Template name
function Collector:recordCacheMiss(name)
    if not self.enabled then return end
    self.cacheMisses = self.cacheMisses + 1
end

--- Record an error
---@param name string Template name
---@param error string Error message
---@param line number? Line number
---@param source string? Source context
function Collector:recordError(name, error, line, source)
    if not self.enabled then return end
    
    self.totalErrors = self.totalErrors + 1
    
    local record = {
        name = name,
        error = error,
        line = line,
        source = source,
        timestamp = os.time(),
    }
    
    table.insert(self.errors, record)
    while #self.errors > self.maxHistory do
        table.remove(self.errors, 1)
    end
end

--- Record filter usage
---@param filterName string Filter name
function Collector:recordFilterUsage(filterName)
    if not self.enabled then return end
    
    self.filterUsage[filterName] = (self.filterUsage[filterName] or 0) + 1
end

--- Record an include
---@param parent string Parent template
---@param child string Included template
---@param duration number Time taken
function Collector:recordInclude(parent, child, duration)
    if not self.enabled then return end
    
    if not self.includes[parent] then
        self.includes[parent] = {}
    end
    
    table.insert(self.includes[parent], {
        child = child,
        duration = duration,
        timestamp = os.time(),
    })
end

--- Record block usage
---@param template string Template name
---@param blockName string Block name
---@param overridden boolean Was it overridden
function Collector:recordBlock(template, blockName, overridden)
    if not self.enabled then return end
    
    if not self.blocks[template] then
        self.blocks[template] = {}
    end
    
    self.blocks[template][blockName] = {
        overridden = overridden,
        timestamp = os.time(),
    }
end

--------------------------------------------------------------------------------
-- Retrieval Methods
--------------------------------------------------------------------------------

--- Get summary statistics
---@return table Summary
function Collector:getSummary()
    return {
        renders = {
            total = self.totalRenders,
            totalTime = self.totalRenderTime,
            avgTime = self.totalRenders > 0 and (self.totalRenderTime / self.totalRenders) or 0,
            uniqueTemplates = self:_countKeys(self.renders),
        },
        compilations = {
            total = self.totalCompilations,
            totalTime = self.totalCompileTime,
            avgTime = self.totalCompilations > 0 and (self.totalCompileTime / self.totalCompilations) or 0,
        },
        cache = {
            hits = self.cacheHits,
            misses = self.cacheMisses,
            hitRate = (self.cacheHits + self.cacheMisses) > 0 
                and (self.cacheHits / (self.cacheHits + self.cacheMisses) * 100) or 0,
        },
        errors = {
            total = self.totalErrors,
            recent = #self.errors,
        },
        memory = collectgarbage("count"),
    }
end

--- Get render stats for a specific template
---@param name string Template name
---@return table? Stats
function Collector:getRenderStats(name)
    local stats = self.renders[name]
    if not stats then return nil end
    
    return {
        count = stats.count,
        totalTime = stats.totalTime,
        avgTime = stats.count > 0 and (stats.totalTime / stats.count) or 0,
        minTime = stats.minTime ~= math.huge and stats.minTime or 0,
        maxTime = stats.maxTime,
        lastRender = stats.lastRender,
        historyCount = #stats.history,
    }
end

--- Get all render stats
---@return table Stats by template
function Collector:getAllRenderStats()
    local result = {}
    for name in pairs(self.renders) do
        result[name] = self:getRenderStats(name)
    end
    return result
end

--- Get recent errors
---@param limit number? Max errors to return
---@return table Errors
function Collector:getRecentErrors(limit)
    limit = limit or 10
    local result = {}
    local start = math.max(1, #self.errors - limit + 1)
    for i = start, #self.errors do
        table.insert(result, self.errors[i])
    end
    return result
end

--- Get filter usage stats
---@return table Filter usage
function Collector:getFilterUsage()
    -- Sort by usage
    local sorted = {}
    for name, count in pairs(self.filterUsage) do
        table.insert(sorted, { name = name, count = count })
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)
    return sorted
end

--- Get slowest templates
---@param limit number? Max templates to return
---@return table Slow templates
function Collector:getSlowestTemplates(limit)
    limit = limit or 10
    local sorted = {}
    
    for name, stats in pairs(self.renders) do
        local avgTime = stats.count > 0 and (stats.totalTime / stats.count) or 0
        table.insert(sorted, {
            name = name,
            avgTime = avgTime,
            maxTime = stats.maxTime,
            count = stats.count,
        })
    end
    
    table.sort(sorted, function(a, b) return a.avgTime > b.avgTime end)
    
    local result = {}
    for i = 1, math.min(limit, #sorted) do
        table.insert(result, sorted[i])
    end
    return result
end

--- Get include tree for a template
---@param name string Template name
---@return table? Include tree
function Collector:getIncludeTree(name)
    return self.includes[name]
end

--- Export all metrics as JSON-friendly table
---@return table All metrics
function Collector:export()
    return {
        summary = self:getSummary(),
        renders = self:getAllRenderStats(),
        compilations = self.compilations,
        errors = self.errors,
        filterUsage = self:getFilterUsage(),
        includes = self.includes,
        blocks = self.blocks,
        enabled = self.enabled,
        exportTime = os.time(),
    }
end

--------------------------------------------------------------------------------
-- Control Methods
--------------------------------------------------------------------------------

--- Enable metrics collection
function Collector:enable()
    self.enabled = true
end

--- Disable metrics collection
function Collector:disable()
    self.enabled = false
end

--- Reset all metrics
function Collector:reset()
    self.renders = {}
    self.totalRenders = 0
    self.totalRenderTime = 0
    self.compilations = {}
    self.totalCompilations = 0
    self.totalCompileTime = 0
    self.cacheHits = 0
    self.cacheMisses = 0
    self.errors = {}
    self.totalErrors = 0
    self.filterUsage = {}
    self.includes = {}
    self.blocks = {}
end

--- Set max history size
---@param size number Max entries
function Collector:setMaxHistory(size)
    self.maxHistory = size
end

--------------------------------------------------------------------------------
-- Utility Methods
--------------------------------------------------------------------------------

function Collector:_getKeys(tbl)
    local keys = {}
    for k in pairs(tbl) do
        if type(k) == "string" and not k:match("^__") then
            table.insert(keys, k)
        end
    end
    return keys
end

function Collector:_countKeys(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

--------------------------------------------------------------------------------
-- Global instance (optional)
--------------------------------------------------------------------------------

metrics.global = nil

--- Get or create global metrics instance
---@return Collector
function metrics.getGlobal()
    if not metrics.global then
        metrics.global = metrics.new()
    end
    return metrics.global
end

return metrics
