-- Vein Filters Tests
-- Tests for built-in filter functions

local Assay = require("assay")
local filters = require("vein.lib.filters")

Assay.global()

--------------------------------------------------------------------------------
-- Escape Filters
--------------------------------------------------------------------------------

describe("Escape Filters", function()
    describe("escape()", function()
        it("should escape HTML special characters", function()
            expect(filters.escape("<script>alert('xss')</script>"))
                :toBe("&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;")
        end)

        it("should escape ampersands", function()
            expect(filters.escape("foo & bar")):toBe("foo &amp; bar")
        end)

        it("should escape double quotes", function()
            expect(filters.escape('say "hello"')):toBe('say &quot;hello&quot;')
        end)

        it("should handle nil values", function()
            expect(filters.escape(nil)):toBe("")
        end)

        it("should convert numbers to strings", function()
            expect(filters.escape(42)):toBe("42")
        end)
    end)

    describe("url()", function()
        it("should URL encode special characters", function()
            expect(filters.url("hello world")):toBe("hello%20world")
        end)

        it("should encode special chars", function()
            expect(filters.url("foo=bar&baz=qux")):toBe("foo%3Dbar%26baz%3Dqux")
        end)

        it("should preserve safe characters", function()
            expect(filters.url("hello-world_123")):toBe("hello-world_123")
        end)

        it("should handle nil", function()
            expect(filters.url(nil)):toBe("")
        end)
    end)

    describe("urldecode()", function()
        it("should decode URL encoded strings", function()
            expect(filters.urldecode("hello%20world")):toBe("hello world")
        end)

        it("should convert + to space", function()
            expect(filters.urldecode("hello+world")):toBe("hello world")
        end)
    end)

    describe("json()", function()
        it("should encode strings", function()
            expect(filters.json("hello")):toBe('"hello"')
        end)

        it("should encode numbers", function()
            expect(filters.json(42)):toBe("42")
        end)

        it("should encode booleans", function()
            expect(filters.json(true)):toBe("true")
            expect(filters.json(false)):toBe("false")
        end)

        it("should encode nil as null", function()
            expect(filters.json(nil)):toBe("null")
        end)

        it("should encode arrays", function()
            expect(filters.json({1, 2, 3})):toBe("[1,2,3]")
        end)

        it("should encode objects", function()
            local result = filters.json({a = 1})
            expect(result):toContain('"a":1')
        end)
    end)
end)

--------------------------------------------------------------------------------
-- String Transformations
--------------------------------------------------------------------------------

describe("String Transformations", function()
    describe("upper()", function()
        it("should convert to uppercase", function()
            expect(filters.upper("hello")):toBe("HELLO")
        end)

        it("should handle nil", function()
            expect(filters.upper(nil)):toBe("")
        end)
    end)

    describe("lower()", function()
        it("should convert to lowercase", function()
            expect(filters.lower("HELLO")):toBe("hello")
        end)

        it("should handle mixed case", function()
            expect(filters.lower("HeLLo WoRLD")):toBe("hello world")
        end)
    end)

    describe("capitalize()", function()
        it("should capitalize first letter", function()
            expect(filters.capitalize("hello")):toBe("Hello")
        end)

        it("should lowercase rest", function()
            expect(filters.capitalize("hELLO")):toBe("Hello")
        end)
    end)

    describe("title()", function()
        it("should title case each word", function()
            expect(filters.title("hello world")):toBe("Hello World")
        end)

        it("should handle mixed case input", function()
            expect(filters.title("hELLO wORLD")):toBe("Hello World")
        end)
    end)

    describe("trim()", function()
        it("should trim whitespace", function()
            expect(filters.trim("  hello  ")):toBe("hello")
        end)

        it("should handle only whitespace", function()
            expect(filters.trim("   ")):toBe("")
        end)
    end)

    describe("striptags()", function()
        it("should remove HTML tags", function()
            expect(filters.striptags("<p>Hello <b>World</b></p>")):toBe("Hello World")
        end)

        it("should handle self-closing tags", function()
            expect(filters.striptags("Hello<br/>World")):toBe("HelloWorld")
        end)
    end)

    describe("nl2br()", function()
        it("should convert newlines to br tags", function()
            expect(filters.nl2br("Hello\nWorld")):toBe("Hello<br>\nWorld")
        end)
    end)

    describe("truncate()", function()
        it("should truncate long strings", function()
            expect(filters.truncate("Hello World", 8)):toBe("Hello...")
        end)

        it("should not truncate short strings", function()
            expect(filters.truncate("Hello", 10)):toBe("Hello")
        end)

        it("should use custom suffix", function()
            -- Note: "…" is 3 bytes in UTF-8, so 8 - 3 = 5 bytes for text
            expect(filters.truncate("Hello World", 8, "…")):toBe("Hello…")
        end)
    end)

    describe("truncatewords()", function()
        it("should truncate by word count", function()
            expect(filters.truncatewords("one two three four five", 3)):toBe("one two three...")
        end)

        it("should not truncate if enough words", function()
            expect(filters.truncatewords("one two", 5)):toBe("one two")
        end)
    end)

    describe("padleft()", function()
        it("should pad left with spaces", function()
            expect(filters.padleft("5", 3)):toBe("  5")
        end)

        it("should pad with custom char", function()
            expect(filters.padleft("5", 3, "0")):toBe("005")
        end)
    end)

    describe("padright()", function()
        it("should pad right with spaces", function()
            expect(filters.padright("5", 3)):toBe("5  ")
        end)
    end)

    describe("center()", function()
        it("should center string", function()
            expect(filters.center("Hi", 6)):toBe("  Hi  ")
        end)
    end)

    describe("replace()", function()
        it("should replace substrings", function()
            expect(filters.replace("hello world", "world", "lua")):toBe("hello lua")
        end)
    end)

    describe("split()", function()
        it("should split by delimiter", function()
            local result = filters.split("a,b,c", ",")
            expect(#result):toBe(3)
            expect(result[1]):toBe("a")
            expect(result[2]):toBe("b")
            expect(result[3]):toBe("c")
        end)
    end)

    describe("reverse()", function()
        it("should reverse string", function()
            expect(filters.reverse("hello")):toBe("olleh")
        end)
    end)

    describe("slug()", function()
        it("should create URL slug", function()
            expect(filters.slug("Hello World!")):toBe("hello-world")
        end)

        it("should handle multiple spaces", function()
            expect(filters.slug("Hello   World")):toBe("hello-world")
        end)

        it("should remove special characters", function()
            expect(filters.slug("Hello@#$World")):toBe("helloworld")
        end)
    end)
end)

--------------------------------------------------------------------------------
-- Number Formatting
--------------------------------------------------------------------------------

describe("Number Formatting", function()
    describe("number()", function()
        it("should format with thousands separator", function()
            expect(filters.number(1234567)):toBe("1,234,567")
        end)

        it("should handle decimals", function()
            expect(filters.number(1234.567, 2)):toBe("1,234.57")
        end)

        it("should handle nil", function()
            expect(filters.number(nil)):toBe("0")
        end)
    end)

    describe("currency()", function()
        it("should format as currency", function()
            expect(filters.currency(1234.5)):toBe("$1,234.50")
        end)

        it("should use custom symbol", function()
            expect(filters.currency(1234.5, "€")):toBe("€1,234.50")
        end)
    end)

    describe("percent()", function()
        it("should format as percentage", function()
            expect(filters.percent(0.5)):toBe("50%")
        end)

        it("should handle decimals", function()
            expect(filters.percent(0.123, 1)):toBe("12.3%")
        end)
    end)

    describe("bytes()", function()
        it("should format bytes", function()
            expect(filters.bytes(1024)):toBe("1.00 KB")
        end)

        it("should format megabytes", function()
            expect(filters.bytes(1048576)):toBe("1.00 MB")
        end)

        it("should format large sizes", function()
            expect(filters.bytes(1073741824)):toBe("1.00 GB")
        end)
    end)

    describe("round()", function()
        it("should round numbers", function()
            expect(filters.round(3.7)):toBe(4)
            expect(filters.round(3.2)):toBe(3)
        end)

        it("should round to decimals", function()
            expect(filters.round(3.456, 2)):toBe(3.46)
        end)
    end)

    describe("floor()", function()
        it("should floor numbers", function()
            expect(filters.floor(3.9)):toBe(3)
        end)
    end)

    describe("ceil()", function()
        it("should ceil numbers", function()
            expect(filters.ceil(3.1)):toBe(4)
        end)
    end)

    describe("abs()", function()
        it("should return absolute value", function()
            expect(filters.abs(-5)):toBe(5)
            expect(filters.abs(5)):toBe(5)
        end)
    end)
end)

--------------------------------------------------------------------------------
-- Date/Time Formatting
--------------------------------------------------------------------------------

describe("Date/Time Formatting", function()
    describe("date()", function()
        it("should format timestamps", function()
            local result = filters.date(0, "%Y")
            expect(result):toBeString()
        end)

        it("should handle nil", function()
            expect(filters.date(nil)):toBe("")
        end)
    end)

    describe("timeago()", function()
        it("should return 'just now' for recent times", function()
            expect(filters.timeago(os.time())):toBe("just now")
        end)

        it("should handle nil", function()
            expect(filters.timeago(nil)):toBeString()
        end)
    end)
end)

--------------------------------------------------------------------------------
-- Array/Table Filters
--------------------------------------------------------------------------------

describe("Array/Table Filters", function()
    describe("length()", function()
        it("should return array length", function()
            expect(filters.length({1, 2, 3})):toBe(3)
        end)

        it("should return string length", function()
            expect(filters.length("hello")):toBe(5)
        end)

        it("should count table keys", function()
            expect(filters.length({a = 1, b = 2})):toBe(2)
        end)

        it("should return 0 for nil", function()
            expect(filters.length(nil)):toBe(0)
        end)
    end)

    describe("first()", function()
        it("should return first element", function()
            expect(filters.first({10, 20, 30})):toBe(10)
        end)

        it("should return nil for empty array", function()
            expect(filters.first({})):toBeNil()
        end)
    end)

    describe("last()", function()
        it("should return last element", function()
            expect(filters.last({10, 20, 30})):toBe(30)
        end)
    end)

    describe("join()", function()
        it("should join array elements", function()
            expect(filters.join({"a", "b", "c"}, "-")):toBe("a-b-c")
        end)

        it("should use default separator", function()
            expect(filters.join({"a", "b"})):toBe("a, b")
        end)
    end)

    describe("sort()", function()
        it("should sort array", function()
            local result = filters.sort({3, 1, 2})
            expect(result[1]):toBe(1)
            expect(result[2]):toBe(2)
            expect(result[3]):toBe(3)
        end)

        it("should sort by key", function()
            local items = {
                {name = "Charlie"},
                {name = "Alice"},
                {name = "Bob"}
            }
            local sorted = filters.sort(items, "name")
            expect(sorted[1].name):toBe("Alice")
            expect(sorted[2].name):toBe("Bob")
            expect(sorted[3].name):toBe("Charlie")
        end)
    end)

    describe("keys()", function()
        it("should return table keys", function()
            local result = filters.keys({a = 1, b = 2})
            expect(#result):toBe(2)
            expect(result):toContain("a")
            expect(result):toContain("b")
        end)
    end)

    describe("values()", function()
        it("should return table values", function()
            local result = filters.values({a = 1, b = 2})
            expect(#result):toBe(2)
            expect(result):toContain(1)
            expect(result):toContain(2)
        end)
    end)

    describe("slice()", function()
        it("should slice array", function()
            local result = filters.slice({1, 2, 3, 4, 5}, 2, 4)
            expect(#result):toBe(3)
            expect(result[1]):toBe(2)
            expect(result[3]):toBe(4)
        end)
    end)

    describe("pluck()", function()
        it("should extract key from array of tables", function()
            local items = {
                {name = "Alice", age = 30},
                {name = "Bob", age = 25}
            }
            local names = filters.pluck(items, "name")
            expect(names[1]):toBe("Alice")
            expect(names[2]):toBe("Bob")
        end)
    end)

    describe("groupby()", function()
        it("should group by key", function()
            local items = {
                {category = "A", name = "Item1"},
                {category = "B", name = "Item2"},
                {category = "A", name = "Item3"}
            }
            local grouped = filters.groupby(items, "category")
            expect(#grouped.A):toBe(2)
            expect(#grouped.B):toBe(1)
        end)
    end)
end)

--------------------------------------------------------------------------------
-- Conditional Filters
--------------------------------------------------------------------------------

describe("Conditional Filters", function()
    describe("default()", function()
        it("should return value if not nil", function()
            expect(filters.default("hello", "default")):toBe("hello")
        end)

        it("should return default if nil", function()
            expect(filters.default(nil, "default")):toBe("default")
        end)

        it("should return default if empty string", function()
            expect(filters.default("", "default")):toBe("default")
        end)
    end)

    describe("ternary()", function()
        it("should return trueValue if truthy", function()
            expect(filters.ternary(true, "yes", "no")):toBe("yes")
        end)

        it("should return falseValue if falsy", function()
            expect(filters.ternary(false, "yes", "no")):toBe("no")
        end)
    end)
end)

--------------------------------------------------------------------------------
-- Debug Filters
--------------------------------------------------------------------------------

describe("Debug Filters", function()
    describe("typeof()", function()
        it("should return type of value", function()
            expect(filters.typeof("hello")):toBe("string")
            expect(filters.typeof(42)):toBe("number")
            expect(filters.typeof({})):toBe("table")
            expect(filters.typeof(nil)):toBe("nil")
        end)
    end)

    describe("dump()", function()
        it("should dump value as HTML", function()
            local result = filters.dump({a = 1})
            expect(result):toContain("<pre>")
            expect(result):toContain("</pre>")
        end)
    end)
end)

--------------------------------------------------------------------------------
-- defaults() function
--------------------------------------------------------------------------------

describe("defaults()", function()
    it("should return all filter functions", function()
        local defaults = filters.defaults()
        expect(defaults.escape):toBeFunction()
        expect(defaults.upper):toBeFunction()
        expect(defaults.lower):toBeFunction()
        expect(defaults.truncate):toBeFunction()
    end)

    it("should not include defaults function itself", function()
        local defaults = filters.defaults()
        expect(defaults.defaults):toBeNil()
    end)
end)

return Assay.run()
