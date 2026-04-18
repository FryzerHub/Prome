-- ================================================================
-- VM Module - Main Interface
-- Converts Lua code to custom bytecode VM
-- ================================================================

local VM = {
    Compiler = require("prometheus.vm.Compiler");
    VMStrings = require("prometheus.vm.VMStrings");
    Encoder = require("prometheus.vm.Encoder");
    Opcode = require("prometheus.vm.Opcode");
};

-- Main entry point for VM compilation
function VM.compile(source, config)
    config = config or {};
    
    -- Initialize global opcode tracking
    _G.UsedOps = _G.UsedOps or {};
    _G.UsedOps[0] = 0;  -- MOVE
    _G.UsedOps[1] = 1;  -- LOADK
    _G.UsedOps[2] = 2;  -- LOADBOOL
    _G.UsedOps[4] = 4;  -- GETTABLE
    _G.UsedOps[5] = 5;  -- SETTABLE
    _G.UsedOps[6] = 6;  -- NEWTABLE
    _G.UsedOps[12] = 12; -- CALL
    _G.UsedOps[30] = 30; -- RETURN
    
    -- Compile source to bytecode
    local bytecode, constants, protos = VM.Compiler.compile(source);
    
    -- Generate VM runtime
    local vmCode = VM.VMStrings.generate(bytecode, _G.UsedOps, config);
    
    return vmCode;
end

return VM;