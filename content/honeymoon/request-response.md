# Request & Response

Every route handler receives a `req` (request) and `res` (response) object. These objects provide methods and properties for reading incoming data and sending responses.

## Request Object

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `req.method` | string | HTTP method (`"GET"`, `"POST"`, etc.) |
| `req.path` | string | Request path (`"/api/users/42"`) |
| `req.headers` | table | Request headers (lowercase keys) |
| `req.query` | table | Query parameters (`?key=value`) |
| `req.params` | table | Route parameters (`:id`, `*`) |
| `req.body` | string | Raw request body |
| `req.ip` | string | Client IP (respects X-Forwarded-For) |
| `req.protocol` | string | `"http"` or `"https"` (respects X-Forwarded-Proto) |
| `req.hostname` | string | Host header value |
| `req.secure` | boolean | `true` if HTTPS |
| `req.xhr` | boolean | `true` if XMLHttpRequest |
| `req.baseUrl` | string | Base URL for mounted routers |
| `req.session` | table | Session object (requires session middleware) |
| `req.sessionID` | string | Session ID (requires session middleware) |
| `req.user` | table | Authenticated user (requires auth middleware) |
| `req.id` | string | Request ID (requires requestId middleware) |

### Header Methods

#### req:get(name)

Get a header value (case-insensitive):

```lua
local contentType = req:get("Content-Type")
local auth = req:get("authorization")
```

#### req:has(name)

Check if a header exists:

```lua
if req:has("Authorization") then
    -- Header is present
end
```

### Body Parsing

#### req:json()

Parse the request body as JSON:

```lua
app:post("/api/users", function(req, res)
    local data = req:json()
    print(data.name, data.email)
end)
```

#### req:form()

Parse the request body as URL-encoded form data:

```lua
app:post("/login", function(req, res)
    local data = req:form()
    print(data.username, data.password)
end)
```

### Parameter Access

#### req:param(name, default?)

Search for a parameter across route params, query string, and body (in that order):

```lua
app:get("/users/:id", function(req, res)
    -- Checks req.params.id, then req.query.id, then body
    local id = req:param("id")
    local format = req:param("format", "json")  -- With default
end)
```

### Content Negotiation

#### req:accepts(types)

Check what content types the client accepts (from the `Accept` header):

```lua
local type = req:accepts("json")          -- Returns "json" or nil
local type = req:accepts({"html", "json"}) -- Returns best match or nil
```

Supported short forms: `"json"`, `"html"`, `"text"`, `"xml"`.

#### req:is(types)

Check the request's Content-Type:

```lua
if req:is("json") then
    local data = req:json()
end
```

### Validation

#### req:validate(schema)

Validate the request body against a schema. Throws a `ValidationError` on failure:

```lua
local schema = honeymoon.schema({
    name = { type = "string", required = true, min = 2 },
    email = { type = "email", required = true },
})

app:post("/api/users", function(req, res)
    local data = req:validate(schema)
    -- data is sanitized and valid
    res:status(201):json({ user = data })
end)
```

#### req:validateQuery(schema)

Validate query parameters:

```lua
local querySchema = honeymoon.schema({
    page = { type = "integer", default = 1, minValue = 1 },
    limit = { type = "integer", default = 25, minValue = 1, maxValue = 100 },
})

app:get("/api/users", function(req, res)
    local query = req:validateQuery(querySchema)
    res:json({ page = query.page, limit = query.limit })
end)
```

#### req:validateParams(schema)

Validate route parameters:

```lua
local paramsSchema = honeymoon.schema({
    id = { type = "integer", required = true, minValue = 1 },
})

app:get("/api/users/:id", function(req, res)
    local params = req:validateParams(paramsSchema)
    local user = User:find(params.id)
end)
```

See [Validation](/docs/honeymoon/validation) for schema definition details.

### Cookies

#### req:cookies()

Get all cookies as a table:

```lua
local cookies = req:cookies()
print(cookies.theme, cookies.lang)
```

#### req:cookie(name)

Get a single cookie value:

```lua
local theme = req:cookie("theme")
```

### Utility Methods

#### req:originalUrl()

Get the full URL including query string:

```lua
print(req:originalUrl())  -- "/users?page=2&sort=name"
```

#### req:fresh() / req:stale()

Check conditional request headers (If-None-Match, If-Modified-Since):

```lua
if req:fresh() then
    res:status(304):send("")  -- Not Modified
end
```

#### req:range(size)

Parse the Range header for partial content requests:

```lua
local ranges = req:range(fileSize)
if ranges then
    local range = ranges[1]
    print(range.start, range["end"])
end
```

---

## Response Object

### Status

#### res:status(code)

Set the HTTP status code (chainable):

```lua
res:status(201):json({ created = true })
res:status(404):send("Not Found")
```

#### res:getStatus()

Get the current status code:

```lua
local code = res:getStatus()
```

### Headers

#### res:set(name, value)

Set a response header:

```lua
res:set("X-Custom", "value")
```

#### res:get(name)

Get a response header value:

```lua
local value = res:get("Content-Type")
```

#### res:append(name, value)

Append a value to an existing header:

```lua
res:append("Set-Cookie", "theme=dark")
```

#### res:remove(name)

Remove a header:

```lua
res:remove("X-Powered-By")
```

#### res:headers(table)

Set multiple headers at once:

```lua
res:headers({
    ["X-Custom"] = "value",
    ["X-Request-Id"] = "abc123",
})
```

### Content Type

#### res:type(contentType)

Set the Content-Type header with shorthand support:

```lua
res:type("json")   -- application/json
res:type("html")   -- text/html; charset=utf-8
res:type("text")   -- text/plain; charset=utf-8
res:type("xml")    -- application/xml
res:type("application/pdf")  -- Exact value
```

### Sending Responses

#### res:send(body)

Send a response body:

```lua
res:send("Hello World")
res:send("<h1>Page</h1>")
```

#### res:json(data)

Send a JSON response:

```lua
res:json({ users = users, total = #users })
res:status(201):json({ id = user.id })
```

#### res:html(content)

Send HTML:

```lua
res:html("<h1>Hello</h1>")
```

#### res:text(content)

Send plain text:

```lua
res:text("Plain text response")
```

#### res:xml(content)

Send XML:

```lua
res:xml("<user><name>Alice</name></user>")
```

#### res:sent()

Check if a response has already been sent:

```lua
if not res:sent() then
    res:json({ fallback = true })
end
```

### Rendering Templates

#### res:render(name, data)

Render a template with the configured view engine:

```lua
res:render("users/index", {
    title = "Users",
    users = users,
})
```

Template data is merged with `res.locals`:

```lua
res.locals.currentUser = user
res.locals.year = os.date("%Y")
res:render("dashboard")  -- Template has access to currentUser and year
```

### Redirects

#### res:redirect(url, status?)

Redirect to a URL:

```lua
res:redirect("/login")           -- 302 Found
res:redirect("/new-page", 301)   -- 301 Moved Permanently
```

#### res:back(fallback?)

Redirect to the referrer, or a fallback URL:

```lua
res:back("/")  -- Go back, or home if no referrer
```

### File Responses

#### res:sendFile(filepath)

Send a file with the appropriate Content-Type:

```lua
res:sendFile("./uploads/report.pdf")
```

#### res:download(filepath, filename?)

Send a file as an attachment download:

```lua
res:download("./data/export.csv", "users-export.csv")
```

#### res:inline(filepath, filename?)

Send a file for inline display (e.g., in the browser):

```lua
res:inline("./uploads/photo.jpg")
```

### Cookies

#### res:cookie(name, value, options?)

Set a cookie:

```lua
res:cookie("theme", "dark", {
    maxAge = 86400 * 30,   -- 30 days in seconds
    path = "/",
    httpOnly = true,
    secure = true,
    sameSite = "Lax",
})
```

| Option | Default | Description |
|--------|---------|-------------|
| `maxAge` | `nil` | Lifetime in seconds |
| `expires` | `nil` | Expiration timestamp or string |
| `path` | `"/"` | Cookie path |
| `domain` | `nil` | Cookie domain |
| `secure` | `false` | HTTPS only |
| `httpOnly` | `true` | No JavaScript access |
| `sameSite` | `"Lax"` | `"Strict"`, `"Lax"`, or `"None"` |

#### res:clearCookie(name, options?)

Delete a cookie:

```lua
res:clearCookie("theme")
```

### Content Negotiation

#### res:format(handlers)

Respond based on the client's `Accept` header:

```lua
res:format({
    ["application/json"] = function()
        res:json({ user = user })
    end,
    ["text/html"] = function()
        res:render("user", { user = user })
    end,
    default = function()
        res:text(user.name)
    end,
})
```

### Cache Control

#### res:cache(options)

Set the Cache-Control header:

```lua
res:cache("public, max-age=3600")

res:cache({
    public = true,
    maxAge = 3600,
    sMaxAge = 7200,
    mustRevalidate = true,
    immutable = false,
})
```

#### res:noCache()

Disable caching:

```lua
res:noCache()
-- Sets: no-store, no-cache, must-revalidate, proxy-revalidate
```

#### res:etag(tag, weak?)

Set the ETag header:

```lua
res:etag("abc123")
res:etag("abc123", true)  -- Weak ETag: W/"abc123"
```

#### res:lastModified(timestamp)

Set the Last-Modified header:

```lua
res:lastModified(os.time())
```

#### res:vary(field)

Add to the Vary header:

```lua
res:vary("Accept")
res:vary("Accept-Encoding")
```

### Link Header

#### res:links(links)

Set the Link header (useful for pagination):

```lua
res:links({
    next = "/api/users?page=3",
    prev = "/api/users?page=1",
    last = "/api/users?page=10",
})
```

### Error Responses

#### res:error(status, message, code?)

Send a JSON error response:

```lua
res:error(404, "User not found", "USER_NOT_FOUND")
```

Produces:

```json
{
    "error": {
        "status": 404,
        "message": "User not found",
        "code": "USER_NOT_FOUND"
    }
}
```

#### res:validationError(errors)

Send a 422 response with validation errors:

```lua
res:validationError({
    email = { "must be a valid email address" },
    name = { "is required" },
})
```

#### res:errorPage(status, message, stack?)

Render an HTML error page. In development mode, includes the stack trace:

```lua
res:errorPage(500, "Internal Server Error", debug.traceback())
```

See [Error Handling](/docs/honeymoon/error-handling) for more details.
