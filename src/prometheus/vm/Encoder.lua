-- ================================================================
-- Bytecode Encoder
-- Encodes bytecode using custom base-N encoding
-- ================================================================

local Encoder = {};

-- Shuffle string characters randomly
local function shuffleString(str)
    local chars = {};
    for i = 1, #str do
        chars[i] = str:sub(i, i);
    end
    
    for i = #chars, 2, -1 do
        local j = math.random(1, i);
        chars[i], chars[j] = chars[j], chars[i];
    end
    
    return table.concat(chars);
end

-- Generate printable character set
local function generateCharset()
    local chars = {};
    
    -- Printable ASCII: 33-126 (excluding some special chars)
    for i = 33, 126 do
        local c = string.char(i);
        -- Exclude quotes, backslash, and some problematic chars
        if c ~= "'" and c ~= '"' and c ~= "\\" and c ~= "`" then
            table.insert(chars, c);
        end
    end
    
    local charset = table.concat(chars);
    return shuffleString(charset);
end

-- Encode number to base-N
local function encodeNumber(n, charset)
    local base = #charset;
    local result = {};
    
    if n == 0 then
        return charset:sub(1, 1);
    end
    
    while n > 0 do
        local remainder = n % base;
        table.insert(result, 1, charset:sub(remainder + 1, remainder + 1));
        n = math.floor(n / base);
    end
    
    return table.concat(result);
end

-- Encode string to escaped format
local function encodeString(str, charset)
    local encoded = {};
    
    for i = 1, #str do
        local byte = str:byte(i);
        table.insert(encoded, encodeNumber(byte, charset));
    end
    
    return table.concat(encoded, "_");
end

-- Encode to escaped byte sequence
local function escapeBytes(str)
    local result = {};
    
    for i = 1, #str do
        local byte = str:byte(i);
        table.insert(result, "\\" .. byte);
    end
    
    return table.concat(result);
end

-- Main encode function
function Encoder.encode(bytecode)
    local charset = generateCharset();
    
    -- First encode the bytecode string
    local encoded = encodeString(bytecode, charset);
    
    -- Then escape it
    local escaped = escapeBytes(encoded);
    
    return escaped, charset;
end

-- Encode charset itself
function Encoder.encodeCharset(charset)
    return escapeBytes(charset);
end

return Encoder;