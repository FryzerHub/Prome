local VmGenerator = require("prometheus.vm.VmGenerator");
local Instruction = require("prometheus.vm.Instruction");

function Vmify:apply(ast, pipeline)
    -- 1. Convert AST to bytecode
    local bytecode = self:astToBytecode(ast);
    
    -- 2. Extract constants
    local constants = self:extractConstants(ast);
    
    -- 3. Generate VM interpreter
    local vmCode = VmGenerator.generateInterpreter(
        bytecode, 
        constants,
        {opcodes = Instruction}
    );
    
    -- 4. Return new AST with VM code
    return parser:parse(vmCode);
end