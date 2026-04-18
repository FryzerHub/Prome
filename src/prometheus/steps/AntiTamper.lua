-- ================================================================
-- Anti-Tamper Step
-- Adds runtime protection against debugging and tampering
-- ================================================================

local Step = require("prometheus.step");
local Ast = require("prometheus.ast");

local AntiTamper = Step:extend();
AntiTamper.Description = "Add anti-tampering protection";
AntiTamper.Name = "AntiTamper";

AntiTamper.SettingsDescriptor = {
    IntegrityCheck = {
        type = "boolean";
        default = true;
        description = "Add integrity verification";
    };
    AntiDebug = {
        type = "boolean";
        default = true;
        description = "Detect debugging attempts";
    };
    EnvironmentCheck = {
        type = "boolean";
        default = true;
        description = "Validate execution environment";
    };
};

function AntiTamper:init(settings)
    self.settings = settings or {};
end

function AntiTamper:apply(ast, pipeline)
    local parts = {};
    
    -- Add anti-debug check
    if self.settings.AntiDebug then
        table.insert(parts, self:generateAntiDebug());
    end
    
    -- Add environment validation
    if self.settings.EnvironmentCheck then
        table.insert(parts, self:generateEnvCheck());
    end
    
    if #parts == 0 then
        return ast;
    end
    
    -- Wrap original code with checks
    local checkCode = table.concat(parts, "\n");
    local wrappedAst = self:wrapWithChecks(ast, checkCode);
    
    return wrappedAst;
end

function AntiTamper:generateAntiDebug()
    return [[
-- Anti-Debug Check
(function()
    local function check()
        if debug then
            if debug.getinfo or debug.getupvalue or debug.setupvalue then
                error("\x44\x65\x62\x75\x67\x67\x69\x6E\x67\x20\x64\x65\x74\x65\x63\x74\x65\x64")
            end
        end
        
        -- Check for common debugging variables
        if rawget(_G, "dbg") or rawget(_G, "debugger") then
            error("Debug detected")
        end
    end
    
    check()
    
    -- Periodic checks
    local count = 0
    local old_error = error
    error = function(...)
        count = count + 1
        if count > 100 then
            -- Possible debugging breakpoint loop
            old_error("Anti-tamper triggered")
        end
        return old_error(...)
    end
end)()
]];
end

function AntiTamper:generateEnvCheck()
    return [[
-- Environment Validation
(function()
    local required_globals = {"print", "pcall", "type", "tostring"}
    for _, name in ipairs(required_globals) do
        if not _G[name] then
            error("Environment validation failed: " .. name)
        end
    end
    
    -- Check for sandboxing
    if not getfenv and not _ENV then
        error("Invalid environment")
    end
end)()
]];
end

function AntiTamper:wrapWithChecks(ast, checkCode)
    -- Parse check code to AST
    local Parser = require("prometheus.parser");
    local checkAst = Parser:new({
        LuaVersion = "Lua51";
    }):parse(checkCode);
    
    -- Prepend checks to main AST
    local body = ast.body.statements;
    for i = #checkAst.body.statements, 1, -1 do
        table.insert(body, 1, checkAst.body.statements[i]);
    end
    
    return ast;
end

return AntiTamper;