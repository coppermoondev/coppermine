-- Ember - HoneyMoon Integration
-- Middleware that creates per-request child loggers and logs request completion

local honeymoon = {}

--- Create HoneyMoon middleware
---@param logger Logger       The root Ember logger
---@param options table|nil   Options
---@return function middleware
function honeymoon.middleware(logger, options)
    options = options or {}
    local completionLevel = options.level or "info"
    local requestIdHeader = options.requestIdHeader or "x-request-id"
    local autoLog = options.autoLog ~= false
    local ignorePaths = options.ignorePaths or {}
    local customProps = options.customProps

    return function(req, res, next)
        -- Check ignored paths
        for _, p in ipairs(ignorePaths) do
            if req.path:sub(1, #p) == p then
                return next()
            end
        end

        -- Get or generate request ID
        local requestId = req.id
        if not requestId then
            if options.genReqId then
                requestId = options.genReqId(req)
            elseif req.headers and req.headers[requestIdHeader] then
                requestId = req.headers[requestIdHeader]
            elseif crypto and crypto.uuid then
                requestId = crypto.uuid()
            end
        end

        -- Build child context
        local childContext = {
            method = req.method,
            path = req.path,
        }
        if requestId then
            childContext.requestId = requestId
        end

        -- Custom context props
        if customProps then
            local ok, extra = pcall(customProps, req)
            if ok and extra then
                for k, v in pairs(extra) do
                    childContext[k] = v
                end
            end
        end

        -- Create child logger and attach to request
        req.log = logger:child(childContext)

        -- Auto-log request completion
        if autoLog then
            local startTime
            if time and time.monotonic_ms then
                startTime = time.monotonic_ms()
            else
                startTime = os.clock() * 1000
            end

            local originalSend = res.send

            res.send = function(self, body)
                local duration
                if time and time.monotonic_ms then
                    duration = time.monotonic_ms() - startTime
                else
                    duration = (os.clock() * 1000) - startTime
                end

                local status = self._status or 200

                -- Escalate level based on status code
                local logLevel = completionLevel
                if status >= 500 then
                    logLevel = "error"
                elseif status >= 400 then
                    logLevel = "warn"
                end

                req.log[logLevel](req.log, "request completed", {
                    status = status,
                    duration = math.floor(duration * 100) / 100, -- 2 decimal places
                    contentLength = body and #body or 0,
                })

                return originalSend(self, body)
            end
        end

        next()
    end
end

return honeymoon
