# Assay Testing

Assay is the unit testing framework for CopperMoon. It provides a Jest-inspired API with `describe`, `it`, `expect`, mocking, spies, and multiple reporters.

## Quick Start

```lua
local Assay = require("assay")
Assay.global()  -- Register describe, it, expect globally

describe("Calculator", function()
    it("should add numbers", function()
        expect(1 + 1):toBe(2)
    end)

    it("should multiply numbers", function()
        expect(3 * 4):toBe(12)
    end)
end)

Assay.run()
```

Output:

```
Calculator
  ✓ should add numbers (0.00μs)
  ✓ should multiply numbers (0.00μs)

──────────────────────────────────────────────────

Tests: 2 passed (2 total)
Time:  0.10ms

 PASS  All tests passed!
```

## Installation

Add Assay to your `harbor.toml` as a dev dependency:

```toml
[dev-dependencies]
assay = { path = "../assay" }
```

## Test Definition

### describe / it

Group tests into suites with `describe` and define individual tests with `it`:

```lua
describe("Math", function()
    describe("addition", function()
        it("should add integers", function()
            expect(2 + 3):toBe(5)
        end)

        it("should add floats", function()
            expect(0.1 + 0.2):toBeCloseTo(0.3, 5)
        end)
    end)

    describe("division", function()
        it("should divide evenly", function()
            expect(10 / 2):toBe(5)
        end)
    end)
end)
```

`test()` is an alias for `it()`.

### skip

Skip a test that is not ready or temporarily broken:

```lua
skip("should handle edge case", function()
    -- This test won't run
end)
```

### only

Focus on a specific test. When `only` is used, all other tests are skipped:

```lua
only("debug this test", function()
    expect(true):toBe(true)
end)
```

## Lifecycle Hooks

Run setup and teardown code around tests:

```lua
describe("Database", function()
    local db

    beforeAll(function()
        db = Database.connect("test.db")
    end)

    afterAll(function()
        db:close()
    end)

    beforeEach(function()
        db:beginTransaction()
    end)

    afterEach(function()
        db:rollback()
    end)

    it("should insert records", function()
        db:insert({ name = "Alice" })
        expect(db:count()):toBe(1)
    end)
end)
```

| Hook | When it runs |
|------|-------------|
| `beforeAll(fn)` | Once before all tests in the suite |
| `afterAll(fn)` | Once after all tests in the suite |
| `beforeEach(fn)` | Before each individual test |
| `afterEach(fn)` | After each individual test |

Hooks from parent suites run first. If a `beforeAll` or `beforeEach` hook fails, the affected tests are marked as failed.

## Configuration

```lua
Assay.configure({
    bail = false,        -- Stop on first failure
    verbose = true,      -- Verbose output
    shuffle = false,     -- Randomize test order
    seed = nil,          -- Random seed for shuffling
    filter = nil,        -- Lua pattern to filter test names
    colors = true,       -- ANSI color output
    showTimings = true,  -- Show test duration
    showSummary = true,  -- Show summary after tests
})
```

## Reporters

Assay includes four built-in reporters:

```lua
local Reporter = require("assay.lib.reporter")

Reporter.use("spec")    -- Hierarchical output (default)
Reporter.use("dot")     -- Minimal: . for pass, F for fail, S for skip
Reporter.use("tap")     -- Test Anything Protocol format
Reporter.use("json")    -- JSON output
```

### Spec Reporter (default)

```
Math
  addition
    ✓ should add integers (0.00μs)
    ✓ should add floats (0.00μs)
  division
    ✓ should divide evenly (0.00μs)
    ✗ should handle division by zero
      Expected Infinity to be 0

──────────────────────────────────────────────────

Tests: 3 passed, 1 failed (4 total)
Time:  0.50ms

 FAIL  Some tests failed
```

### Custom Reporter

Create your own reporter by providing a table of callbacks:

```lua
Reporter.use({
    onSuiteStart = function(suite, depth) end,
    onTestPass = function(test, result, depth) end,
    onTestFail = function(test, result, depth) end,
    onTestSkip = function(test, result, depth) end,
    onEnd = function(results) end,
})
```

## Running Tests

### From code

```lua
local results = Assay.run()
```

### Test runner script

Create `tests/init.lua`:

```lua
local Assay = require("assay")

Assay.configure({
    bail = false,
    verbose = true,
    colors = true,
})

-- Load test files
require("tests.math_test")
require("tests.string_test")

-- Run and return exit code
local results = Assay.run()
return results.success and 0 or 1
```

### Running multiple test files

When running multiple test files, reset Assay state between files:

```lua
local testFiles = {
    "tests.models_test",
    "tests.routes_test",
    "tests.utils_test",
}

for _, testFile in ipairs(testFiles) do
    Assay.runner.reset()
    require(testFile)
end
```

### With Shipyard

Add to `Shipyard.toml` or `harbor.toml`:

```toml
[scripts]
test = "coppermoon tests/init.lua"
```

Run with:

```bash
shipyard script test
```

## Test File Conventions

Name test files with one of these patterns for easy discovery:

- `*_test.lua`
- `*_spec.lua`
- `*.test.lua`
- `*.spec.lua`

## Assert-Style API

For those who prefer classic assertions over `expect()`:

```lua
local Expect = require("assay.lib.expect")
local assert = Expect.assert

assert.equal(1 + 1, 2)
assert.deepEqual({a = 1}, {a = 1})
assert.notEqual("a", "b")
assert.isTrue(true)
assert.isFalse(false)
assert.isNil(nil)
assert.isNotNil("hello")
assert.isType("hello", "string")
assert.throws(function() error("boom") end)
assert.doesNotThrow(function() return 1 end)
assert.contains("hello world", "world")
assert.matches("hello", "^hel")
```

## Next Steps

- [Assertions](/docs/assay/assertions) - Complete reference of all matchers
- [Mocking](/docs/assay/mocking) - Mock functions, spies, stubs, and fakes
