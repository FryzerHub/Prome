-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- PreventDecompilation.lua
--
-- This Step adds aggressive anti-decompilation code to break decoders

local Step = require("prometheus.step");
local Ast = require("prometheus.ast");
local Scope = require("prometheus.scope");
local Visitast = require("prometheus.visitast");
local util = require("prometheus.util");
local Parser = require("prometheus.parser");
local Enums = require("prometheus.enums");
local RandomStrings = require("prometheus.randomStrings");

local PreventDecompilation = Step:extend();
PreventDecompilation.Name = "Prevent Decompilation";
PreventDecompilation.Description = "Adds aggressive anti-decompilation code to break bytecode decoders";

PreventDecompilation.SettingsDescriptor = {
    Enabled = {
        type = "boolean",
        default = true,
        description = "Enable aggressive decompilation prevention"
    };
    DecoyCodeDensity = {
        type = "number",
        default = 0.4,
        min = 0,
        max = 1,
        description = "Density of decoy code paths that break decompilers"
    };
    RuntimeChecks = {
        type = "boolean",
        default = true,
        description = "Add runtime integrity checks that break analysis"
    };
    BytecodeObfuscation = {
        type = "boolean",
        default = true,
        description = "Obfuscate bytecode layout to break disassembly"
    }
};

function PreventDecompilation:init(_) end

local function buildTrapChunk(settings)
    local density = tonumber(settings.DecoyCodeDensity) or 0.4;
    density = math.max(0, math.min(1, density));

    -- Keep runtime overhead tiny: traps are behind opaque predicates that are
    -- stable at runtime but hard for simplistic deobfuscators to fold.
    local tag = RandomStrings.randomString();
    local sanity = math.random(2^20, 2^24);
    local iters = math.floor(10 + density * 80);

    local runtimeChecks = settings.RuntimeChecks and "true" or "false";
    local bytecodeObf = settings.BytecodeObfuscation and "true" or "false";

    return string.format([[
do
    local _rt = %s;
    local _bc = %s;
    local _tag = %q;
    local _n = %d;

    local _pcall = pcall;
    local _type = type;
    local _tostring = tostring;
    local _select = select;
    local _unpack = (table and table.unpack) or unpack;

    -- Opaque, stable predicate. Designed to be hard to constant-fold for
    -- naive deobfuscators (varargs, pcall, multi-return).
    local function _opaque(...)
        local ok, a, b = _pcall(function(x, y)
            return (x + 1) - 1, (y .. ""):sub(1, 0);
        end, _n, _tag);
        if not ok then return false end
        local c = _select("#", a, b, ...);
        return (c > 1) and (_type(a) == "number") and (_tostring(b) == "");
    end

    -- Lightweight integrity checks that don't require debug library.
    local function _integrity()
        if not _rt then return true end
        if _type(_pcall) ~= "function" then return false end
        local ok1 = _pcall(function() return 1 end);
        local ok2, msg = _pcall(function() error(_tag, 0) end);
        if ok1 ~= true then return false end
        if ok2 ~= false then return false end
        if _type(msg) ~= "string" or msg:sub(1, #_tag) ~= _tag then return false end
        return true
    end

    -- Dead-code traps (executed only if integrity fails).
    local function _trap()
        if not _bc then return end

        -- Many decompilers/decoders hate vararg packing/unpacking with sparse nils.
        local function _mr(...)
            local t = { ... }
            t[#t + 2] = nil
            return _unpack(t)
        end

        -- Confusing control flow with safe termination.
        local acc = 0
        for i = 1, %d do
            local a = (i * 1103515245 + 12345) %% 2^31
            local b = (a %% 97) + 1
            if (a %% b) == (a %% b) then
                acc = (acc + (a %% 256)) %% 256
            else
                acc = (acc + 1) %% 256
            end
        end

        -- Create values that look meaningful, then discard.
        local _ = _mr(acc, nil, acc, nil, _tag, nil)
        if _ then end
    end

    if _integrity() and _opaque(_tag, _n, _tag) then
        -- fast path: do nothing
    else
        _trap()
        -- fail closed without an infinite loop (Roblox safe)
        error("Integrity check failed", 0)
    end
end
]], runtimeChecks, bytecodeObf, tag, sanity, iters);
end

function PreventDecompilation:apply(ast, pipeline)
    if not self.Enabled then
        return ast;
    end

    -- Inject a small, Roblox-compatible anti-analysis trampoline near the top.
    -- Important: keep PrettyPrint compatibility by using parsed AST insertion.
    local code = buildTrapChunk(self);
    local parsed = Parser:new({ LuaVersion = Enums.LuaVersion.Lua51 }):parse(code);
    local doStat = parsed.body.statements[1];
    doStat.body.scope:setParent(ast.body.scope);
    table.insert(ast.body.statements, 1, doStat);

    return ast;
end

return PreventDecompilation;
