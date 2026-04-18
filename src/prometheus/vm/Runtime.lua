-- VM Runtime/Interpreter
local Runtime = {}
local Opcode = require("prometheus.vm.Opcode").Opcode

function Runtime:new(bytecode)
    local obj = {
        instructions = bytecode.instructions,
        constants = bytecode.constants,
        pc = 1, -- Program counter
        registers = {},
        stack = {},
        globals = _G,
        upvalues = {},
    }
    setmetatable(obj, {__index = self})
    return obj
end

-- Get register value
function Runtime:getReg(index)
    return self.registers[index]
end

-- Set register value
function Runtime:setReg(index, value)
    self.registers[index] = value
end

-- Get constant value
function Runtime:getConst(index)
    return self.constants[index + 1] -- Lua is 1-indexed
end

-- Execute single instruction
function Runtime:executeInstruction()
    local inst = self.instructions[self.pc]
    if not inst then
        return false -- End of program
    end
    
    local opcode = inst.opcode
    local args = inst.args
    
    if opcode == Opcode.LOADK then
        self:setReg(args[1], self:getConst(args[2]))
    elseif opcode == Opcode.LOADBOOL then
        self:setReg(args[1], args[2] == 1)
    elseif opcode == Opcode.LOADNIL then
        self:setReg(args[1], nil)
    elseif opcode == Opcode.ADD then
        self:setReg(args[1], self:getReg(args[2]) + self:getReg(args[3]))
    elseif opcode == Opcode.SUB then
        self:setReg(args[1], self:getReg(args[2]) - self:getReg(args[3]))
    elseif opcode == Opcode.MUL then
        self:setReg(args[1], self:getReg(args[2]) * self:getReg(args[3]))
    elseif opcode == Opcode.DIV then
        self:setReg(args[1], self:getReg(args[2]) / self:getReg(args[3]))
    elseif opcode == Opcode.MOD then
        self:setReg(args[1], self:getReg(args[2]) % self:getReg(args[3]))
    elseif opcode == Opcode.POW then
        self:setReg(args[1], self:getReg(args[2]) ^ self:getReg(args[3]))
    elseif opcode == Opcode.UNM then
        self:setReg(args[1], -self:getReg(args[2]))
    elseif opcode == Opcode.NOT then
        self:setReg(args[1], not self:getReg(args[2]))
    elseif opcode == Opcode.LEN then
        self:setReg(args[1], #self:getReg(args[2]))
    elseif opcode == Opcode.EQ then
        self:setReg(args[1], self:getReg(args[2]) == self:getReg(args[3]))
    elseif opcode == Opcode.LT then
        self:setReg(args[1], self:getReg(args[2]) < self:getReg(args[3]))
    elseif opcode == Opcode.LE then
        self:setReg(args[1], self:getReg(args[2]) <= self:getReg(args[3]))
    elseif opcode == Opcode.CONCAT then
        self:setReg(args[1], self:getReg(args[2]) .. self:getReg(args[3]))
    elseif opcode == Opcode.MOVE then
        self:setReg(args[1], self:getReg(args[2]))
    elseif opcode == Opcode.GETGLOBAL then
        local name = self:getConst(args[2])
        self:setReg(args[1], self.globals[name])
    elseif opcode == Opcode.SETGLOBAL then
        local name = self:getConst(args[2])
        self.globals[name] = self:getReg(args[1])
    elseif opcode == Opcode.CALL then
        local func = self:getReg(args[1])
        local argCount = args[2] - 1
        local resultCount = args[3] - 1
        
        local callArgs = {}
        for i = 1, argCount do
            table.insert(callArgs, self:getReg(args[1] + i))
        end
        
        local results = {func(table.unpack(callArgs))}
        
        for i = 1, resultCount do
            self:setReg(args[1] + i - 1, results[i])
        end
    elseif opcode == Opcode.RETURN then
        local resultCount = args[2] - 1
        local results = {}
        for i = 0, resultCount - 1 do
            table.insert(results, self:getReg(args[1] + i))
        end
        return true, results
    elseif opcode == Opcode.JMP then
        self.pc = self.pc + args[1]
        return true
    elseif opcode == Opcode.TEST then
        if not self:getReg(args[1]) then
            self.pc = self.pc + 1 -- Skip next instruction (JMP)
        end
    elseif opcode == Opcode.NEWTABLE then
        self:setReg(args[1], {})
    elseif opcode == Opcode.GETTABLE then
        local table_val = self:getReg(args[2])
        local key = self:getReg(args[3])
        self:setReg(args[1], table_val[key])
    elseif opcode == Opcode.SETTABLE then
        local table_val = self:getReg(args[1])
        local key = self:getReg(args[2])
        local value = self:getReg(args[3])
        table_val[key] = value
    else
        error("Unsupported opcode: " .. tostring(opcode))
    end
    
    self.pc = self.pc + 1
    return true
end

-- Run the VM
function Runtime:run()
    while true do
        local continue, result = self:executeInstruction()
        if not continue then
            break
        end
        if result then
            return table.unpack(result)
        end
    end
end

return Runtime