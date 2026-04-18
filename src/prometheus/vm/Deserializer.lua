local Deserializer = {};

function Deserializer:new()
    local obj = {};
    setmetatable(obj, {__index = self});
    return obj;
end

function Deserializer:deserialize(bytecodeString)
    return {
        instructions = {},
        constants = {},
    };
end

return Deserializer;