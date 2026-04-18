local Runtime = {};

function Runtime:new(bytecode)
    local obj = {
        instructions = bytecode.instructions,
        constants = bytecode.constants,
        pc = 1,
        registers = {},
    };
    setmetatable(obj, {__index = self});
    return obj;
end

function Runtime:run()
    return;
end

return Runtime;