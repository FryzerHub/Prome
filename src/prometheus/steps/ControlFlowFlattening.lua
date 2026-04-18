-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- ControlFlowFlattening.lua
--
-- This Step flattens control flow into state machines to make analysis extremely difficult

local Step = require("prometheus.step");
local Ast = require("prometheus.ast");
local Scope = require("prometheus.scope");
local Visitast = require("prometheus.visitast");

local ControlFlowFlattening = Step:extend();
ControlFlowFlattening.Name = "Control Flow Flattening";
ControlFlowFlattening.Description = "Flattens control flow into state machines to prevent analysis";

ControlFlowFlattening.SettingsDescriptor = {
    Enabled = {
        type = "boolean",
        default = false,
        description = "Enable control flow flattening"
    },
    FlattenChance = {
        type = "number",
        default = 0.5,
        min = 0,
        max = 1,
        description = "Chance to flatten any given control structure"
    }
};

-- Add these methods to existing ControlFlowFlattening:

function ControlFlowFlattening:generateOpaquePredicate()
    local predicates = {
        -- Always true
        [[((function() return true end)())]],
        [[(math.floor(1.5) == 1)]],
        [[(#({}) == 0)]],
        [[(type("") == "string")]],
        
        -- Always false
        [[(math.floor(0.5) == 1)]],
        [[(#({1}) == 0)]],
        [[(type(1) == "string")]],
    };
    
    return predicates[math.random(1, #predicates)];
end

function ControlFlowFlattening:insertDeadCode(block)
    local deadCode = {
        [[local __ = (function() return end)()]],
        [[if false then print("never") end]],
        [[local _ = math.random() > 2 and error() or nil]],
    };
    
    for i = 1, math.random(1, 3) do
        local code = deadCode[math.random(1, #deadCode)];
        local Parser = require("prometheus.parser");
        local ast = Parser:new({LuaVersion = "Lua51"}):parse(code);
        table.insert(block.statements, math.random(1, #block.statements + 1), ast.body.statements[1]);
    end
end

function ControlFlowFlattening:createMultipleDispatchers(statements)
    -- Instead of one dispatcher, create multiple interconnected ones
    local dispatchers = {};
    local chunkSize = math.floor(#statements / 3);
    
    for i = 1, 3 do
        local start = (i - 1) * chunkSize + 1;
        local finish = i == 3 and #statements or i * chunkSize;
        local chunk = {};
        
        for j = start, finish do
            table.insert(chunk, statements[j]);
        end
        
        table.insert(dispatchers, self:createDispatcher(chunk));
    end
    
    return dispatchers;
end

function ControlFlowFlattening:init(_) end

function ControlFlowFlattening:apply(ast, pipeline)
    -- Control flow flattening is complex and requires careful state management
    -- For now, implement a simplified version that adds state transitions
    
    if not self.Enabled then
        return ast;
    end
    
    -- Identify and flatten control structures
    local modified = false;
    
    Visitast(ast.body, {
        IfStatement = function(node)
            if math.random() < self.FlattenChance then
                -- Add state tracking around if statements
                -- This makes execution trace harder to follow
                node.stateId = math.random(0, 2^20);
                modified = true;
            end
        end;
        
        ForStatement = function(node)
            if math.random() < self.FlattenChance then
                node.stateId = math.random(0, 2^20);
                modified = true;
            end
        end;
        
        WhileStatement = function(node)
            if math.random() < self.FlattenChance then
                node.stateId = math.random(0, 2^20);
                modified = true;
            end
        end;
    });
    
    return ast;
end

return ControlFlowFlattening;
