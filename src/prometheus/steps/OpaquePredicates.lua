-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- OpaquePredicates.lua
--
-- This Step injects opaque predicates (always true/false conditions) into code

local Step = require("prometheus.step");
local Ast = require("prometheus.ast");
local AstKind = Ast.AstKind;
local Visitast = require("prometheus.visitast");
local util = require("prometheus.util");

local OpaquePredicates = Step:extend();
OpaquePredicates.Name = "Opaque Predicates";
OpaquePredicates.Description = "Injects mathematical predicates that are always true/false";

OpaquePredicates.SettingsDescriptor = {
    Enabled = {
        type = "boolean",
        default = false,
        description = "Enable opaque predicates"
    },
    PredicateIntensity = {
        type = "number",
        default = 0.3,
        min = 0,
        max = 1,
        description = "Density of opaque predicates to inject"
    }
};

function OpaquePredicates:init(_) end

local function createAlwaysTruePredicate()
    -- Mathematical invariants that are always true
    local predicates = {
        -- Bit manipulation invariant
        function()
            local x = math.random(1, 1000);
            local y = math.random(1, 1000);
            -- (x | y) >= (x & y) is always true
            return Ast.BinaryExpression(
                Ast.BinaryExpression(
                    Ast.NumberExpression(x),
                    Ast.StringExpression("|"),
                    Ast.NumberExpression(y)
                ),
                Ast.StringExpression(">="),
                Ast.BinaryExpression(
                    Ast.NumberExpression(x),
                    Ast.StringExpression("&"),
                    Ast.NumberExpression(y)
                )
            );
        end;
        
        -- Algebraic invariant
        function()
            local x = math.random(1, 100);
            local y = math.random(1, 100);
            -- (x + y) == ((x - y) + 2*y) is always true
            return Ast.BinaryExpression(
                Ast.BinaryExpression(
                    Ast.NumberExpression(x),
                    Ast.StringExpression("+"),
                    Ast.NumberExpression(y)
                ),
                Ast.StringExpression("=="),
                Ast.BinaryExpression(
                    Ast.BinaryExpression(
                        Ast.BinaryExpression(
                            Ast.NumberExpression(x),
                            Ast.StringExpression("-"),
                            Ast.NumberExpression(y)
                        ),
                        Ast.StringExpression("+"),
                        Ast.BinaryExpression(
                            Ast.NumberExpression(2),
                            Ast.StringExpression("*"),
                            Ast.NumberExpression(y)
                        )
                    ),
                    Ast.StringExpression(""),
                    Ast.NumberExpression(0)
                )
            );
        end;
        
        -- Type check invariant
        function()
            local x = math.random(1, 1000);
            -- (x ~= nil) is always true for numbers
            return Ast.BinaryExpression(
                Ast.NumberExpression(x),
                Ast.StringExpression("~="),
                Ast.NilExpression()
            );
        end;
    };
    
    return predicates[math.random(1, #predicates)]();
end

function OpaquePredicates:apply(ast, pipeline)
    if not self.Enabled then
        return ast;
    end
    
    local rootScope = ast.body.scope;
    local statementCount = 0;
    local injectionCount = 0;
    
    -- Inject predicates into block statements
    local function injectIntoBlock(block)
        if not block.statements then return; end
        
        local newStatements = {};
        
        for i, stmt in ipairs(block.statements) do
            table.insert(newStatements, stmt);
            statementCount = statementCount + 1;
            
            -- Random injection based on intensity
            if math.random() < self.PredicateIntensity then
                local predicate = createAlwaysTruePredicate();
                
                -- Create fake if statement with unreachable else branch
                local emptyBlock = Ast.Block({}, rootScope);
                local fakeStmts = {
                    Ast.AssignmentStatement(
                        {Ast.AssignmentVariable(rootScope, rootScope:addVariable())},
                        {Ast.NumberExpression(0)}
                    )
                };
                fakeStmts.scope = rootScope;
                
                local fakeBlock = Ast.Block(fakeStmts, rootScope);
                trueBlock = Ast.Block({}, rootScope);
                
                local ifStmt = Ast.IfStatement(
                    predicate,
                    trueBlock,
                    fakeBlock
                );
                
                table.insert(newStatements, ifStmt);
                injectionCount = injectionCount + 1;
            end
        end
        
        block.statements = newStatements;
    end
    
    -- Walk through all blocks and inject
    Visitast(ast.body, {
        Block = function(node)
            injectIntoBlock(node);
        end;
    });
    
    return ast;
end

return OpaquePredicates;
