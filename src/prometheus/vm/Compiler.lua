local Compiler = {};

function Compiler:new()
    local obj = {
        instructions = {},
        constants = {},
        registerCount = 0,
    };
    setmetatable(obj, {__index = self});
    return obj;
end

function Compiler:compile(ast)
    return {
        instructions = self.instructions,
        constants = self.constants,
    };
end

return Compiler;