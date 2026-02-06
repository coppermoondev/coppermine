-- HoneyMoon Static Middleware
-- Serve static files from a directory

local utils = require("honeymoon.lib.utils")

local static = {}

--- Default options
local defaults = {
    index = "index.html",
    dotfiles = "ignore",     -- ignore, allow, deny
    etag = true,
    maxAge = 0,
    immutable = false,
    lastModified = true,
    redirect = true,         -- Redirect directories to trailing slash
    extensions = nil,        -- Try these extensions if file not found
}

--- Create static file serving middleware
---@param root string Root directory path
---@param options table|nil Static options
---@return function Middleware function
function static.create(root, options)
    options = options or {}

    -- Merge with defaults
    local config = {}
    for k, v in pairs(defaults) do
        config[k] = options[k] ~= nil and options[k] or v
    end

    -- Normalize root path
    root = root:gsub("[/\\]+$", "")

    return function(req, res, next)
        -- Only handle GET and HEAD
        if req.method ~= "GET" and req.method ~= "HEAD" then
            return next()
        end

        -- Get requested path and strip baseUrl prefix
        local path = req.path
        local baseUrl = req.baseUrl or ""

        -- Strip mount path prefix (e.g., /public/css/style.css -> /css/style.css)
        if #baseUrl > 0 and path:sub(1, #baseUrl) == baseUrl then
            path = path:sub(#baseUrl + 1)
        end

        -- Ensure path starts with /
        if path == "" or path:sub(1, 1) ~= "/" then
            path = "/" .. path
        end

        -- Decode URL
        path = utils.url_decode(path)

        -- Security: prevent directory traversal
        if not utils.is_safe_path(path) then
            return next()
        end

        -- Handle dotfiles
        local filename = path:match("([^/]+)$") or ""
        if filename:sub(1, 1) == "." then
            if config.dotfiles == "ignore" then
                return next()
            elseif config.dotfiles == "deny" then
                return res:status(403):send("Forbidden")
            end
        end

        -- Build file path
        local filepath = root .. path

        -- Check if path is a directory
        local is_dir = fs.is_dir(filepath)

        if is_dir then
            -- Redirect to trailing slash if needed
            if config.redirect and not path:match("/$") then
                return res:redirect(path .. "/", 301)
            end

            -- Try index file
            if config.index then
                filepath = filepath .. "/" .. config.index
                if not fs.exists(filepath) then
                    return next()
                end
            else
                return next()
            end
        end

        -- Try extensions if file doesn't exist
        if not fs.exists(filepath) and config.extensions then
            for _, ext in ipairs(config.extensions) do
                local try_path = filepath .. "." .. ext
                if fs.exists(try_path) then
                    filepath = try_path
                    break
                end
            end
        end

        -- Check if file exists
        if not fs.exists(filepath) or fs.is_dir(filepath) then
            return next()
        end

        -- Get file info
        local stat_ok, stat = pcall(fs.stat, filepath)
        if not stat_ok then
            return next()
        end

        -- Get content type
        local ext = utils.get_extension(filepath)
        local content_type = utils.get_mime_type(ext)
        res:type(content_type)

        -- Set Cache-Control
        if config.maxAge > 0 then
            local cache_control = "public, max-age=" .. config.maxAge
            if config.immutable then
                cache_control = cache_control .. ", immutable"
            end
            res:set("Cache-Control", cache_control)
        end

        -- Set Last-Modified
        if config.lastModified and stat and stat.mtime then
            res:set("Last-Modified", os.date("!%a, %d %b %Y %H:%M:%S GMT", stat.mtime))

            -- Check If-Modified-Since
            local ims = req:get("if-modified-since")
            if ims then
                -- Simple comparison (not parsing date)
                local last_mod = os.date("!%a, %d %b %Y %H:%M:%S GMT", stat.mtime)
                if ims == last_mod then
                    return res:status(304):send("")
                end
            end
        end

        -- Generate ETag
        if config.etag and stat then
            local etag_value = string.format('"%x-%x"', stat.size or 0, stat.mtime or 0)
            res:set("ETag", etag_value)

            -- Check If-None-Match
            local inm = req:get("if-none-match")
            if inm and inm == etag_value then
                return res:status(304):send("")
            end
        end

        -- Set Accept-Ranges
        res:set("Accept-Ranges", "bytes")

        -- Handle Range requests
        local range_header = req:get("range")
        if range_header and stat and stat.size then
            local ranges = req:range(stat.size)
            if ranges and #ranges == 1 then
                -- Single range
                local range = ranges[1]

                -- Read file content
                local ok, content = pcall(fs.read, filepath)
                if not ok then
                    return next()
                end

                local partial = content:sub(range.start + 1, range["end"] + 1)

                res:status(206)
                res:set("Content-Range",
                    string.format("bytes %d-%d/%d", range.start, range["end"], stat.size))
                return res:send(partial)
            elseif ranges == nil then
                -- Invalid range
                res:set("Content-Range", "bytes */" .. stat.size)
                return res:status(416):send("Range Not Satisfiable")
            end
        end

        -- Read and send file
        local ok, content = pcall(fs.read, filepath)
        if not ok then
            return next()
        end

        -- HEAD request: don't send body
        if req.method == "HEAD" then
            res:set("Content-Length", tostring(#content))
            return res:send("")
        end

        res:send(content)
    end
end

--- Create static file server with directory listing
---@param root string Root directory
---@param options table|nil Options
---@return function
function static.directory(root, options)
    options = options or {}
    local show_hidden = options.hidden or false

    local base_static = static.create(root, options)

    return function(req, res, next)
        -- Try static file first
        local path = root .. req.path

        if fs.is_dir(path) then
            -- Generate directory listing
            local entries = {}
            local ok, files = pcall(fs.list, path)

            if ok and files then
                for _, file in ipairs(files) do
                    if show_hidden or file:sub(1, 1) ~= "." then
                        local full_path = path .. "/" .. file
                        local is_dir = fs.is_dir(full_path)
                        table.insert(entries, {
                            name = file .. (is_dir and "/" or ""),
                            isDir = is_dir
                        })
                    end
                end
            end

            -- Sort: directories first, then alphabetically
            table.sort(entries, function(a, b)
                if a.isDir ~= b.isDir then
                    return a.isDir
                end
                return a.name < b.name
            end)

            -- Generate HTML
            local html = string.format([[
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Index of %s</title>
    <style>
        body { font-family: system-ui, sans-serif; margin: 40px; background: #f5f5f5; }
        h1 { color: #333; border-bottom: 1px solid #ddd; padding-bottom: 10px; }
        ul { list-style: none; padding: 0; }
        li { padding: 8px 0; border-bottom: 1px solid #eee; }
        a { color: #0066cc; text-decoration: none; }
        a:hover { text-decoration: underline; }
        .dir { font-weight: bold; }
        .dir::before { content: "📁 "; }
        .file::before { content: "📄 "; }
    </style>
</head>
<body>
    <h1>Index of %s</h1>
    <ul>
]], req.path, req.path)

            -- Add parent directory link
            if req.path ~= "/" then
                html = html .. '<li><a href="../">../</a></li>\n'
            end

            for _, entry in ipairs(entries) do
                local class = entry.isDir and "dir" or "file"
                html = html .. string.format(
                    '<li><a href="%s" class="%s">%s</a></li>\n',
                    entry.name, class, entry.name
                )
            end

            html = html .. "</ul></body></html>"

            return res:html(html)
        end

        -- Fall back to static file serving
        base_static(req, res, next)
    end
end

return static
