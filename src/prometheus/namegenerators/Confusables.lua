-- ================================================================
-- Confusables Name Generator
-- Uses visually similar Unicode characters
-- ================================================================

local NameGenerator = require("prometheus.namegenerator");

local Confusables = NameGenerator:extend();
Confusables.Name = "Confusables";

-- Characters that look similar to ASCII
local confusableMap = {
    a = {"а", "ɑ", "α"},  -- Cyrillic a, Greek alpha
    e = {"е", "ε"},        -- Cyrillic e, Greek epsilon
    o = {"о", "ο"},        -- Cyrillic o, Greek omicron
    p = {"р", "ρ"},        -- Cyrillic r, Greek rho
    c = {"с"},             -- Cyrillic s
    x = {"х", "χ"},        -- Cyrillic h, Greek chi
    i = {"і", "ι"},        -- Cyrillic i, Greek iota
    l = {"ӏ", "Ι"},        -- Cyrillic palochka
};

function Confusables:init(settings)
    self.settings = settings or {};
    self.counter = 0;
    self.usedNames = {};
end

function Confusables:generateName(id)
    local base = "var";
    local suffix = tostring(self.counter);
    self.counter = self.counter + 1;
    
    -- Mix in confusables
    local result = {};
    for i = 1, #base do
        local char = base:sub(i, i);
        if confusableMap[char] and math.random() > 0.5 then
            local options = confusableMap[char];
            table.insert(result, options[math.random(1, #options)]);
        else
            table.insert(result, char);
        end
    end
    
    table.insert(result, suffix);
    
    local name = table.concat(result);
    self.usedNames[name] = true;
    
    return name;
end

return Confusables;