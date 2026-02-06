-- Vein Test Suite Runner
-- Run all Vein tests using Assay

-- Add packages directory to path for dev dependencies
-- CWD is packages/vein when running via shipyard, so packages is at ../
local sep = package.config:sub(1, 1)
package.path = ".." .. sep .. "?" .. sep .. "init.lua;" ..
               ".." .. sep .. "?.lua;" ..
               package.path

-- Custom Lua searcher to work around coppermoon safe mode issue
local function luaSearcher(modname)
    local path = modname:gsub("%.", "/")
    for pattern in package.path:gmatch("[^;]+") do
        local filepath = pattern:gsub("%?", path)
        local fn = loadfile(filepath)
        if fn then return fn, filepath end
    end
end
table.insert(package.searchers, 2, luaSearcher)

local Assay = require("assay")

-- Configure Assay
Assay.configure({
    bail = false,
    verbose = true,
    colors = true,
})

-- Track overall results
local allResults = {
    total = 0,
    passed = 0,
    failed = 0,
    skipped = 0
}

-- Run each test file
local testFiles = {
    "vein.tests.filters_test",
    "vein.tests.compiler_test",
    "vein.tests.engine_test",
}

for _, testFile in ipairs(testFiles) do
    -- Reset Assay state before each file
    Assay.runner.reset()

    -- Load and run tests
    local ok, results = pcall(function()
        return require(testFile)
    end)

    if ok and type(results) == "table" then
        allResults.total = allResults.total + (results.total or 0)
        allResults.passed = allResults.passed + (results.passCount or 0)
        allResults.failed = allResults.failed + (results.failCount or 0)
        allResults.skipped = allResults.skipped + (results.skipCount or 0)
    else
        print("\27[31mError loading " .. testFile .. ": " .. tostring(results) .. "\27[0m")
        allResults.failed = allResults.failed + 1
    end
end

-- Return exit code
return allResults.failed == 0 and 0 or 1
