-- AST to VM Bytecode Compiler
local Compiler = {};
local Opcode = require("prometheus.vm.Opcode").Opcode;
local Instruction = require("prometheus.vm.Instruction");

-- AST Node Types
local AstKind = require("prometheus.ast").AstKind;

function Compiler:new()
    local obj = {
        instructions = {},
        constants = {},
        functions = {},
        registerCount = 0,
        labelCount = 0,
    };
    setmetatable(obj, {__index = self});
    return obj;
end

-- Allocate register
function Compiler:allocateRegister()
    self.registerCount = self.registerCount + 1;
    return self.registerCount;
end

-- Free register
function Compiler:freeRegister()
    if self.registerCount > 0 then
        self.registerCount = self.registerCount - 1;
    end
end

-- Add constant
function Compiler:addConstant(value)
    for i, const in ipairs(self.constants) do
        if const == value then
            return i - 1;
        end
    end
    table.insert(self.constants, value);
    return #self.constants - 1;
end

-- Emit instruction
function Compiler:emit(opcode, ...)
    local inst = Instruction:new(opcode, ...);
    table.insert(self.instructions, inst);
    return #self.instructions;
end

-- Compile number
function Compiler:compileNumber(node, target)
    target = target or self:allocateRegister();
    local constIndex = self:addConstant(node.value);
    self:emit(Opcode.LOADK, target, constIndex);
    return target;
end

-- Compile string
function Compiler:compileString(node, target)
    target = target or self:allocateRegister();
    local constIndex = self:addConstant(node.value);
    self:emit(Opcode.LOADK, target, constIndex);
    return target;
end

-- Compile boolean
function Compiler:compileBoolean(node, target)
    target = target or self:allocateRegister();
    self:emit(Opcode.LOADBOOL, target, node.value and 1 or 0, 0);
    return target;
end

-- Compile nil
function Compiler:compileNil(node, target)
    target = target or self:allocateRegister();
    self:emit(Opcode.LOADNIL, target, 0);
    return target;
end

-- Compile AST to bytecode
function Compiler:compile(ast)
    -- This is a simplified version
    -- You'll need to implement full AST traversal based on Prometheus AST structure
    
    return {
        instructions = self.instructions,
        constants = self.constants,
        functions = self.functions,
    };
end

return Compiler;