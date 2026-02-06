-- HoneyMoon - Web Framework for CopperMoon
-- A complete, production-ready web framework inspired by Express.js
--
-- Features:
--   - Express-style routing with parameters
--   - Schema validation for requests
--   - Session management
--   - Authentication (Basic, Bearer, API Key)
--   - Rate limiting
--   - Security headers (Helmet)
--   - Static file serving
--   - Error pages with stack traces
--
-- Usage:
--   local honeymoon = require("honeymoon")
--   local app = honeymoon.new()
--
--   app:get("/", function(req, res)
--       res:send("Hello World!")
--   end)
--
--   app:listen(3000)
--
-- @module honeymoon
-- @author CopperMoon Team
-- @license MIT

local honeymoon = {}

--------------------------------------------------------------------------------
-- Version
--------------------------------------------------------------------------------

honeymoon._VERSION = "0.2.0"
honeymoon._DESCRIPTION = "A complete, production-ready web framework for CopperMoon"

--------------------------------------------------------------------------------
-- Core Modules
--------------------------------------------------------------------------------

local application = require("honeymoon.lib.application")
local router_mod = require("honeymoon.lib.router")
local schema_mod = require("honeymoon.lib.schema")
local errors_mod = require("honeymoon.lib.errors")
local utils_mod = require("honeymoon.lib.utils")
local session_mod = require("honeymoon.lib.session")
local middleware = require("honeymoon.lib.middleware")

--------------------------------------------------------------------------------
-- Application Factory
--------------------------------------------------------------------------------

--- Create a new HoneyMoon application
---@return Application
function honeymoon.new()
    return application.new()
end

--------------------------------------------------------------------------------
-- Router
--------------------------------------------------------------------------------

--- Router class for modular route definitions
honeymoon.Router = {
    --- Create a new router
    ---@return Router
    new = function()
        return router_mod.new()
    end
}

--------------------------------------------------------------------------------
-- Schema Validation
--------------------------------------------------------------------------------

--- Create a validation schema
---@param definition table Schema definition
---@return Schema
function honeymoon.schema(definition)
    return schema_mod.new(definition)
end

--- Schema presets for common fields
honeymoon.schemaPresets = schema_mod.presets

--- Get a schema preset
---@param name string Preset name
---@return table
function honeymoon.preset(name)
    return schema_mod.preset(name)
end

--------------------------------------------------------------------------------
-- Error Classes
--------------------------------------------------------------------------------

--- Validation error class
honeymoon.ValidationError = errors_mod.ValidationError

--- HTTP error class
honeymoon.HttpError = errors_mod.HttpError

--- Error factory functions
honeymoon.errors = {
    badRequest = errors_mod.bad_request,
    unauthorized = errors_mod.unauthorized,
    forbidden = errors_mod.forbidden,
    notFound = errors_mod.not_found,
    methodNotAllowed = errors_mod.method_not_allowed,
    conflict = errors_mod.conflict,
    unprocessable = errors_mod.unprocessable,
    tooManyRequests = errors_mod.too_many_requests,
    internal = errors_mod.internal,
}

--------------------------------------------------------------------------------
-- Built-in Middleware
--------------------------------------------------------------------------------

-- Logger
honeymoon.logger = middleware.logger

-- CORS
honeymoon.cors = middleware.cors

-- Body parsers
honeymoon.json = middleware.json
honeymoon.urlencoded = middleware.urlencoded
honeymoon.bodyParser = middleware.bodyParser
honeymoon.raw = middleware.raw
honeymoon.text = middleware.text

-- Static files
honeymoon.static = middleware.static
honeymoon.directory = middleware.directory

-- Rate limiting
honeymoon.rateLimit = middleware.rateLimit

-- Authentication
honeymoon.basicAuth = middleware.basicAuth
honeymoon.bearerAuth = middleware.bearerAuth
honeymoon.apiKeyAuth = middleware.apiKeyAuth
honeymoon.jwtAuth = middleware.jwtAuth

-- Session
honeymoon.session = middleware.session
honeymoon.flash = middleware.flash

-- Security
honeymoon.helmet = middleware.helmet
honeymoon.csrf = middleware.csrf
honeymoon.requestId = middleware.requestId

-- Utilities
honeymoon.timeout = middleware.timeout
honeymoon.compression = middleware.compression
honeymoon.favicon = middleware.favicon
honeymoon.methodOverride = middleware.methodOverride
honeymoon.responseTime = middleware.responseTime

-- Authorization helpers
honeymoon.requireAuth = middleware.requireAuth
honeymoon.requireRoles = middleware.requireRoles
honeymoon.requirePermission = middleware.requirePermission

--------------------------------------------------------------------------------
-- Session Store
--------------------------------------------------------------------------------

--- Create a memory session store
---@return MemoryStore
function honeymoon.MemoryStore()
    return session_mod.MemoryStore()
end

--------------------------------------------------------------------------------
-- Utilities
--------------------------------------------------------------------------------

--- Utility functions
honeymoon.utils = {
    urlEncode = utils_mod.url_encode,
    urlDecode = utils_mod.url_decode,
    randomString = utils_mod.random_string,
    deepCopy = utils_mod.deep_copy,
    merge = utils_mod.merge,
    base64Encode = utils_mod.base64_encode,
    base64Decode = utils_mod.base64_decode,
    trim = utils_mod.trim,
    split = utils_mod.split,
    isEmail = utils_mod.is_email,
    isUrl = utils_mod.is_url,
    isUuid = utils_mod.is_uuid,
    getMimeType = utils_mod.get_mime_type,
    getStatusText = utils_mod.get_status_text,
    normalizePath = utils_mod.normalize_path,
    joinPath = utils_mod.join_path,
    isSafePath = utils_mod.is_safe_path,
}

--- MIME types mapping
honeymoon.mimeTypes = utils_mod.mime_types

--- HTTP status codes mapping
honeymoon.statusCodes = utils_mod.status_codes

return honeymoon
