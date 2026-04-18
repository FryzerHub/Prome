-- AST to VM Bytecode Compiler
local Compiler = {}
local Opcode = require("prometheus.vm.Opcode").Opcode
local Instruction = require("prometheus.vm.Instruction")

-- AST Node Types
local AstKind = require("prometheus.ast").AstKind

function Compiler:new()
    local obj = {
        instructions = {},
        constants = {},
        functions = {},
        registerCount = 0,
        labelCount = 0,
    }
    setmetatable(obj, {__index = self})
    return obj
end

-- Allocate register
function Compiler:allocateRegister()
    self.registerCount = self.registerCount + 1
    return self.registerCount
end

-- Free register
function Compiler:freeRegister()
    self.registerCount = self.registerCount - 1
end

-- Add constant
function Compiler:addConstant(value)
    for i, const in ipairs(self.constants) do
        if const == value then
            return i - 1
        end
    end
    table.insert(self.constants, value)
    return #self.constants - 1
end

-- Emit instruction
function Compiler:emit(opcode, ...)
    local inst = Instruction:new(opcode, ...)
    table.insert(self.instructions, inst)
    return #self.instructions
end

-- Compile AST node
function Compiler:compileNode(node, target)
    if not node then
        return nil
    end
    
    local kind = node.kind
    
    if kind == AstKind.NumberExpression then
        return self:compileNumber(node, target)
    elseif kind == AstKind.StringExpression then
        return self:compileString(node, target)
    elseif kind == AstKind.BooleanExpression then
        return self:compileBoolean(node, target)
    elseif kind == AstKind.NilExpression then
        return self:compileNil(node, target)
    elseif kind == AstKind.BinaryExpression then
        return self:compileBinary(node, target)
    elseif kind == AstKind.UnaryExpression then
        return self:compileUnary(node, target)
    elseif kind == AstKind.FunctionCallExpression then
        return self:compileFunctionCall(node, target)
    elseif kind == AstKind.VariableExpression then
        return self:compileVariable(node, target)
    elseif kind == AstKind.AssignmentStatement then
        return self:compileAssignment(node)
    elseif kind == AstKind.ReturnStatement then
        return self:compileReturn(node)
    elseif kind == AstKind.IfStatement then
        return self:compileIf(node)
    elseif kind == AstKind.WhileStatement then
        return self:compileWhile(node)
    elseif kind == AstKind.Block then
        return self:compileBlock(node)
    else
        error("Unsupported AST node kind: " .. tostring(kind))
    end
end

-- Compile number
function Compiler:compileNumber(node, target)
    target = target or self:allocateRegister()
    local constIndex = self:addConstant(node.value)
    self:emit(Opcode.LOADK, target, constIndex)
    return target
end

-- Compile string
function Compiler:compileString(node, target)
    target = target or self:allocateRegister()
    local constIndex = self:addConstant(node.value)
    self:emit(Opcode.LOADK, target, constIndex)
    return target
end

-- Compile boolean
function Compiler:compileBoolean(node, target)
    target = target or self:allocateRegister()
    self:emit(Opcode.LOADBOOL, target, node.value and 1 or 0, 0)
    return target
end

-- Compile nil
function Compiler:compileNil(node, target)
    target = target or self:allocateRegister()
    self:emit(Opcode.LOADNIL, target, 0)
    return target
end

-- Compile binary operation
function Compiler:compileBinary(node, target)
    target = target or self:allocateRegister()
    
    local left = self:compileNode(node.left)
    local right = self:compileNode(node.right)
    
    local opcodeMap = {
        ["+"] = Opcode.ADD,
        ["-"] = Opcode.SUB,
        ["*"] = Opcode.MUL,
        ["/"] = Opcode.DIV,
        ["%"] = Opcode.MOD,
        ["^"] = Opcode.POW,
        ["=="] = Opcode.EQ,
        ["<"] = Opcode.LT,
        ["<="] = Opcode.LE,
        [".."] = Opcode.CONCAT,
    }
    
    local opcode = opcodeMap[node.operator]
    if not opcode then
        error("Unsupported binary operator: " .. node.operator)
    end
    
    self:emit(opcode, target, left, right)
    self:freeRegister()
    self:freeRegister()
    
    return target
end

-- Compile unary operation
function Compiler:compileUnary(node, target)
    target = target or self:allocateRegister()
    
    local operand = self:compileNode(node.operand)
    
    local opcodeMap = {
        ["-"] = Opcode.UNM,
        ["not"] = Opcode.NOT,
        ["#"] = Opcode.LEN,
    }
    
    local opcode = opcodeMap[node.operator]
    if not opcode then
        error("Unsupported unary operator: " .. node.operator)
    end
    
    self:emit(opcode, target, operand)
    self:freeRegister()
    
    return target
end

-- Compile function call
function Compiler:compileFunctionCall(node, target)
    target = target or self:allocateRegister()
    
    local func = self:compileNode(node.base)
    
    -- Compile arguments
    local argStart = self.registerCount + 1
    for i, arg in ipairs(node.arguments) do
        self:compileNode(arg)
    end
    
    local argCount = #node.arguments
    self:emit(Opcode.CALL, func, argCount + 1, 2) -- +1 for function, 2 for 1 return value
    
    -- Move result to target if needed
    if func ~= target then
        self:emit(Opcode.MOVE, target, func)
    end
    
    return target
end

-- Compile variable access
function Compiler:compileVariable(node, target)
    target = target or self:allocateRegister()
    local constIndex = self:addConstant(node.name)
    self:emit(Opcode.GETGLOBAL, target, constIndex)
    return target
end

-- Compile assignment
function Compiler:compileAssignment(node)
    for i, var in ipairs(node.variables) do
        local value = node.expressions[i]
        if value then
            local valueReg = self:compileNode(value)
            local constIndex = self:addConstant(var.name)
            self:emit(Opcode.SETGLOBAL, valueReg, constIndex)
            self:freeRegister()
        end
    end
end

-- Compile return statement
function Compiler:compileReturn(node)
    if #node.expressions > 0 then
        local resultReg = self:compileNode(node.expressions[1])
        self:emit(Opcode.RETURN, resultReg, 2) -- Return 1 value
        self:freeRegister()
    else
        self:emit(Opcode.RETURN, 0, 1) -- Return nothing
    end
end

-- Compile if statement
function Compiler:compileIf(node)
    local testReg = self:compileNode(node.condition)
    self:emit(Opcode.TEST, testReg, 0)
    local jumpToElse = self:emit(Opcode.JMP, 0) -- Placeholder
    self:freeRegister()
    
    -- Then block
    self:compileBlock(node.thenBlock)
    
    local jumpToEnd = self:emit(Opcode.JMP, 0) -- Placeholder
    
    -- Patch jump to else
    local elseStart = #self.instructions + 1
    self.instructions[jumpToElse].args[1] = elseStart - jumpToElse - 1
    
    -- Else block
    if node.elseBlock then
        self:compileBlock(node.elseBlock)
    end
    
    -- Patch jump to end
    local endPos = #self.instructions + 1
    self.instructions[jumpToEnd].args[1] = endPos - jumpToEnd - 1
end

-- Compile while statement
function Compiler:compileWhile(node)
    local loopStart = #self.instructions + 1
    
    local testReg = self:compileNode(node.condition)
    self:emit(Opcode.TEST, testReg, 0)
    local jumpToEnd = self:emit(Opcode.JMP, 0) -- Placeholder
    self:freeRegister()
    
    -- Loop body
    self:compileBlock(node.body)
    
    -- Jump back to start
    self:emit(Opcode.JMP, loopStart - #self.instructions - 1)
    
    -- Patch jump to end
    local endPos = #self.instructions + 1
    self.instructions[jumpToEnd].args[1] = endPos - jumpToEnd - 1
end

-- Compile block
function Compiler:compileBlock(node)
    for _, statement in ipairs(node.statements) do
        self:compileNode(statement)
    end
end

-- Compile AST to bytecode
function Compiler:compile(ast)
    self:compileNode(ast)
    
    return {
        instructions = self.instructions,
        constants = self.constants,
        functions = self.functions,
    }
end

return Compiler