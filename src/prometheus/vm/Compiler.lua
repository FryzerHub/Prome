-- ================================================================
-- VM Compiler - Lua to Custom Bytecode
-- ================================================================

local bit = bit or bit32;
local band = bit.band;
local bor = bit.bor;
local lshift = bit.lshift;
local rshift = bit.rshift;

local Compiler = {};

-- Instruction encoding
local function encodeInstruction(opcode, a, b, c)
    -- Custom instruction format: [Opcode:6][A:8][C:9][B:9]
    local instruction = 0;
    instruction = bor(instruction, band(opcode, 0x3F));
    instruction = bor(instruction, lshift(band(a, 0xFF), 6));
    instruction = bor(instruction, lshift(band(c, 0x1FF), 14));
    instruction = bor(instruction, lshift(band(b, 0x1FF), 23));
    return instruction;
end

-- Parse state
local ParseState = {
    source = "";
    position = 1;
    instructions = {};
    constants = {};
    protos = {};
    registerStack = 0;
    scope = {};
};

function ParseState:new(source)
    local obj = {
        source = source;
        position = 1;
        instructions = {};
        constants = {};
        constantMap = {};
        protos = {};
        registerStack = 0;
        maxStack = 0;
        scopes = {{}};
        localCount = 0;
    };
    setmetatable(obj, {__index = self});
    return obj;
end

function ParseState:addConstant(value)
    local key = tostring(value);
    if self.constantMap[key] then
        return self.constantMap[key];
    end
    
    local index = #self.constants;
    table.insert(self.constants, value);
    self.constantMap[key] = index;
    return index;
end

function ParseState:allocRegister()
    local reg = self.registerStack;
    self.registerStack = self.registerStack + 1;
    if self.registerStack > self.maxStack then
        self.maxStack = self.registerStack;
    end
    return reg;
end

function ParseState:freeRegister()
    self.registerStack = self.registerStack - 1;
end

function ParseState:emit(opcode, a, b, c)
    a = a or 0;
    b = b or 0;
    c = c or 0;
    
    local instr = encodeInstruction(opcode, a, b, c);
    table.insert(self.instructions, instr);
    
    -- Track used opcodes
    if _G.UsedOps then
        _G.UsedOps[opcode] = opcode;
    end
    
    return #self.instructions - 1;
end

-- Simple Lua parser and compiler
function Compiler.compile(source)
    local state = ParseState:new(source);
    
    -- Load the source as a function to get bytecode template
    local func, err = loadstring(source);
    if not func then
        error("Compilation error: " .. tostring(err));
    end
    
    -- Use Lua's built-in compiler then convert to custom format
    local success, result = pcall(string.dump, func);
    if not success then
        error("Failed to dump bytecode: " .. tostring(result));
    end
    
    -- Parse Lua bytecode and convert to custom format
    local customBytecode = Compiler.convertLuaBytecode(result, state);
    
    return customBytecode, state.constants, state.protos;
end

-- Convert standard Lua bytecode to custom format
function Compiler.convertLuaBytecode(luaBytecode, state)
    local output = {};
    local pos = 1;
    
    -- Lua 5.1 bytecode header is 12 bytes
    pos = pos + 12;
    
    -- Helper to read bytes
    local function readByte()
        local b = luaBytecode:byte(pos);
        pos = pos + 1;
        return b;
    end
    
    local function readInt()
        local a, b, c, d = luaBytecode:byte(pos, pos + 3);
        pos = pos + 4;
        return a + b * 256 + c * 65536 + d * 16777216;
    end
    
    -- Read size_t (depends on platform, assume 4 bytes)
    local function readSize()
        return readInt();
    end
    
    -- Skip function header
    local sourceSize = readSize();
    pos = pos + sourceSize;
    
    local lineDefined = readInt();
    local lastLineDefined = readInt();
    local numUpvalues = readByte();
    local numParams = readByte();
    local isVararg = readByte();
    local maxStackSize = readByte();
    
    -- Read instructions
    local codeSize = readInt();
    for i = 1, codeSize do
        local instr = readInt();
        
        -- Decode Lua instruction
        local opcode = band(instr, 0x3F);
        local a = band(rshift(instr, 6), 0xFF);
        local c = band(rshift(instr, 14), 0x1FF);
        local b = band(rshift(instr, 23), 0x1FF);
        local bx = bor(lshift(b, 9), c);
        local sbx = bx - 131071;
        
        -- Convert to custom opcode (can add randomization here)
        local customOp = opcode;
        
        -- Emit custom instruction
        state:emit(customOp, a, b, c);
    end
    
    -- Read constants
    local constSize = readInt();
    for i = 1, constSize do
        local constType = readByte();
        
        if constType == 0 then -- nil
            state:addConstant(nil);
        elseif constType == 1 then -- boolean
            local value = readByte() ~= 0;
            state:addConstant(value);
        elseif constType == 3 then -- number
            -- Read double (8 bytes)
            local bytes = {};
            for j = 1, 8 do
                bytes[j] = readByte();
            end
            -- Simple number reconstruction (not perfect for all cases)
            local num = 0;
            state:addConstant(num);
        elseif constType == 4 then -- string
            local strSize = readSize();
            local str = luaBytecode:sub(pos, pos + strSize - 1);
            pos = pos + strSize;
            state:addConstant(str);
        end
    end
    
    -- Serialize to custom bytecode format
    local serialized = Compiler.serialize(state);
    
    return serialized;
end

-- Serialize compiled bytecode to string
function Compiler.serialize(state)
    local parts = {};
    
    -- Header
    table.insert(parts, string.char(0x1B, 0x4C, 0x75, 0x61)); -- Magic
    table.insert(parts, string.char(0x51)); -- Version 5.1
    table.insert(parts, string.char(0x00)); -- Format
    table.insert(parts, string.char(0x01)); -- Endianness
    table.insert(parts, string.char(0x04)); -- Int size
    table.insert(parts, string.char(0x08)); -- Size_t size
    table.insert(parts, string.char(0x04)); -- Instruction size
    table.insert(parts, string.char(0x08)); -- Number size
    table.insert(parts, string.char(0x00)); -- Integral flag
    
    -- Function info
    local function writeInt(n)
        table.insert(parts, string.char(
            band(n, 0xFF),
            band(rshift(n, 8), 0xFF),
            band(rshift(n, 16), 0xFF),
            band(rshift(n, 24), 0xFF)
        ));
    end
    
    -- Source name
    writeInt(0); -- No source name
    
    writeInt(0); -- Line defined
    writeInt(0); -- Last line defined
    table.insert(parts, string.char(0)); -- Num upvalues
    table.insert(parts, string.char(0)); -- Num params
    table.insert(parts, string.char(2)); -- Vararg flag
    table.insert(parts, string.char(state.maxStack)); -- Max stack
    
    -- Instructions
    writeInt(#state.instructions);
    for _, instr in ipairs(state.instructions) do
        writeInt(instr);
    end
    
    -- Constants
    writeInt(#state.constants);
    for _, const in ipairs(state.constants) do
        local constType = type(const);
        
        if constType == "nil" then
            table.insert(parts, string.char(0));
        elseif constType == "boolean" then
            table.insert(parts, string.char(1));
            table.insert(parts, string.char(const and 1 or 0));
        elseif constType == "number" then
            table.insert(parts, string.char(3));
            -- Write 8-byte double (simplified)
            for i = 1, 8 do
                table.insert(parts, string.char(0));
            end
        elseif constType == "string" then
            table.insert(parts, string.char(4));
            writeInt(#const + 1);
            table.insert(parts, const);
            table.insert(parts, string.char(0));
        end
    end
    
    -- Protos (nested functions)
    writeInt(0);
    
    -- Source line positions
    writeInt(0);
    
    -- Locals
    writeInt(0);
    
    -- Upvalues
    writeInt(0);
    
    return table.concat(parts);
end

return Compiler;