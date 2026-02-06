# Assertions

Assertions use the `expect(value)` function followed by a matcher with colon syntax:

```lua
expect(value):matcher(expected)
```

## Negation

Use `.never` or `.NOT` to negate any matcher:

```lua
expect(5).never:toBe(3)
expect("hello").NOT:toContain("xyz")
```

## Equality

### toBe(expected)

Strict equality using `==`.

```lua
expect(2):toBe(2)
expect("hello"):toBe("hello")
expect(true):toBe(true)
```

### toEqual(expected)

Deep equality for tables. Compares structure and values recursively.

```lua
expect({a = 1, b = 2}):toEqual({a = 1, b = 2})
expect({1, 2, 3}):toEqual({1, 2, 3})
expect({a = {b = {c = 1}}}):toEqual({a = {b = {c = 1}}})
```

### toStrictEqual(expected)

Same reference check using `rawequal`.

```lua
local t = {1, 2, 3}
expect(t):toStrictEqual(t)       -- Same reference, passes
expect({1}):toStrictEqual({1})   -- Different reference, fails
```

## Truthiness

### toBeTruthy()

Value is truthy (not `false` and not `nil`).

```lua
expect(true):toBeTruthy()
expect(1):toBeTruthy()
expect(""):toBeTruthy()
expect({}):toBeTruthy()
```

### toBeFalsy()

Value is falsy (`false` or `nil`).

```lua
expect(false):toBeFalsy()
expect(nil):toBeFalsy()
```

### toBeNil()

Value is `nil`.

```lua
expect(nil):toBeNil()
```

### toBeDefined()

Value is not `nil`.

```lua
expect("hello"):toBeDefined()
expect(0):toBeDefined()
expect(false):toBeDefined()  -- false is defined
```

## Type Checking

### toBeType(typeName)

Check the Lua type.

```lua
expect("hello"):toBeType("string")
expect(42):toBeType("number")
expect({}):toBeType("table")
expect(true):toBeType("boolean")
expect(print):toBeType("function")
```

### Shorthand Type Matchers

```lua
expect("hello"):toBeString()
expect(42):toBeNumber()
expect(true):toBeBoolean()
expect({}):toBeTable()
expect(print):toBeFunction()
```

## Number Comparison

### toBeGreaterThan(n)

```lua
expect(10):toBeGreaterThan(5)
```

### toBeGreaterThanOrEqual(n) / toBeAtLeast(n)

```lua
expect(10):toBeGreaterThanOrEqual(10)
expect(10):toBeAtLeast(10)
```

### toBeLessThan(n)

```lua
expect(5):toBeLessThan(10)
```

### toBeLessThanOrEqual(n) / toBeAtMost(n)

```lua
expect(5):toBeLessThanOrEqual(5)
expect(5):toBeAtMost(5)
```

### toBeCloseTo(n, precision)

Floating point comparison. `precision` is the number of decimal digits to check.

```lua
expect(0.1 + 0.2):toBeCloseTo(0.3, 5)
expect(3.14159):toBeCloseTo(3.14, 2)
```

### toBePositive()

```lua
expect(42):toBePositive()
expect(0.1):toBePositive()
```

### toBeNegative()

```lua
expect(-3):toBeNegative()
expect(-0.1):toBeNegative()
```

### toBeInteger()

```lua
expect(42):toBeInteger()
expect(42.0):toBeInteger()
```

## String Matchers

### toContain(substring)

String contains a substring (also works on arrays).

```lua
expect("hello world"):toContain("world")
```

### toMatch(pattern)

Match a Lua pattern.

```lua
expect("hello"):toMatch("^hel")
expect("test123"):toMatch("%d+$")
expect("hello@world.com"):toMatch(".+@.+%..+")
```

### toStartWith(prefix)

```lua
expect("hello"):toStartWith("hel")
```

### toEndWith(suffix)

```lua
expect("hello"):toEndWith("llo")
```

### toHaveLength(n)

Check string or table length.

```lua
expect("hello"):toHaveLength(5)
expect({1, 2, 3}):toHaveLength(3)
```

### toBeEmpty()

String is empty or table has no elements.

```lua
expect(""):toBeEmpty()
expect({}):toBeEmpty()
```

## Table Matchers

### toContain(element)

Array contains an element.

```lua
expect({1, 2, 3}):toContain(2)
expect({"a", "b", "c"}):toContain("b")
```

### toContainEqual(element)

Array contains an element matching by deep equality.

```lua
expect({{id = 1}, {id = 2}}):toContainEqual({id = 1})
```

### toHaveProperty(key, value)

Table has a key, optionally with a specific value.

```lua
expect({a = 1, b = 2}):toHaveProperty("a")
expect({a = 1, b = 2}):toHaveProperty("a", 1)
```

### toHaveKey(key)

Table has a key.

```lua
expect({x = 10, y = 20}):toHaveKey("x")
```

### toHaveLength(n)

Array has the specified number of elements.

```lua
expect({1, 2, 3}):toHaveLength(3)
```

### toBeEmpty()

Table has no elements.

```lua
expect({}):toBeEmpty()
```

## Error Matchers

### toThrow(message)

Function throws an error. Optionally check the error message contains a substring.

```lua
expect(function()
    error("boom")
end):toThrow()

expect(function()
    error("specific error message")
end):toThrow("specific")
```

### toNotThrow()

Function does not throw.

```lua
expect(function()
    return 42
end):toNotThrow()
```

## Instance Checking

### toBeInstanceOf(class)

Check if a value has a specific metatable.

```lua
local MyClass = {}
MyClass.__index = MyClass

local obj = setmetatable({}, MyClass)
expect(obj):toBeInstanceOf(MyClass)
```

## Mock Matchers

These matchers work with mock functions created by `Assay.fn()` or `Assay.spy()`.

### toHaveBeenCalled()

Mock was called at least once.

```lua
local fn = Assay.fn()
fn()
expect(fn):toHaveBeenCalled()
```

### toHaveBeenCalledTimes(n)

Mock was called exactly `n` times.

```lua
local fn = Assay.fn()
fn()
fn()
expect(fn):toHaveBeenCalledTimes(2)
```

### toHaveBeenCalledWith(...)

Mock was called with the specified arguments (any call).

```lua
local fn = Assay.fn()
fn(1, 2, 3)
fn("a", "b")
expect(fn):toHaveBeenCalledWith(1, 2, 3)
```

### toHaveBeenLastCalledWith(...)

Most recent call used the specified arguments.

```lua
local fn = Assay.fn()
fn("first")
fn("last")
expect(fn):toHaveBeenLastCalledWith("last")
```

### toHaveReturned()

Mock returned a value (did not throw).

```lua
local fn = Assay.fn(function() return 42 end)
fn()
expect(fn):toHaveReturned()
```

### toHaveReturnedWith(value)

Mock returned a specific value.

```lua
local fn = Assay.fn(function() return 42 end)
fn()
expect(fn):toHaveReturnedWith(42)
```

## Argument Matchers

Use flexible matchers when verifying mock calls:

```lua
local Mock = require("assay.lib.mock")

expect(fn):toHaveBeenCalledWith(
    Mock.matchers.any(),                  -- Match anything
    Mock.matchers.anyString(),            -- Match any string
    Mock.matchers.anyNumber()             -- Match any number
)
```

Available argument matchers:

| Matcher | Description |
|---------|-------------|
| `any()` | Match any value |
| `anyString()` | Match any string |
| `anyNumber()` | Match any number |
| `anyFunction()` | Match any function |
| `anyType(typeName)` | Match any value of the given type |
| `objectContaining(subset)` | Match table containing at least these keys |
| `stringContaining(substr)` | Match string containing substring |
| `stringMatching(pattern)` | Match string against Lua pattern |

```lua
expect(fn):toHaveBeenCalledWith(
    Mock.matchers.objectContaining({id = 1}),
    Mock.matchers.stringContaining("hello")
)
```
