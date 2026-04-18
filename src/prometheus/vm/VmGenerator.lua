local VmGenerator = {};

function VmGenerator.generateInterpreter(bytecode, constants, config)
    local template = [[
local function VM(bytecode, constants)
    local stack = {};
    local sp = 0; -- stack pointer
    local pc = 1; -- program counter
    local env = getfenv(0);
    
    while pc <= #bytecode do
        local op = bytecode[pc];
        pc = pc + 1;
        
        if op == ]] .. config.opcodes.PUSH .. [[ then
            local value = bytecode[pc];
            pc = pc + 1;
            sp = sp + 1;
            stack[sp] = value;
            
        elseif op == ]] .. config.opcodes.ADD .. [[ then
            local b = stack[sp]; sp = sp - 1;
            local a = stack[sp];
            stack[sp] = a + b;
            
        -- ... more opcodes ...
        
        end
    end
    
    return stack[sp];
end

return VM(...)
]];
    
    return template;
end

return VmGenerator;