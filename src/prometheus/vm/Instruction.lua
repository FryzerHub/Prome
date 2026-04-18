local Opcode = require("prometheus.vm.Opcode").Opcode;
local OpcodeInfo = require("prometheus.vm.Opcode").OpcodeInfo;

local Instruction = {};
Instruction.__index = Instruction;

function Instruction:new(opcode, ...)
    local args = {...};
    local info = OpcodeInfo[opcode];
    
    if not info then
        error("Invalid opcode: " .. tostring(opcode));
    end
    
    local inst = {
        opcode = opcode,
        args = args,
        name = info.name,
    };
    
    setmetatable(inst, self);
    return inst;
end

function Instruction:encode()
    local encoded = {self.opcode};
    for i, arg in ipairs(self.args) do
        table.insert(encoded, arg);
    end
    return encoded;
end

function Instruction.decode(bytecode, index)
    local opcode = bytecode[index];
    local info = OpcodeInfo[opcode];
    
    if not info then
        error("Invalid opcode at index " .. index);
    end
    
    local args = {};
    for i = 1, info.args - 1 do
        table.insert(args, bytecode[index + i]);
    end
    
    return Instruction:new(opcode, unpack(args)), index + info.args;
end

function Instruction:__tostring()
    local str = self.name;
    if #self.args > 0 then
        str = str .. " " .. table.concat(self.args, ", ");
    end
    return str;
end

return Instruction;