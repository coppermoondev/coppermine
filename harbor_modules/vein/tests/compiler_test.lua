-- Vein Compiler Tests
-- Tests for template compilation and tokenization

local Assay = require("assay")
local compiler = require("vein.lib.compiler")

Assay.global()

--------------------------------------------------------------------------------
-- Tokenization
--------------------------------------------------------------------------------

describe("Tokenizer", function()
    describe("Basic Tokenization", function()
        it("should tokenize plain text", function()
            local tokens = compiler.tokenize("Hello World")
            expect(#tokens):toBe(1)
            expect(tokens[1].type):toBe("TEXT")
            expect(tokens[1].value):toBe("Hello World")
        end)

        it("should tokenize output expressions", function()
            local tokens = compiler.tokenize("{{ name }}")
            expect(#tokens):toBe(1)
            expect(tokens[1].type):toBe("OUTPUT")
            expect(tokens[1].value):toBe("name")
        end)

        it("should tokenize raw output", function()
            local tokens = compiler.tokenize("{! html !}")
            expect(#tokens):toBe(1)
            expect(tokens[1].type):toBe("RAW")
            expect(tokens[1].value):toBe("html")
        end)

        it("should tokenize code blocks", function()
            local tokens = compiler.tokenize("{% if true then %}")
            expect(#tokens):toBe(1)
            expect(tokens[1].type):toBe("CODE")
            expect(tokens[1].value):toBe("if true then")
        end)

        it("should skip comments", function()
            local tokens = compiler.tokenize("{# this is a comment #}")
            expect(#tokens):toBe(0)
        end)

        it("should tokenize includes", function()
            local tokens = compiler.tokenize('{@ include "header" @}')
            expect(#tokens):toBe(1)
            expect(tokens[1].type):toBe("INCLUDE")
        end)

        it("should tokenize partials", function()
            local tokens = compiler.tokenize('{> "sidebar" >}')
            expect(#tokens):toBe(1)
            expect(tokens[1].type):toBe("PARTIAL")
        end)
    end)

    describe("Mixed Content", function()
        it("should tokenize text with expressions", function()
            local tokens = compiler.tokenize("Hello {{ name }}!")
            expect(#tokens):toBe(3)
            expect(tokens[1].type):toBe("TEXT")
            expect(tokens[1].value):toBe("Hello ")
            expect(tokens[2].type):toBe("OUTPUT")
            expect(tokens[2].value):toBe("name")
            expect(tokens[3].type):toBe("TEXT")
            expect(tokens[3].value):toBe("!")
        end)

        it("should handle multiple expressions", function()
            local tokens = compiler.tokenize("{{ a }} and {{ b }}")
            expect(#tokens):toBe(3)
            expect(tokens[1].type):toBe("OUTPUT")
            expect(tokens[2].type):toBe("TEXT")
            expect(tokens[3].type):toBe("OUTPUT")
        end)

        it("should handle adjacent tags", function()
            local tokens = compiler.tokenize("{{ a }}{{ b }}")
            expect(#tokens):toBe(2)
            expect(tokens[1].value):toBe("a")
            expect(tokens[2].value):toBe("b")
        end)
    end)

    describe("Edge Cases", function()
        it("should handle empty template", function()
            local tokens = compiler.tokenize("")
            expect(#tokens):toBe(0)
        end)

        it("should trim whitespace in expressions", function()
            local tokens = compiler.tokenize("{{   name   }}")
            expect(tokens[1].value):toBe("name")
        end)

        it("should preserve whitespace in text", function()
            local tokens = compiler.tokenize("  Hello  ")
            expect(tokens[1].value):toBe("  Hello  ")
        end)
    end)

    describe("Error Handling", function()
        it("should error on unclosed tag", function()
            expect(function()
                compiler.tokenize("{{ name")
            end):toThrow("Unclosed")
        end)
    end)
end)

--------------------------------------------------------------------------------
-- Code Generation
--------------------------------------------------------------------------------

describe("Code Generation", function()
    describe("generateCode()", function()
        it("should generate valid Lua code for text", function()
            local code = compiler.generateCode("Hello World")
            expect(code):toContain("return function")
            expect(code):toContain("Hello World")
        end)

        it("should generate code for output expressions", function()
            local code = compiler.generateCode("{{ name }}")
            expect(code):toContain("__write")
            expect(code):toContain("name")
        end)

        it("should escape output by default", function()
            local code = compiler.generateCode("{{ name }}")
            expect(code):toContain("escape")
        end)

        it("should not escape raw output", function()
            local code = compiler.generateCode("{! html !}")
            -- Raw should not have double escape
            expect(code):toContain("__write")
        end)

        it("should handle filters", function()
            local code = compiler.generateCode("{{ name | upper }}")
            expect(code):toContain("__filters.upper")
        end)

        it("should handle filters with arguments", function()
            local code = compiler.generateCode("{{ text | truncate(10) }}")
            expect(code):toContain("__filters.truncate")
            expect(code):toContain("10")
        end)

        it("should handle chained filters", function()
            local code = compiler.generateCode("{{ text | upper | trim }}")
            expect(code):toContain("__filters.upper")
            expect(code):toContain("__filters.trim")
        end)
    end)

    describe("Control Structures", function()
        it("should generate code for if statements", function()
            local code = compiler.generateCode("{% if x then %}yes{% end %}")
            expect(code):toContain("if x then")
            expect(code):toContain("end")
        end)

        it("should add 'then' to if without it", function()
            local code = compiler.generateCode("{% if x %}yes{% end %}")
            expect(code):toContain("if x then")
        end)

        it("should handle elseif", function()
            local code = compiler.generateCode("{% if x then %}a{% elseif y then %}b{% end %}")
            expect(code):toContain("elseif y then")
        end)

        it("should add 'then' to elseif without it", function()
            local code = compiler.generateCode("{% if x then %}a{% elseif y %}b{% end %}")
            expect(code):toContain("elseif y then")
        end)

        it("should handle else", function()
            local code = compiler.generateCode("{% if x then %}a{% else %}b{% end %}")
            expect(code):toContain("else")
        end)

        it("should handle for loops with do", function()
            local code = compiler.generateCode("{% for i = 1, 10 do %}{{ i }}{% end %}")
            expect(code):toContain("for i = 1, 10 do")
        end)

        it("should handle for-in loops", function()
            local code = compiler.generateCode("{% for item in items do %}{{ item }}{% end %}")
            expect(code):toContain("ipairs")
        end)

        it("should transform endif to end", function()
            local code = compiler.generateCode("{% if x then %}yes{% endif %}")
            expect(code):toContain("end")
        end)

        it("should transform endfor to end", function()
            local code = compiler.generateCode("{% for i = 1, 3 do %}x{% endfor %}")
            expect(code):toContain("end")
        end)
    end)

    describe("Template Inheritance", function()
        it("should handle extends", function()
            local code = compiler.generateCode('{% extends "base.vein" %}')
            expect(code):toContain("__ctx.__extends")
            expect(code):toContain("base.vein")
        end)

        it("should handle block definitions", function()
            local code = compiler.generateCode("{% block content %}Hello{% endblock %}")
            expect(code):toContain("__blocks")
            expect(code):toContain("content")
        end)
    end)

    describe("Includes", function()
        it("should generate include calls", function()
            local code = compiler.generateCode('{@ include "header.vein" @}')
            expect(code):toContain("include")
            expect(code):toContain("header.vein")
        end)
    end)

    describe("Variables", function()
        it("should handle set statement", function()
            local code = compiler.generateCode("{% set x = 5 %}")
            expect(code):toContain("local x = 5")
        end)
    end)
end)

--------------------------------------------------------------------------------
-- Compilation
--------------------------------------------------------------------------------

describe("Compilation", function()
    local mockEngine = {
        options = {
            autoEscape = true,
            delimiters = {
                output = { "{{", "}}" },
                raw = { "{!", "!}" },
                code = { "{%", "%}" },
                comment = { "{#", "#}" },
                include = { "{@", "@}" },
                partial = { "{>", ">}" },
            }
        }
    }

    describe("compile()", function()
        it("should return a function", function()
            local fn = compiler.compile("Hello", mockEngine)
            expect(fn):toBeFunction()
        end)

        it("should compile text templates", function()
            local fn = compiler.compile("Hello World", mockEngine)
            local ctx = { __filters = require("vein.lib.filters").defaults() }
            local result = fn(ctx)
            expect(result):toBe("Hello World")
        end)

        it("should compile expressions", function()
            local fn = compiler.compile("Hello {{ name }}", mockEngine)
            local ctx = {
                __filters = require("vein.lib.filters").defaults(),
                name = "World"
            }
            local result = fn(ctx)
            expect(result):toBe("Hello World")
        end)

        it("should apply auto-escape", function()
            local fn = compiler.compile("{{ html }}", mockEngine)
            local ctx = {
                __filters = require("vein.lib.filters").defaults(),
                html = "<script>"
            }
            local result = fn(ctx)
            expect(result):toBe("&lt;script&gt;")
        end)

        it("should not escape raw output", function()
            local fn = compiler.compile("{! html !}", mockEngine)
            local ctx = {
                __filters = require("vein.lib.filters").defaults(),
                html = "<b>bold</b>"
            }
            local result = fn(ctx)
            expect(result):toBe("<b>bold</b>")
        end)

        it("should apply filters", function()
            local fn = compiler.compile("{{ name | upper }}", mockEngine)
            local ctx = {
                __filters = require("vein.lib.filters").defaults(),
                name = "hello"
            }
            local result = fn(ctx)
            expect(result):toBe("HELLO")
        end)

        it("should handle conditionals", function()
            local fn = compiler.compile("{% if show then %}visible{% end %}", mockEngine)

            local ctx1 = { __filters = {}, show = true }
            expect(fn(ctx1)):toBe("visible")

            local ctx2 = { __filters = {}, show = false }
            expect(fn(ctx2)):toBe("")
        end)

        it("should handle loops", function()
            local fn = compiler.compile("{% for i = 1, 3 do %}{{ i }}{% end %}", mockEngine)
            local ctx = { __filters = require("vein.lib.filters").defaults() }
            local result = fn(ctx)
            expect(result):toBe("123")
        end)

        it("should handle for-in loops", function()
            local fn = compiler.compile("{% for item in items do %}{{ item }},{% end %}", mockEngine)
            local ctx = {
                __filters = require("vein.lib.filters").defaults(),
                items = {"a", "b", "c"}
            }
            local result = fn(ctx)
            expect(result):toBe("a,b,c,")
        end)

        it("should handle nil values gracefully", function()
            local fn = compiler.compile("{{ missing }}", mockEngine)
            local ctx = { __filters = require("vein.lib.filters").defaults() }
            local result = fn(ctx)
            expect(result):toBe("")
        end)
    end)

    describe("Metadata", function()
        it("should return metadata when requested", function()
            local fn, meta = compiler.compile("{{ x }}", mockEngine, { returnMetadata = true })
            expect(fn):toBeFunction()
            expect(meta):toBeTable()
            expect(meta.tokenCount):toBeNumber()
        end)
    end)
end)

--------------------------------------------------------------------------------
-- Complex Templates
--------------------------------------------------------------------------------

describe("Complex Templates", function()
    local mockEngine = {
        options = {
            autoEscape = true,
            delimiters = {
                output = { "{{", "}}" },
                raw = { "{!", "!}" },
                code = { "{%", "%}" },
                comment = { "{#", "#}" },
                include = { "{@", "@}" },
                partial = { "{>", ">}" },
            }
        }
    }

    it("should handle nested conditionals", function()
        local template = [[
{% if a then %}
  {% if b then %}both{% else %}only a{% end %}
{% else %}
  none
{% end %}
]]
        local fn = compiler.compile(template, mockEngine)

        local ctx1 = { __filters = {}, a = true, b = true }
        expect(fn(ctx1)):toContain("both")

        local ctx2 = { __filters = {}, a = true, b = false }
        expect(fn(ctx2)):toContain("only a")

        local ctx3 = { __filters = {}, a = false, b = true }
        expect(fn(ctx3)):toContain("none")
    end)

    it("should handle loops with conditionals", function()
        local template = "{% for n in nums do %}{% if n > 5 then %}{{ n }}{% end %}{% end %}"
        local fn = compiler.compile(template, mockEngine)
        local ctx = {
            __filters = require("vein.lib.filters").defaults(),
            nums = {3, 6, 4, 8, 2, 9}
        }
        local result = fn(ctx)
        expect(result):toBe("689")
    end)

    it("should handle table access", function()
        local template = "{{ user.name }} ({{ user.email }})"
        local fn = compiler.compile(template, mockEngine)
        local ctx = {
            __filters = require("vein.lib.filters").defaults(),
            user = { name = "John", email = "john@example.com" }
        }
        local result = fn(ctx)
        expect(result):toBe("John (john@example.com)")
    end)

    it("should handle array index access", function()
        local template = "First: {{ items[1] }}"
        local fn = compiler.compile(template, mockEngine)
        local ctx = {
            __filters = require("vein.lib.filters").defaults(),
            items = {"apple", "banana", "cherry"}
        }
        local result = fn(ctx)
        expect(result):toBe("First: apple")
    end)

    it("should handle arithmetic in expressions", function()
        local template = "{{ a + b }}"
        local fn = compiler.compile(template, mockEngine)
        local ctx = {
            __filters = require("vein.lib.filters").defaults(),
            a = 5, b = 3
        }
        local result = fn(ctx)
        expect(result):toBe("8")
    end)

    it("should handle string concatenation", function()
        local template = '{{ first .. " " .. last }}'
        local fn = compiler.compile(template, mockEngine)
        local ctx = {
            __filters = require("vein.lib.filters").defaults(),
            first = "John", last = "Doe"
        }
        local result = fn(ctx)
        expect(result):toBe("John Doe")
    end)

    it("should handle function calls in expressions", function()
        local template = "{{ #items }} items"
        local fn = compiler.compile(template, mockEngine)
        local ctx = {
            __filters = require("vein.lib.filters").defaults(),
            items = {1, 2, 3, 4, 5}
        }
        local result = fn(ctx)
        expect(result):toBe("5 items")
    end)
end)

return Assay.run()
