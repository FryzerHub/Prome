-- VM Runtime/Interpreter
local Runtime = {};
local Opcode = require("prometheus.vm.Opcode").Opcode;

function Runtime:new(bytecode)
    local obj = {
        instructions = bytecode.instructions,
        constants = bytecode.constants,
        pc = 1,
        registers = {},
        stack = {},
        globals = _G,
        upvalues = {},
    };
    setmetatable(obj, {__index = self});
    return obj;
end

-- Get register value
function Runtime:getReg(index)
    return self.registers[index];
end

-- Set register value
function Runtime:setReg(index, value)
    self.registers[index] = value;
end

-- Get constant value
function Runtime:getConst(index)
    return self.constants[index + 1];
end

-- Run the VM
function Runtime:run()
    -- Simplified runtime execution
    return;
end

return Runtime;