-- ================================================================
-- VM Runtime Generator
-- Creates the virtual machine that executes custom bytecode
-- ================================================================

local VMStrings = {};

-- Generate random variable name
local function generateVariable(length)
    local letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";
    local result = {};
    
    -- First character must be letter
    local rand = math.random(1, #letters);
    table.insert(result, letters:sub(rand, rand));
    
    -- Rest can be letter, digit, or underscore
    for i = 2, length do
        rand = math.random(1, #charset);
        table.insert(result, charset:sub(rand, rand));
    end
    
    return table.concat(result);
end

-- Generate variable map with random names
local function generateVarMap()
    return {
        Instr = generateVariable(math.random(8, 15)),
        Stack = generateVariable(math.random(8, 15)),
        Env = generateVariable(math.random(8, 15)),
        Top = generateVariable(math.random(8, 15)),
        Reg = generateVariable(math.random(8, 15)),
        Const = generateVariable(math.random(8, 15)),
        Proto = generateVariable(math.random(8, 15)),
        Upval = generateVariable(math.random(8, 15)),
        PC = generateVariable(math.random(8, 15)),
        Code = generateVariable(math.random(8, 15)),
        Opcode = generateVariable(math.random(8, 15)),
        A = generateVariable(math.random(8, 15)),
        B = generateVariable(math.random(8, 15)),
        C = generateVariable(math.random(8, 15)),
        Bx = generateVariable(math.random(8, 15)),
        sBx = generateVariable(math.random(8, 15)),
        Deserialize = generateVariable(math.random(10, 18)),
        Execute = generateVariable(math.random(10, 18)),
        Wrap = generateVariable(math.random(10, 18)),
        Decode = generateVariable(math.random(10, 18)),
        BitAnd = generateVariable(math.random(8, 12)),
        BitOr = generateVariable(math.random(8, 12)),
        BitXor = generateVariable(math.random(8, 12)),
        LShift = generateVariable(math.random(8, 12)),
        RShift = generateVariable(math.random(8, 12)),
        Chunk = generateVariable(math.random(8, 15)),
        State = generateVariable(math.random(8, 15)),
    };
end

-- Apply variable mapping to code
local function applyVarMap(code, varMap)
    for old, new in pairs(varMap) do
        -- Use word boundary to avoid partial replacements
        code = code:gsub("%f[%w_]" .. old .. "%f[^%w_]", new);
    end
    return code;
end

-- Generate deserializer function
function VMStrings.generateDeserializer(varMap)
    local template = [[
local function Deserialize(Chunk, Charset)
    local Base = #Charset
    local Decode = {}
    
    for i = 1, Base do
        Decode[Charset:sub(i,i)] = i - 1
    end
    
    local function DecodeNumber(str)
        local result = 0
        for i = 1, #str do
            result = result * Base + Decode[str:sub(i,i)]
        end
        return result
    end
    
    local function DecodeString(encoded)
        local parts = {}
        for part in encoded:gmatch("[^_]+") do
            table.insert(parts, string.char(DecodeNumber(part)))
        end
        return table.concat(parts)
    end
    
    local bytes = {}
    for i = 1, #Chunk do
        local byte = Chunk:sub(i,i)
        if byte:match("%d") then
            table.insert(bytes, tonumber(byte))
        end
    end
    
    -- Decode escaped bytes
    local decoded = {}
    local i = 1
    while i <= #Chunk do
        if Chunk:sub(i,i) == "\\" then
            local numStr = ""
            i = i + 1
            while i <= #Chunk and Chunk:sub(i,i):match("%d") do
                numStr = numStr .. Chunk:sub(i,i)
                i = i + 1
            end
            if #numStr > 0 then
                table.insert(decoded, string.char(tonumber(numStr)))
            end
        else
            i = i + 1
        end
    end
    
    return table.concat(decoded)
end
]];
    
    return applyVarMap(template, varMap);
end

-- Generate VM executor
function VMStrings.generateExecutor(varMap, usedOpcodes)
    local template = [[
local function Execute(Code, Env)
    local Stack = setmetatable({}, {__index = Env})
    local Instr = Code.instructions
    local Const = Code.constants
    local Proto = Code.protos
    local PC = 1
    local Top = 0
    
    -- Bit operations (for Lua 5.1 compatibility)
    local BitAnd = bit and bit.band or function(a,b)
        local result = 0
        local bitval = 1
        while a > 0 and b > 0 do
            if a % 2 == 1 and b % 2 == 1 then
                result = result + bitval
            end
            bitval = bitval * 2
            a = math.floor(a/2)
            b = math.floor(b/2)
        end
        return result
    end
    
    local BitOr = bit and bit.bor or function(a,b)
        local result = 0
        local bitval = 1
        while a > 0 or b > 0 do
            if a % 2 == 1 or b % 2 == 1 then
                result = result + bitval
            end
            bitval = bitval * 2
            a = math.floor(a/2)
            b = math.floor(b/2)
        end
        return result
    end
    
    local RShift = bit and bit.rshift or function(a,b)
        return math.floor(a / (2^b))
    end
    
    local LShift = bit and bit.lshift or function(a,b)
        return a * (2^b)
    end
    
    while true do
        local instr = Instr[PC]
        if not instr then break end
        
        -- Decode instruction
        local Opcode = BitAnd(instr, 0x3F)
        local A = BitAnd(RShift(instr, 6), 0xFF)
        local C = BitAnd(RShift(instr, 14), 0x1FF)
        local B = BitAnd(RShift(instr, 23), 0x1FF)
        local Bx = BitOr(LShift(B, 9), C)
        local sBx = Bx - 131071
        
        PC = PC + 1
        
        -- Opcode dispatch will be inserted here
        __OPCODE_DISPATCH__
    end
    
    return Stack
end
]];
    
    return applyVarMap(template, varMap);
end

-- Generate wrapper function
function VMStrings.generateWrapper(varMap)
    local template = [[
local function Wrap(Chunk, Charset)
    local code = Deserialize(Chunk, Charset)
    local env = getfenv and getfenv(0) or _ENV
    return function(...)
        return Execute(code, env)
    end
end
]];
    
    return applyVarMap(template, varMap);
end

-- Main generation function
function VMStrings.generate(bytecode, usedOpcodes, config)
    config = config or {};
    
    local varMap = generateVarMap();
    local parts = {};
    
    -- Add obfuscation header
    table.insert(parts, "-- Protected by Prometheus VM");
    table.insert(parts, "-- github.com/prometheus-lua/Prometheus");
    table.insert(parts, "");
    
    -- Generate deserializer
    table.insert(parts, VMStrings.generateDeserializer(varMap));
    table.insert(parts, "");
    
    -- Generate executor with opcode handlers
    local executor = VMStrings.generateExecutor(varMap, usedOpcodes);
    
    -- Insert opcode dispatch
    local opcodeDispatch = VMStrings.generateOpcodeDispatch(varMap, usedOpcodes);
    executor = executor:gsub("__OPCODE_DISPATCH__", opcodeDispatch);
    
    table.insert(parts, executor);
    table.insert(parts, "");
    
    -- Generate wrapper
    table.insert(parts, VMStrings.generateWrapper(varMap));
    table.insert(parts, "");
    
    -- Encode bytecode
    local Encoder = require("prometheus.vm.Encoder");
    local encodedBytecode, charset = Encoder.encode(bytecode);
    
    -- Generate final call
    local finalCall = string.format(
        "return %s('%s', '%s')()",
        varMap.Wrap,
        encodedBytecode,
        charset
    );
    table.insert(parts, finalCall);
    
    return table.concat(parts, "\n");
end

-- Generate opcode dispatch logic
function VMStrings.generateOpcodeDispatch(varMap, usedOpcodes)
    local Opcode = require("prometheus.vm.Opcode");
    local parts = {};
    
    -- Convert to list and shuffle
    local opcodeList = {};
    for opcode, _ in pairs(usedOpcodes) do
        table.insert(opcodeList, opcode);
    end
    
    -- Shuffle for unpredictability
    for i = #opcodeList, 2, -1 do
        local j = math.random(1, i);
        opcodeList[i], opcodeList[j] = opcodeList[j], opcodeList[i];
    end
    
    -- Generate if/elseif chain
    local condition = "if";
    for _, opcode in ipairs(opcodeList) do
        local handler = Opcode.getHandler(opcode);
        local code = applyVarMap(handler, varMap);
        
        table.insert(parts, string.format(
            "        %s Opcode == %d then\n%s",
            condition,
            opcode,
            code
        ));
        
        condition = "elseif";
    end
    
    table.insert(parts, "        end");
    
    return table.concat(parts, "\n");
end

return VMStrings;