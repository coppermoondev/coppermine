-- Ember - Structured Logging Library for CopperMoon
-- Fast, extensible logging with transports, formatters, and child loggers
--
-- Usage:
--   local ember = require("ember")
--
--   -- Zero-config (console output, info level)
--   local log = ember()
--   log:info("Hello world")
--
--   -- Full config
--   local log = ember({
--       level = "debug",
--       name = "my-app",
--       transports = {
--           ember.transports.console({ colors = true }),
--           ember.transports.file({ path = "./logs/app.log", level = "warn" }),
--       },
--       context = { service = "api" },
--   })
--
--   -- Structured logging
--   log:info("User login", { userId = 42, ip = "127.0.0.1" })
--
--   -- Child loggers
--   local reqLog = log:child({ requestId = "abc-123" })
--   reqLog:info("Processing")  -- includes requestId automatically
--
-- @module ember
-- @author CopperMoon Team
-- @license MIT

local ember = {}

--------------------------------------------------------------------------------
-- Version
--------------------------------------------------------------------------------

ember._VERSION = "0.1.0"
ember._DESCRIPTION = "A structured logging library for CopperMoon"

--------------------------------------------------------------------------------
-- Core Modules
--------------------------------------------------------------------------------

local Logger = require("ember.lib.logger")
local levels = require("ember.lib.levels")
local transport_mod = require("ember.lib.transport")
local formatter_mod = require("ember.lib.formatter")

--------------------------------------------------------------------------------
-- Built-in Transports & Formatters
--------------------------------------------------------------------------------

ember.transports = {
    console = require("ember.lib.transports.console"),
    file    = require("ember.lib.transports.file"),
    json    = require("ember.lib.transports.json"),
}

ember.formatters = {
    text   = require("ember.lib.formatters.text"),
    json   = require("ember.lib.formatters.json"),
    pretty = require("ember.lib.formatters.pretty"),
}

ember.levels = levels

--------------------------------------------------------------------------------
-- Factory
--------------------------------------------------------------------------------

--- Create a new logger instance
---@param options table|nil Logger options
---@return Logger
function ember.new(options)
    options = options or {}

    -- Default transport: console with pretty colors at info level
    if not options.transports then
        options.transports = {
            ember.transports.console({ colors = true }),
        }
    end

    return Logger.new(options)
end

--------------------------------------------------------------------------------
-- Custom Transport / Formatter Constructors
--------------------------------------------------------------------------------

--- Create a custom transport from a definition table
---@param definition table  Must have `name` and `write` fields
---@return table Transport
function ember.transport(definition)
    return transport_mod.create(definition)
end

--- Create a custom formatter from a function or table
---@param fn_or_table function|table
---@return table Formatter
function ember.formatter(fn_or_table)
    return formatter_mod.create(fn_or_table)
end

--------------------------------------------------------------------------------
-- Integrations (lazy-loaded)
--------------------------------------------------------------------------------

local _honeymoon = nil
local _lantern = nil
local _freight = nil

--- Create HoneyMoon middleware that attaches req.log child logger
---@param logger Logger       The root logger
---@param options table|nil   Middleware options
---@return function middleware
function ember.honeymoon(logger, options)
    if not _honeymoon then
        _honeymoon = require("ember.lib.integrations.honeymoon")
    end
    return _honeymoon.middleware(logger, options)
end

--- Create Lantern bridge middleware (connects req.log to req.lantern)
---@param options table|nil
---@return function middleware
function ember.lantern(options)
    if not _lantern then
        _lantern = require("ember.lib.integrations.lantern")
    end
    return _lantern.middleware(options)
end

--- Wrap a Freight database instance for query logging
---@param db table    Freight database instance
---@param logger Logger
---@param options table|nil
---@return table db
function ember.freight(db, logger, options)
    if not _freight then
        _freight = require("ember.lib.integrations.freight")
    end
    return _freight.setup(db, logger, options)
end

--------------------------------------------------------------------------------
-- Callable: ember(options) == ember.new(options)
--------------------------------------------------------------------------------

setmetatable(ember, {
    __call = function(_, options)
        return ember.new(options)
    end,
})

return ember
