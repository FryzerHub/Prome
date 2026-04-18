-- Bytecode Deserializer
local Deserializer = {}
local Instruction = require("prometheus.vm.Instruction")

function Deserializer:new()
    local obj = {}
    setmetatable(obj, {__index = self})
    return obj
end

-- Deserialize bytecode string to bytecode structure
function Deserializer:deserialize(bytecodeString)
    -- This is a simple deserializer
    -- In production, you'd use proper serialization
    local bytecode = loadstring("return " .. bytecodeString)()
    
    local instructions = {}
    local index = 1
    
    while index <= #bytecode.code do
        local inst, nextIndex = Instruction.decode(bytecode.code, index)
        table.insert(instructions, inst)
        index = nextIndex
    end
    
    return {
        instructions = instructions,
        constants = bytecode.constants,
        functions = bytecode.functions or {},
    }
end

return Deserializer