-- ================================================================
-- VM-Style Name Generator
-- Generates random names like your VM implementation
-- ================================================================

local NameGenerator = require("prometheus.namegenerator");

local VMStyle = NameGenerator:extend();
VMStyle.Name = "VMStyle";

function VMStyle:init(settings)
    self.settings = settings or {};
    self.minLength = settings.MinLength or 8;
    self.maxLength = settings.MaxLength or 15;
    self.usedNames = {};
end

function VMStyle:generateName(id)
    local letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";
    
    local function generate()
        local length = math.random(self.minLength, self.maxLength);
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
    
    -- Generate unique name
    local name;
    repeat
        name = generate();
    until not self.usedNames[name];
    
    self.usedNames[name] = true;
    return name;
end

return VMStyle;