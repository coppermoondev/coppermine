-- Vein Engine Tests
-- Tests for the main Vein engine API

local Assay = require("assay")
local vein = require("vein")

Assay.global()

--------------------------------------------------------------------------------
-- Engine Creation
--------------------------------------------------------------------------------

describe("Engine Creation", function()
    describe("vein.new()", function()
        it("should create a new engine instance", function()
            local engine = vein.new()
            expect(engine):toBeTable()
        end)

        it("should accept options", function()
            local engine = vein.new({
                views = "./templates",
                cache = false,
                debug = true
            })
            expect(engine.options.views):toBe("./templates")
            expect(engine.options.cache):toBe(false)
            expect(engine.options.debug):toBe(true)
        end)

        it("should have default options", function()
            local engine = vein.new()
            expect(engine.options.extension):toBe(".vein")
            expect(engine.options.cache):toBe(true)
            expect(engine.options.autoEscape):toBe(true)
        end)

        it("should initialize filters", function()
            local engine = vein.new()
            expect(engine.filters):toBeTable()
            expect(engine.filters.escape):toBeFunction()
            expect(engine.filters.upper):toBeFunction()
        end)
    end)
end)

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

describe("Configuration", function()
    describe("set()", function()
        it("should update configuration options", function()
            local engine = vein.new()
            engine:set("debug", true)
            expect(engine.options.debug):toBe(true)
        end)

        it("should update views path", function()
            local engine = vein.new()
            engine:set("views", "/new/path")
            expect(engine.options.views):toBe("/new/path")
        end)

        it("should return self for chaining", function()
            local engine = vein.new()
            local result = engine:set("debug", true)
            expect(result):toBe(engine)
        end)
    end)

    describe("global()", function()
        it("should add global variable", function()
            local engine = vein.new()
            engine:global("siteName", "My Site")
            expect(engine.options.globals.siteName):toBe("My Site")
        end)

        it("should add multiple globals from table", function()
            local engine = vein.new()
            engine:global({
                siteName = "My Site",
                version = "1.0"
            })
            expect(engine.options.globals.siteName):toBe("My Site")
            expect(engine.options.globals.version):toBe("1.0")
        end)

        it("should return self for chaining", function()
            local engine = vein.new()
            local result = engine:global("key", "value")
            expect(result):toBe(engine)
        end)
    end)
end)

--------------------------------------------------------------------------------
-- Custom Filters
--------------------------------------------------------------------------------

describe("Custom Filters", function()
    describe("filter()", function()
        it("should register a custom filter", function()
            local engine = vein.new()
            engine:filter("double", function(value)
                return value * 2
            end)
            expect(engine.filters.double):toBeFunction()
        end)

        it("should use custom filter in template", function()
            local engine = vein.new()
            engine:filter("exclaim", function(value)
                return value .. "!"
            end)
            local result = engine:renderString("{{ text | exclaim }}", { text = "Hello" })
            expect(result):toBe("Hello!")
        end)

        it("should return self for chaining", function()
            local engine = vein.new()
            local result = engine:filter("test", function() end)
            expect(result):toBe(engine)
        end)
    end)

    describe("adding multiple filters", function()
        it("should register multiple filters via direct assignment", function()
            local engine = vein.new()
            engine.filters.double = function(v) return v * 2 end
            engine.filters.triple = function(v) return v * 3 end
            expect(engine.filters.double):toBeFunction()
            expect(engine.filters.triple):toBeFunction()
        end)
    end)
end)

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

describe("Helpers", function()
    describe("helper()", function()
        it("should register a helper function", function()
            local engine = vein.new()
            engine:helper("formatDate", function(date)
                return os.date("%Y-%m-%d", date)
            end)
            expect(engine.helpers.formatDate):toBeFunction()
        end)

        it("should return self for chaining", function()
            local engine = vein.new()
            local result = engine:helper("test", function() end)
            expect(result):toBe(engine)
        end)
    end)
end)

--------------------------------------------------------------------------------
-- Components
--------------------------------------------------------------------------------

describe("Components", function()
    describe("component()", function()
        it("should register a component", function()
            local engine = vein.new()
            engine:component("card", "<div class='card'>{{ slot }}</div>")
            expect(engine.components.card):toBe("<div class='card'>{{ slot }}</div>")
        end)

        it("should return self for chaining", function()
            local engine = vein.new()
            local result = engine:component("test", "template")
            expect(result):toBe(engine)
        end)
    end)
end)

--------------------------------------------------------------------------------
-- String Rendering
--------------------------------------------------------------------------------

describe("String Rendering", function()
    describe("renderString()", function()
        it("should render plain text", function()
            local engine = vein.new()
            local result = engine:renderString("Hello World")
            expect(result):toBe("Hello World")
        end)

        it("should render expressions", function()
            local engine = vein.new()
            local result = engine:renderString("Hello {{ name }}", { name = "World" })
            expect(result):toBe("Hello World")
        end)

        it("should escape HTML by default", function()
            local engine = vein.new()
            local result = engine:renderString("{{ html }}", { html = "<script>" })
            expect(result):toBe("&lt;script&gt;")
        end)

        it("should render raw HTML", function()
            local engine = vein.new()
            local result = engine:renderString("{! html !}", { html = "<b>bold</b>" })
            expect(result):toBe("<b>bold</b>")
        end)

        it("should use globals", function()
            local engine = vein.new()
            engine:global("siteName", "My Site")
            local result = engine:renderString("Welcome to {{ siteName }}")
            expect(result):toBe("Welcome to My Site")
        end)

        it("should apply filters", function()
            local engine = vein.new()
            local result = engine:renderString("{{ name | upper }}", { name = "hello" })
            expect(result):toBe("HELLO")
        end)

        it("should chain filters", function()
            local engine = vein.new()
            local result = engine:renderString("{{ text | upper | trim }}", { text = "  hello  " })
            expect(result):toBe("HELLO")
        end)

        it("should handle filter arguments", function()
            local engine = vein.new()
            local result = engine:renderString("{{ text | truncate(5) }}", { text = "Hello World" })
            expect(result):toBe("He...")
        end)
    end)

    describe("Conditionals", function()
        it("should render if true", function()
            local engine = vein.new()
            local result = engine:renderString("{% if show then %}visible{% end %}", { show = true })
            expect(result):toBe("visible")
        end)

        it("should not render if false", function()
            local engine = vein.new()
            local result = engine:renderString("{% if show then %}visible{% end %}", { show = false })
            expect(result):toBe("")
        end)

        it("should render else branch", function()
            local engine = vein.new()
            local result = engine:renderString(
                "{% if show then %}yes{% else %}no{% end %}",
                { show = false }
            )
            expect(result):toBe("no")
        end)

        it("should render elseif branch", function()
            local engine = vein.new()
            local result = engine:renderString(
                "{% if a then %}A{% elseif b then %}B{% else %}C{% end %}",
                { a = false, b = true }
            )
            expect(result):toBe("B")
        end)

        it("should handle comparison operators", function()
            local engine = vein.new()
            local result = engine:renderString(
                "{% if count > 0 then %}has items{% end %}",
                { count = 5 }
            )
            expect(result):toBe("has items")
        end)

        it("should handle boolean operators", function()
            local engine = vein.new()
            local result = engine:renderString(
                "{% if a and b then %}both{% end %}",
                { a = true, b = true }
            )
            expect(result):toBe("both")
        end)
    end)

    describe("Loops", function()
        it("should render numeric for loop", function()
            local engine = vein.new()
            local result = engine:renderString("{% for i = 1, 3 do %}{{ i }}{% end %}")
            expect(result):toBe("123")
        end)

        it("should render for-in loop", function()
            local engine = vein.new()
            local result = engine:renderString(
                "{% for item in items do %}{{ item }},{% end %}",
                { items = {"a", "b", "c"} }
            )
            expect(result):toBe("a,b,c,")
        end)

        it("should access table properties in loop", function()
            local engine = vein.new()
            local result = engine:renderString(
                "{% for user in users do %}{{ user.name }},{% end %}",
                { users = {{ name = "Alice" }, { name = "Bob" }} }
            )
            expect(result):toBe("Alice,Bob,")
        end)

        it("should handle empty arrays", function()
            local engine = vein.new()
            local result = engine:renderString(
                "{% for item in items do %}{{ item }}{% end %}",
                { items = {} }
            )
            expect(result):toBe("")
        end)

        it("should handle loop with conditional", function()
            local engine = vein.new()
            local result = engine:renderString(
                "{% for n in nums do %}{% if n > 2 then %}{{ n }}{% end %}{% end %}",
                { nums = {1, 2, 3, 4} }
            )
            expect(result):toBe("34")
        end)
    end)

    describe("Variables", function()
        it("should handle set statement", function()
            local engine = vein.new()
            local result = engine:renderString("{% set x = 5 %}{{ x }}")
            expect(result):toBe("5")
        end)

        it("should handle arithmetic in set", function()
            local engine = vein.new()
            local result = engine:renderString("{% set sum = a + b %}{{ sum }}", { a = 2, b = 3 })
            expect(result):toBe("5")
        end)
    end)

    describe("Comments", function()
        it("should ignore comments", function()
            local engine = vein.new()
            local result = engine:renderString("Hello{# this is a comment #} World")
            expect(result):toBe("Hello World")
        end)

        it("should handle multiline comments", function()
            local engine = vein.new()
            local result = engine:renderString("A{# \nmultiline\ncomment\n#}B")
            expect(result):toBe("AB")
        end)
    end)

    describe("Table/Object Access", function()
        it("should access nested properties", function()
            local engine = vein.new()
            local result = engine:renderString(
                "{{ user.profile.name }}",
                { user = { profile = { name = "John" } } }
            )
            expect(result):toBe("John")
        end)

        it("should access array elements", function()
            local engine = vein.new()
            local result = engine:renderString(
                "{{ items[2] }}",
                { items = {"a", "b", "c"} }
            )
            expect(result):toBe("b")
        end)

        -- TODO: Implement safe nil access in compiler
        skip("should handle nil nested access gracefully", function()
            local engine = vein.new()
            local result = engine:renderString("{{ user.name }}", { user = nil })
            expect(result):toBe("")
        end)
    end)
end)

--------------------------------------------------------------------------------
-- Compile
--------------------------------------------------------------------------------

describe("Compilation", function()
    describe("compileString()", function()
        it("should return a function", function()
            local engine = vein.new()
            local fn = engine:compileString("Hello {{ name }}")
            expect(fn):toBeFunction()
        end)

        it("should compile template for reuse", function()
            local engine = vein.new()
            local fn = engine:compileString("Hello {{ name }}")

            -- Create a proper context
            local ctx = engine:_createContext({ name = "Alice" })
            local result1 = fn(ctx)

            local ctx2 = engine:_createContext({ name = "Bob" })
            local result2 = fn(ctx2)

            expect(result1):toBe("Hello Alice")
            expect(result2):toBe("Hello Bob")
        end)
    end)
end)

--------------------------------------------------------------------------------
-- Cache
--------------------------------------------------------------------------------

describe("Caching", function()
    describe("clearCache()", function()
        it("should clear compiled templates", function()
            local engine = vein.new()
            engine.compiled["test"] = function() return "cached" end

            expect(engine.compiled["test"]):toBeDefined()

            engine:clearCache()

            expect(engine.compiled["test"]):toBeNil()
        end)
    end)
end)

--------------------------------------------------------------------------------
-- Metrics
--------------------------------------------------------------------------------

describe("Metrics", function()
    describe("Metrics API", function()
        it("should not have metrics by default", function()
            local engine = vein.new()
            expect(engine:getMetrics()):toBeNil()
        end)

        it("should enable metrics when configured", function()
            local engine = vein.new({ metrics = true })
            expect(engine:getMetrics()):toBeDefined()
        end)

        it("should enable metrics with enableMetrics()", function()
            local engine = vein.new()
            engine:enableMetrics()
            expect(engine:getMetrics()):toBeDefined()
        end)

        it("should disable metrics with disableMetrics()", function()
            local engine = vein.new({ metrics = true })
            engine:disableMetrics()
            expect(engine.options.metrics):toBe(false)
        end)

        it("should reset metrics with resetMetrics()", function()
            local engine = vein.new({ metrics = true })
            engine:renderString("{{ x }}", { x = 1 })
            engine:resetMetrics()
            -- After reset, should still work
            expect(engine:getMetrics()):toBeDefined()
        end)
    end)
end)

--------------------------------------------------------------------------------
-- Debug
--------------------------------------------------------------------------------

describe("Debug", function()
    describe("getDebugInfo()", function()
        it("should return debug info for template", function()
            local engine = vein.new()
            local info = engine:getDebugInfo("test")
            expect(info.name):toBe("test")
            expect(info.cached):toBeBoolean()
        end)
    end)

    describe("getAllDebugInfo()", function()
        it("should return all debug info", function()
            local engine = vein.new()
            local info = engine:getAllDebugInfo()
            expect(info.options):toBeTable()
            expect(info.filters):toBeTable()
        end)
    end)
end)

--------------------------------------------------------------------------------
-- Quick Render
--------------------------------------------------------------------------------

describe("Quick Render", function()
    describe("vein.render()", function()
        it("should render template string directly", function()
            local result = vein.render("Hello {{ name }}", { name = "World" })
            expect(result):toBe("Hello World")
        end)

        it("should not cache", function()
            -- Multiple calls should work independently
            local r1 = vein.render("{{ x }}", { x = 1 })
            local r2 = vein.render("{{ x }}", { x = 2 })
            expect(r1):toBe("1")
            expect(r2):toBe("2")
        end)
    end)
end)

--------------------------------------------------------------------------------
-- Express Interface
--------------------------------------------------------------------------------

describe("Express Interface", function()
    describe("vein.express()", function()
        it("should return a function", function()
            local viewEngine = vein.express()
            expect(viewEngine):toBeFunction()
        end)
    end)
end)

--------------------------------------------------------------------------------
-- Error Handling
--------------------------------------------------------------------------------

describe("Error Handling", function()
    it("should throw on invalid template syntax", function()
        local engine = vein.new()
        expect(function()
            engine:renderString("{{ unclosed")
        end):toThrow()
    end)

    it("should handle runtime errors in debug mode", function()
        local engine = vein.new({ debug = true })
        expect(function()
            engine:renderString("{{ undefined_func() }}")
        end):toThrow()
    end)

    it("should handle runtime errors in production mode", function()
        local engine = vein.new({ debug = false })
        expect(function()
            engine:renderString("{{ undefined_func() }}")
        end):toThrow()
    end)
end)

return Assay.run()
