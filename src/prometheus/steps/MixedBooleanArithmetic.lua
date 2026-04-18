-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- MixedBooleanArithmetic.lua
--
-- This Step replaces simple arithmetic with complex boolean expressions (MBA)

local Step = require("prometheus.step");
local Ast = require("prometheus.ast");
local AstKind = Ast.AstKind;
local Visitast = require("prometheus.visitast");

local MBA = Step:extend();
MBA.Name = "Mixed Boolean Arithmetic";
MBA.Description = "Replaces arithmetic with complex boolean algebra expressions";

MBA.SettingsDescriptor = {
    Enabled = {
        type = "boolean",
        default = false,
        description = "Enable mixed boolean arithmetic"
    },
    Intensity = {
        type = "number",
        default = 0.5,
        min = 0,
        max = 1,
        description = "Chance to apply MBA to binary operations"
    }
};

function MBA:init(_) end

local function xorExpr(a, b)
    -- (a ^ b) = (a | b) - (a & b)
    return Ast.BinaryExpression(
        Ast.BinaryExpression(a, Ast.StringExpression("|"), b),
        Ast.StringExpression("-"),
        Ast.BinaryExpression(a, Ast.StringExpression("&"), b)
    );
end

local function addExpr(a, b)
    -- a + b = (a ^ b) + 2 * (a & b)
    return Ast.BinaryExpression(
        xorExpr(a, b),
        Ast.StringExpression("+"),
        Ast.BinaryExpression(
            Ast.NumberExpression(2),
            Ast.StringExpression("*"),
            Ast.BinaryExpression(a, Ast.StringExpression("&"), b)
        )
    );
end

local function subExpr(a, b)
    -- a - b = (a ^ b) - 2 * ((~a) & b)
    -- Since ~ isn't available in Lua 5.1, use alternative form
    return Ast.BinaryExpression(
        xorExpr(a, b),
        Ast.StringExpression("-"),
        Ast.BinaryExpression(
            Ast.NumberExpression(2),
            Ast.StringExpression("*"),
            Ast.BinaryExpression(
                Ast.UnaryExpression(
                    Ast.StringExpression("not"),
                    a
                ),
                Ast.StringExpression("and"),
                b
            )
        )
    );
end

local MBA_FORMS = {
    -- Addition forms  
    ["add_form1"] = function(a, b)
        return addExpr(a, b);
    end;
    
    -- Alternative addition
    ["add_form2"] = function(a, b)
        -- a + b = (a | b) + (a & b)
        return Ast.BinaryExpression(
            Ast.BinaryExpression(a, Ast.StringExpression("|"), b),
            Ast.StringExpression("+"),
            Ast.BinaryExpression(a, Ast.StringExpression("&"), b)
        );
    end;
    
    -- Subtraction form
    ["sub_form1"] = function(a, b)
        return subExpr(a, b);
    end;
};

function MBA:apply(ast, pipeline)
    if not self.Enabled then
        return ast;
    end
    
    local modified = 0;
    
    Visitast(ast.body, {
        BinaryExpression = function(node)
            if math.random() > self.Intensity then
                return;
            end
            
            -- Only apply to arithmetic operations
            if node.operator == AstKind.AddExpression or 
               node.operator == AstKind.StringExpression and node.operator.value == "+" then
                
                local forms = {"add_form1", "add_form2"};
                local form = forms[math.random(1, #forms)];
                modified = modified + 1;
                
                return MBA_FORMS[form](node.left, node.right);
                
            elseif node.operator == AstKind.SubExpression or
                   node.operator == AstKind.StringExpression and node.operator.value == "-" then
                
                modified = modified + 1;
                return MBA_FORMS["sub_form1"](node.left, node.right);
            end
        end;
    });
    
    return ast;
end

return MBA;
