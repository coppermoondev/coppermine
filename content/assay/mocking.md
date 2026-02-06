# Mocking

Assay provides mock functions, spies, stubs, and fakes to isolate the code under test and control its dependencies.

## Mock Functions

Create a mock function with `Assay.fn()`:

```lua
-- Empty mock (returns nil)
local mockFn = Assay.fn()

-- Mock with implementation
local mockFn = Assay.fn(function(x)
    return x * 2
end)
```

Mock functions record every call, making them inspectable with `expect()` matchers.

## Configuring Return Values

### mockReturnValue(value)

Always return the same value:

```lua
local fn = Assay.fn()
fn:mockReturnValue(42)

fn()   -- 42
fn()   -- 42
```

### mockReturnValueOnce(value)

Return a value on the next call only:

```lua
local fn = Assay.fn()
fn:mockReturnValueOnce(1)
fn:mockReturnValueOnce(2)
fn:mockReturnValue(0)

fn()   -- 1 (once)
fn()   -- 2 (once)
fn()   -- 0 (default)
fn()   -- 0 (default)
```

### mockReturnValues(...)

Cycle through a list of return values:

```lua
local fn = Assay.fn()
fn:mockReturnValues(1, 2, 3)

fn()   -- 1
fn()   -- 2
fn()   -- 3
fn()   -- 1 (cycles back)
```

### mockImplementation(fn)

Set the mock's implementation:

```lua
local fn = Assay.fn()
fn:mockImplementation(function(x)
    return x + 1
end)

fn(5)   -- 6
fn(10)  -- 11
```

### mockImplementationOnce(fn)

Use an implementation for the next call only:

```lua
local fn = Assay.fn(function() return "default" end)
fn:mockImplementationOnce(function() return "special" end)

fn()   -- "special"
fn()   -- "default"
```

### mockRejectedValue(message)

Make the mock always throw:

```lua
local fn = Assay.fn()
fn:mockRejectedValue("connection failed")

expect(function() fn() end):toThrow("connection failed")
```

### mockRejectedValueOnce(message)

Throw on the next call only:

```lua
local fn = Assay.fn()
fn:mockRejectedValueOnce("timeout")
fn:mockReturnValue("ok")

expect(function() fn() end):toThrow("timeout")
fn()   -- "ok"
```

## Inspecting Calls

Every call to a mock is recorded in `mockFn.calls`:

```lua
local fn = Assay.fn()
fn(1, 2, 3)
fn("a", "b")

-- Check call count
print(#fn.calls)             -- 2

-- Access call arguments
fn.calls[1].args             -- {1, 2, 3}
fn.calls[2].args             -- {"a", "b"}
```

### With expect matchers

```lua
expect(fn):toHaveBeenCalled()
expect(fn):toHaveBeenCalledTimes(2)
expect(fn):toHaveBeenCalledWith(1, 2, 3)
expect(fn):toHaveBeenLastCalledWith("a", "b")
expect(fn):toHaveReturned()
expect(fn):toHaveReturnedWith(42)
```

## Resetting Mocks

### mockClear()

Clear call history but keep the implementation:

```lua
fn(1)
fn(2)
fn:mockClear()
print(#fn.calls)   -- 0
fn(3)              -- Still uses the same implementation
```

### mockReset()

Reset everything to initial state (clear history and implementation):

```lua
fn:mockReturnValue(42)
fn(1)
fn:mockReset()
print(#fn.calls)   -- 0
fn()               -- nil (no implementation)
```

### mockRestore()

Restore the original function (for spies):

```lua
local spy = Assay.spy(obj, "method")
-- ... test ...
spy:mockRestore()   -- obj.method is back to original
```

## Spies

Spies wrap an existing function to track calls while still executing the original:

### Spy on a standalone function

```lua
local original = function(x) return x * 2 end
local spied = Assay.spy(original)

spied(5)   -- 10 (original still runs)
expect(spied):toHaveBeenCalledWith(5)
```

### Spy on an object method

```lua
local obj = {
    greet = function(self, name)
        return "Hello, " .. name
    end
}

local spy = Assay.spy(obj, "greet")

obj:greet("Alice")   -- "Hello, Alice" (original runs)
expect(spy):toHaveBeenCalled()
expect(spy):toHaveBeenCalledWith("Alice")

spy:mockRestore()    -- Restore original method
```

## Stubs

A stub is a mock with no implementation. Use it when you want to replace a dependency without any behavior:

```lua
local stub = Assay.stub()

stub("anything")   -- nil
expect(stub):toHaveBeenCalledWith("anything")
```

You can configure a stub's return value:

```lua
local stub = Assay.stub()
stub:mockReturnValue(true)

stub()   -- true
```

## Fakes

A fake is an object with multiple mocked methods. Use it to replace an entire dependency:

```lua
local fakeDb = Assay.fake({
    connect = function() return true end,
    query = function() return {} end,
    close = function() end,
})

fakeDb.connect()   -- true
fakeDb.query()     -- {}
fakeDb.close()     -- nil

expect(fakeDb.connect):toHaveBeenCalled()
expect(fakeDb.query):toHaveBeenCalled()
```

Each method in a fake is a mock function, so you can configure return values and inspect calls individually.

## Timer Mocking

Mock `os.clock()` for time-dependent tests:

```lua
local Mock = require("assay.lib.mock")
local timers = Mock.useFakeTimers()

timers:setSystemTime(1000)
print(os.clock())                   -- 1.0

timers:advanceTimersByTime(500)
print(os.clock())                   -- 1.5

timers:useRealTimers()              -- Restore real timers
```

## Argument Matchers

When verifying mock calls, use matchers for flexible argument checking:

```lua
local Mock = require("assay.lib.mock")

local fn = Assay.fn()
fn({ id = 1, name = "Alice", email = "alice@example.com" })

-- Match a subset of the object
expect(fn):toHaveBeenCalledWith(
    Mock.matchers.objectContaining({ id = 1 })
)

-- Match any value of a type
expect(fn):toHaveBeenCalledWith(
    Mock.matchers.anyType("table")
)
```

Available matchers:

```lua
Mock.matchers.any()                    -- Matches anything
Mock.matchers.anyString()              -- Matches any string
Mock.matchers.anyNumber()              -- Matches any number
Mock.matchers.anyFunction()            -- Matches any function
Mock.matchers.anyType("table")         -- Matches any value of type
Mock.matchers.objectContaining({...})  -- Matches table with at least these keys
Mock.matchers.stringContaining("sub")  -- Matches string containing substring
Mock.matchers.stringMatching("^pat")   -- Matches string against Lua pattern
```

## Practical Example

Testing a user service with mocked database:

```lua
describe("UserService", function()
    local userService, mockDb

    beforeEach(function()
        mockDb = Assay.fake({
            findById = function(id)
                return { id = id, name = "Alice" }
            end,
            save = function(user)
                return true
            end,
        })
        userService = UserService.new(mockDb)
    end)

    describe("getUser()", function()
        it("should return user by id", function()
            local user = userService:getUser(1)
            expect(user):toBeDefined()
            expect(user.name):toBe("Alice")
            expect(mockDb.findById):toHaveBeenCalledWith(1)
        end)

        it("should return nil for missing user", function()
            mockDb.findById:mockReturnValue(nil)
            local user = userService:getUser(999)
            expect(user):toBeNil()
        end)
    end)

    describe("updateUser()", function()
        it("should save updated user", function()
            userService:updateUser(1, { name = "Bob" })
            expect(mockDb.save):toHaveBeenCalled()
            expect(mockDb.save):toHaveBeenCalledTimes(1)
        end)
    end)
end)
```
