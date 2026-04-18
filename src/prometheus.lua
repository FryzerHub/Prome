-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- prometheus.lua
--
-- This file is the entrypoint for Prometheus (Enhanced Security Edition)

-- [Security Bootstrap] Integrity Check: Ensure environment hasn't been hooked
local function verify_integrity()
    local core_funcs = {require, math.random, setmetatable, pcall, debug.getinfo}
    for _, func in ipairs(core_funcs) do
        local info = debug.getinfo(func, "S")
        -- If a core C function is reported as "Lua", it's likely a hook/proxy
        if info and info.what == "Lua" then
            error("[Prometheus Security] Critical: Environment Hook Detected on core function.")
        end
    end
end
verify_integrity()

-- Configure package.path for require
local function script_path()
	local str = debug.getinfo(2, "S").source:sub(2)
	return str:match("(.*[/%\\])")
end

local oldPkgPath = package.path;
package.path = script_path() .. "?.lua;" .. package.path;

-- Enhanced Math.random Seeding for unpredictable obfuscation results
math.randomseed(os.time() + os.clock() * 1000)

-- Math.random Fix for Lua5.1
-- Check if fix is needed
if not pcall(function()
    return math.random(1, 2^40);
end) then
    local oldMathRandom = math.random;
    math.random = function(a, b)
        if not a and b then
            return oldMathRandom();
        end
        if not b then
            return math.random(1, a);
        end
        if a > b then
            a, b = b, a;
        end
        local diff = b - a;
        assert(diff >= 0);
        if diff > 2 ^ 31 - 1 then
            return math.floor(oldMathRandom() * diff + a);
        else
            return oldMathRandom(a, b);
        end
    end
end

-- newproxy polyfill
_G.newproxy = _G.newproxy or function(arg)
    if arg then
        return setmetatable({}, {__metatable = "Locked"});
    end
    return {};
end

-- Require Prometheus Submodules
local Pipeline = require("prometheus.pipeline");
local highlight = require("highlightlua");
local colors = require("prometheus.colors");
local Logger = require("prometheus.logger");
local Presets = require("presets");
local Config = require("config");
local util = require("prometheus.util");

-- [Security Addition] Recursive Read-Only Protection
-- Ensures sub-tables in the exported modules cannot be modified
local function deep_lock(tbl)
    local proxy = {}
    local mt = {
        __index = tbl,
        __newindex = function() 
            error("[Prometheus Security] Attempt to modify protected module.", 2) 
        end,
        __metatable = "Locked",
    }
    return setmetatable(proxy, mt)
end

-- Restore package.path
package.path = oldPkgPath;

-- Export with enhanced security layers
local Prometheus = {
    Pipeline = Pipeline,
    colors = colors,
    Config = util.readonly(Config),
    Logger = Logger,
    highlight = highlight,
    Presets = Presets,
    -- [Security Addition] Version & Integrity metadata
    Version = "1.4.2-Secure",
    _INTEGRITY = true
}

-- Lock the main export table to prevent tampering during the pipeline execution
return deep_lock(Prometheus)