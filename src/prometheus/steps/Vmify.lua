-- ================================================================
-- Vmify Step - Convert to Custom VM Bytecode
-- This step must run LAST in the pipeline
-- ================================================================

local Step = require("prometheus.step");
local Ast = require("prometheus.ast");
local Scope = require("prometheus.scope");
local VM = require("prometheus.vm");

local Vmify = Step:extend();
Vmify.Description = "Convert code to custom virtual machine bytecode";
Vmify.Name = "Vmify";

Vmify.SettingsDescriptor = {
    CustomOpcodes = {
        type = "boolean";
        default = true;
        description = "Use randomized opcode mappings";
    };
    AntiDebug = {
        type = "boolean";
        default = true;
        description = "Enable anti-debugging checks";
    };
    IntegrityCheck = {
        type = "boolean";
        default = false;
        description = "Add integrity verification";
    };
};

function Vmify:init(settings)
    self.settings = settings or {};
end

function Vmify:apply(ast, pipeline)
    -- Convert AST to Lua source code
    local code = pipeline:getCode(ast);
    
    -- Add anti-debug if enabled
    if self.settings.AntiDebug then
        code = self:addAntiDebug(code);
    end
    
    -- Compile to VM bytecode
    local vmCode = VM.compile(code, self.settings);
    
    -- Add integrity check if enabled
    if self.settings.IntegrityCheck then
        vmCode = self:addIntegrityCheck(vmCode);
    end
    
    -- Return as string (not AST, this is the final output)
    return vmCode;
end

function Vmify:addAntiDebug(code)
    local antiDebug = [[
-- Anti-Debug Check
local function __check_debug()
    if debug and debug.getinfo then
        error("Debugging not allowed")
    end
end
__check_debug()

]];
    return antiDebug .. code;
end

function Vmify:addIntegrityCheck(code)
    -- Calculate simple checksum
    local sum = 0;
    for i = 1, #code do
        sum = sum + code:byte(i);
    end
    sum = sum % 65536;
    
    local check = string.format([[
-- Integrity Check
local __expected_checksum = %d
local __actual_checksum = 0
local __code = [[%s]]
for i = 1, #__code do
    __actual_checksum = __actual_checksum + __code:byte(i)
end
__actual_checksum = __actual_checksum %% 65536
if __actual_checksum ~= __expected_checksum then
    error("Code integrity violation")
end

]], sum, code:gsub("]]", "]]..]"));
    
    return check .. code;
end

return Vmify;