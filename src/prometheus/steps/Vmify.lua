-- Vmify Step - Updated
local Step = require("prometheus.step");
local Ast = require("prometheus.ast");
local Compiler = require("prometheus.vm.Compiler");
local Runtime = require("prometheus.vm.Runtime");
local logger = require("prometheus.logger");

local Vmify = Step:extend();
Vmify.Name = "Vmify";
Vmify.Description = "Compiles the AST to bytecode and wraps it in a VM runtime";

function Vmify:init(settings)
    -- Initialize settings
end

function Vmify:apply(ast, pipeline)
    logger:info("Compiling AST to VM bytecode...");
    
    -- Create compiler
    local compiler = Compiler:new()
    
    -- Compile AST to bytecode
    local bytecode = compiler:compile(ast)
    
    logger:info("Generated " .. #bytecode.instructions .. " instructions");
    logger:info("Generated " .. #bytecode.constants .. " constants");
    
    -- Serialize bytecode
    local serialized = self:serializeBytecode(bytecode)
    
    -- Create wrapper code that loads and runs the VM
    local wrapperCode = self:generateWrapper(serialized)
    
    -- Parse wrapper code back to AST
    local Parser = require("prometheus.parser");
    local parser = Parser:new({
        LuaVersion = pipeline.LuaVersion
    });
    
    local wrappedAst = parser:parse(wrapperCode);
    
    return wrappedAst;
end

function Vmify:serializeBytecode(bytecode)
    -- Serialize instructions
    local instructions = {}
    for _, inst in ipairs(bytecode.instructions) do
        table.insert(instructions, inst:encode())
    end
    
    -- Create serialized structure
    local serialized = {
        code = {},
        constants = bytecode.constants,
        functions = bytecode.functions,
    }
    
    -- Flatten instructions
    for _, inst in ipairs(instructions) do
        for _, byte in ipairs(inst) do
            table.insert(serialized.code, byte)
        end
    end
    
    -- Convert to string
    local function tableToString(t)
        if type(t) ~= "table" then
            if type(t) == "string" then
                return string.format("%q", t)
            else
                return tostring(t)
            end
        end
        
        local result = "{"
        for i, v in ipairs(t) do
            if i > 1 then result = result .. "," end
            result = result .. tableToString(v)
        end
        result = result .. "}"
        return result
    end
    
    return string.format([[{
        code = %s,
        constants = %s,
        functions = %s
    }]], tableToString(serialized.code), tableToString(serialized.constants), tableToString(serialized.functions))
end

function Vmify:generateWrapper(serializedBytecode)
    -- Generate VM runtime embedding code
    local runtimeCode = self:embedRuntime()
    
    return string.format([[
%s

-- Bytecode
local bytecode = %s

-- Deserialize and run
local Deserializer = VM.Deserializer
local Runtime = VM.Runtime

local deserializer = Deserializer:new()
local bytecodeObj = deserializer:deserialize(%q)

local runtime = Runtime:new(bytecodeObj)
return runtime:run()
]], runtimeCode, serializedBytecode, serializedBytecode)
end

function Vmify:embedRuntime()
    -- Embed entire VM runtime as string
    -- In production, you'd read these from files
    local files = {
        "prometheus.vm.Opcode",
        "prometheus.vm.Instruction",
        "prometheus.vm.Compiler",
        "prometheus.vm.Runtime",
        "prometheus.vm.Deserializer",
    }
    
    local embedded = "local VM = {}\n"
    
    for _, moduleName in ipairs(files) do
        local module = require(moduleName)
        -- Serialize module (simplified - in production use proper serialization)
        embedded = embedded .. string.format("VM.%s = ...\n", moduleName:match("[^.]+$"))
    end
    
    return embedded
end

return Vmify;