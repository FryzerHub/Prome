-- prometheus/vm/compiler.lua
-- VM Bytecode Compiler - Converts AST to custom bytecode instructions

local VMCompiler = {}
VMCompiler.__index = VMCompiler

-- Comprehensive Opcode Set
local Opcodes = {
    -- === Stack Operations ===
    LOADK = 0x01,      -- Load constant to stack
    LOADNIL = 0x02,    -- Push nil
    LOADBOOL = 0x03,   -- Push boolean (operand: 0=false, 1=true)
    LOADNUM = 0x04,    -- Load number literal
    
    -- === Arithmetic Operations ===
    ADD = 0x10,        -- a + b
    SUB = 0x11,        -- a - b
    MUL = 0x12,        -- a * b
    DIV = 0x13,        -- a / b
    MOD = 0x14,        -- a % b
    POW = 0x15,        -- a ^ b
    UNM = 0x16,        -- -a (unary minus)
    
    -- === Comparison Operations ===
    EQ = 0x20,         -- a == b
    NE = 0x21,         -- a ~= b
    LT = 0x22,         -- a < b
    GT = 0x23,         -- a > b
    LE = 0x24,         -- a <= b
    GE = 0x25,         -- a >= b
    
    -- === Logical Operations ===
    NOT = 0x30,        -- not a
    AND = 0x31,        -- a and b
    OR = 0x32,         -- a or b
    
    -- === Variable Operations ===
    GETGLOBAL = 0x40,  -- Get global variable (operand: const index)
    SETGLOBAL = 0x41,  -- Set global variable
    GETLOCAL = 0x42,   -- Get local variable (operand: local index)
    SETLOCAL = 0x43,   -- Set local variable
    GETUPVAL = 0x44,   -- Get upvalue
    SETUPVAL = 0x45,   -- Set upvalue
    
    -- === Table Operations ===
    NEWTABLE = 0x50,   -- Create new table
    GETTABLE = 0x51,   -- table[key]
    SETTABLE = 0x52,   -- table[key] = value
    SETLIST = 0x53,    -- Set table list
    
    -- === Function Operations ===
    CLOSURE = 0x60,    -- Create closure
    CALL = 0x61,       -- Function call (operand: arg count)
    RETURN = 0x62,     -- Return from function
    VARARG = 0x63,     -- Handle ... (varargs)
    
    -- === Control Flow ===
    JMP = 0x70,        -- Unconditional jump (operand: offset)
    JMPT = 0x71,       -- Jump if true
    JMPF = 0x72,       -- Jump if false
    JMPNIL = 0x73,     -- Jump if nil
    
    -- === Loop Operations ===
    FORPREP = 0x80,    -- Prepare numeric for loop
    FORLOOP = 0x81,    -- Iterate numeric for loop
    TFORPREP = 0x82,   -- Prepare generic for loop
    TFORLOOP = 0x83,   -- Iterate generic for loop
    
    -- === String Operations ===
    CONCAT = 0x90,     -- String concatenation
    LEN = 0x91,        -- Length operator (#)
    
    -- === Advanced Operations ===
    DUP = 0xA0,        -- Duplicate top of stack
    POP = 0xA1,        -- Pop top of stack
    SWAP = 0xA2,       -- Swap top two stack items
    
    -- === Special Operations ===
    NOP = 0xF0,        -- No operation (for padding)
    HALT = 0xFF,       -- Stop execution
}

function VMCompiler.new(config)
    local self = setmetatable({}, VMCompiler)
    
    self.config = config or {}
    self.instructions = {}
    self.constants = {}
    self.functions = {}
    self.debugInfo = {}
    
    -- Scope management
    self.scopes = {}
    self.currentScope = nil
    self.localCount = 0
    self.upvalueCount = 0
    
    -- Jump tracking
    self.jumps = {}
    self.labels = {}
    
    return self
end

-- === Scope Management ===

function VMCompiler:pushScope()
    local scope = {
        locals = {},
        parent = self.currentScope,
        startPC = #self.instructions
    }
    table.insert(self.scopes, scope)
    self.currentScope = scope
end

function VMCompiler:popScope()
    if #self.scopes > 0 then
        table.remove(self.scopes)
        self.currentScope = self.scopes[#self.scopes]
    end
end

function VMCompiler:registerLocal(name)
    if not self.currentScope then
        self:pushScope()
    end
    
    local index = #self.currentScope.locals
    table.insert(self.currentScope.locals, {
        name = name,
        index = index,
        startPC = #self.instructions
    })
    
    return index
end

function VMCompiler:findLocal(name)
    local scope = self.currentScope
    while scope do
        for i = #scope.locals, 1, -1 do
            if scope.locals[i].name == name then
                return scope.locals[i].index
            end
        end
        scope = scope.parent
    end
    return nil
end

-- === Constant Pool Management ===

function VMCompiler:addConstant(value)
    -- Check if constant already exists
    for i, const in ipairs(self.constants) do
        if const == value then
            return i - 1
        end
    end
    
    -- Add new constant
    table.insert(self.constants, value)
    return #self.constants - 1
end

-- === Instruction Emission ===

function VMCompiler:emit(opcode, operand, aux)
    local instruction = {
        opcode = opcode,
        operand = operand or 0,
        aux = aux or 0,
        pc = #self.instructions
    }
    
    table.insert(self.instructions, instruction)
    return #self.instructions - 1
end

function VMCompiler:emitJump(opcode)
    return self:emit(opcode, 0xFFFF) -- Placeholder
end

function VMCompiler:patchJump(instructionIndex, target)
    if not target then
        target = #self.instructions
    end
    
    local offset = target - instructionIndex - 1
    self.instructions[instructionIndex + 1].operand = offset
end

-- === Main Compilation Entry ===

function VMCompiler:compile(ast)
    -- Initialize root scope
    self:pushScope()
    
    -- Visit the AST
    if ast.kind == "Block" or ast.kind == "Chunk" then
        self:visitBlock(ast)
    else
        error("Invalid AST root: expected Block or Chunk, got " .. (ast.kind or "nil"))
    end
    
    -- Add HALT instruction
    self:emit(Opcodes.HALT)
    
    -- Pop root scope
    self:popScope()
    
    -- Return compiled bytecode
    return {
        version = "1.0.0",
        opcodes = Opcodes,
        instructions = self.instructions,
        constants = self.constants,
        functions = self.functions,
        debugInfo = self.debugInfo,
        metadata = {
            timestamp = os.time(),
            instructionCount = #self.instructions,
            constantCount = #self.constants,
        }
    }
end

-- === Block Compilation ===

function VMCompiler:visitBlock(block)
    local statements = block.statements or block.body or {}
    
    for _, statement in ipairs(statements) do
        self:visitStatement(statement)
    end
end

-- === Statement Compilation ===

function VMCompiler:visitStatement(stmt)
    if not stmt or not stmt.kind then
        return
    end
    
    local stmtType = stmt.kind
    
    if stmtType == "LocalVariableDeclaration" or stmtType == "LocalStatement" then
        self:compileLocalDeclaration(stmt)
        
    elseif stmtType == "AssignmentStatement" or stmtType == "Assignment" then
        self:compileAssignment(stmt)
        
    elseif stmtType == "FunctionCallStatement" or stmtType == "CallStatement" then
        self:compileFunctionCall(stmt)
        
    elseif stmtType == "IfStatement" or stmtType == "If" then
        self:compileIfStatement(stmt)
        
    elseif stmtType == "WhileStatement" or stmtType == "While" then
        self:compileWhileLoop(stmt)
        
    elseif stmtType == "RepeatStatement" or stmtType == "Repeat" then
        self:compileRepeatLoop(stmt)
        
    elseif stmtType == "ForStatement" or stmtType == "NumericFor" then
        self:compileNumericForLoop(stmt)
        
    elseif stmtType == "ForInStatement" or stmtType == "GenericFor" then
        self:compileGenericForLoop(stmt)
        
    elseif stmtType == "ReturnStatement" or stmtType == "Return" then
        self:compileReturn(stmt)
        
    elseif stmtType == "BreakStatement" or stmtType == "Break" then
        self:compileBreak(stmt)
        
    elseif stmtType == "DoStatement" or stmtType == "Do" then
        self:pushScope()
        self:visitBlock(stmt.body or stmt.block)
        self:popScope()
        
    elseif stmtType == "FunctionDeclaration" then
        self:compileFunctionDeclaration(stmt)
    end
end

-- === Local Variable Declaration ===

function VMCompiler:compileLocalDeclaration(stmt)
    local variables = stmt.variables or stmt.names or {}
    local initializers = stmt.init or stmt.values or {}
    
    for i, var in ipairs(variables) do
        local varName = var.name or var
        local localIdx = self:registerLocal(varName)
        
        if initializers[i] then
            -- Compile initializer expression
            self:visitExpression(initializers[i])
            -- Store in local
            self:emit(Opcodes.SETLOCAL, localIdx)
        else
            -- Initialize to nil
            self:emit(Opcodes.LOADNIL)
            self:emit(Opcodes.SETLOCAL, localIdx)
        end
    end
end

-- === Assignment Statement ===

function VMCompiler:compileAssignment(stmt)
    local lhs = stmt.lhs or stmt.variables or {}
    local rhs = stmt.rhs or stmt.values or {}
    
    -- Compile all right-hand side expressions
    for i, expr in ipairs(rhs) do
        self:visitExpression(expr)
    end
    
    -- Assign to left-hand side variables (reverse order)
    for i = #lhs, 1, -1 do
        local var = lhs[i]
        
        if var.kind == "VariableExpression" or var.kind == "Identifier" then
            local varName = var.name or var.value
            local localIdx = self:findLocal(varName)
            
            if localIdx then
                self:emit(Opcodes.SETLOCAL, localIdx)
            else
                -- Global variable
                local constIdx = self:addConstant(varName)
                self:emit(Opcodes.SETGLOBAL, constIdx)
            end
            
        elseif var.kind == "IndexExpression" or var.kind == "Index" then
            -- table[key] = value
            self:visitExpression(var.base)
            self:visitExpression(var.index)
            self:emit(Opcodes.SETTABLE)
        end
    end
end

-- === Function Call ===

function VMCompiler:compileFunctionCall(stmt)
    local expr = stmt.expression or stmt
    
    -- Compile function expression
    if expr.base then
        self:visitExpression(expr.base)
    elseif expr.func then
        self:visitExpression(expr.func)
    end
    
    -- Compile arguments
    local args = expr.arguments or expr.args or {}
    local argCount = 0
    
    for _, arg in ipairs(args) do
        self:visitExpression(arg)
        argCount = argCount + 1
    end
    
    -- Emit CALL instruction
    self:emit(Opcodes.CALL, argCount)
    
    -- Pop return value if statement (not expression)
    if stmt.kind == "FunctionCallStatement" or stmt.kind == "CallStatement" then
        self:emit(Opcodes.POP)
    end
end

-- === If Statement ===

function VMCompiler:compileIfStatement(stmt)
    -- Compile condition
    self:visitExpression(stmt.condition or stmt.test)
    
    -- Jump if false
    local elseJump = self:emitJump(Opcodes.JMPF)
    
    -- Then branch
    self:pushScope()
    self:visitBlock(stmt.body or stmt.consequent)
    self:popScope()
    
    if stmt.elseBlock or stmt.alternate then
        -- Jump over else
        local endJump = self:emitJump(Opcodes.JMP)
        
        -- Patch else jump
        self:patchJump(elseJump)
        
        -- Else branch
        if stmt.elseBlock then
            if stmt.elseBlock.kind == "IfStatement" then
                self:compileIfStatement(stmt.elseBlock)
            else
                self:pushScope()
                self:visitBlock(stmt.elseBlock)
                self:popScope()
            end
        elseif stmt.alternate then
            self:pushScope()
            self:visitBlock(stmt.alternate)
            self:popScope()
        end
        
        -- Patch end jump
        self:patchJump(endJump)
    else
        -- No else branch, just patch the jump
        self:patchJump(elseJump)
    end
end

-- === While Loop ===

function VMCompiler:compileWhileLoop(stmt)
    local loopStart = #self.instructions
    
    -- Compile condition
    self:visitExpression(stmt.condition or stmt.test)
    
    -- Jump if false (exit loop)
    local exitJump = self:emitJump(Opcodes.JMPF)
    
    -- Loop body
    self:pushScope()
    self:visitBlock(stmt.body or stmt.block)
    self:popScope()
    
    -- Jump back to start
    local offset = loopStart - #self.instructions - 1
    self:emit(Opcodes.JMP, offset)
    
    -- Patch exit jump
    self:patchJump(exitJump)
end

-- === Repeat Loop ===

function VMCompiler:compileRepeatLoop(stmt)
    local loopStart = #self.instructions
    
    -- Loop body
    self:pushScope()
    self:visitBlock(stmt.body or stmt.block)
    
    -- Compile condition
    self:visitExpression(stmt.condition or stmt.test)
    
    self:popScope()
    
    -- Jump if false (continue loop)
    local offset = loopStart - #self.instructions - 1
    self:emit(Opcodes.JMPF, offset)
end

-- === Numeric For Loop ===

function VMCompiler:compileNumericForLoop(stmt)
    self:pushScope()
    
    -- Register loop variable
    local varName = stmt.variable.name or stmt.variable
    local varIdx = self:registerLocal(varName)
    
    -- Compile start, stop, step
    self:visitExpression(stmt.start or stmt.init)
    self:visitExpression(stmt.stop or stmt.limit)
    
    if stmt.step then
        self:visitExpression(stmt.step)
    else
        self:emit(Opcodes.LOADK, self:addConstant(1))
    end
    
    -- FORPREP
    local prepPC = #self.instructions
    self:emit(Opcodes.FORPREP, varIdx)
    
    -- Loop body
    local loopStart = #self.instructions
    self:visitBlock(stmt.body or stmt.block)
    
    -- FORLOOP (jump back)
    local offset = loopStart - #self.instructions - 1
    self:emit(Opcodes.FORLOOP, offset)
    
    -- Patch FORPREP to jump to end
    self:patchJump(prepPC)
    
    self:popScope()
end

-- === Generic For Loop ===

function VMCompiler:compileGenericForLoop(stmt)
    self:pushScope()
    
    -- Register loop variables
    local variables = stmt.variables or stmt.names or {}
    for _, var in ipairs(variables) do
        local varName = var.name or var
        self:registerLocal(varName)
    end
    
    -- Compile iterators
    local iterators = stmt.iterators or stmt.values or {}
    for _, iter in ipairs(iterators) do
        self:visitExpression(iter)
    end
    
    -- TFORPREP
    local prepPC = #self.instructions
    self:emit(Opcodes.TFORPREP, #variables)
    
    -- Loop body
    local loopStart = #self.instructions
    self:visitBlock(stmt.body or stmt.block)
    
    -- TFORLOOP (jump back)
    local offset = loopStart - #self.instructions - 1
    self:emit(Opcodes.TFORLOOP, offset)
    
    -- Patch TFORPREP
    self:patchJump(prepPC)
    
    self:popScope()
end

-- === Return Statement ===

function VMCompiler:compileReturn(stmt)
    local values = stmt.arguments or stmt.values or {}
    
    if #values > 0 then
        for _, value in ipairs(values) do
            self:visitExpression(value)
        end
    else
        self:emit(Opcodes.LOADNIL)
    end
    
    self:emit(Opcodes.RETURN, #values)
end

-- === Break Statement ===

function VMCompiler:compileBreak(stmt)
    -- Will be patched later to jump to loop end
    self:emitJump(Opcodes.JMP)
end

-- === Function Declaration ===

function VMCompiler:compileFunctionDeclaration(stmt)
    -- Create new compiler for function
    local funcCompiler = VMCompiler.new(self.config)
    
    -- Compile function body
    funcCompiler:pushScope()
    
    -- Register parameters
    local params = stmt.parameters or stmt.params or {}
    for _, param in ipairs(params) do
        funcCompiler:registerLocal(param.name or param)
    end
    
    -- Compile body
    funcCompiler:visitBlock(stmt.body or stmt.block)
    
    funcCompiler:popScope()
    
    -- Get compiled function
    local funcBytecode = funcCompiler:compile({kind = "Block", statements = {}})
    
    -- Add to functions table
    local funcIdx = #self.functions
    table.insert(self.functions, funcBytecode)
    
    -- Create closure
    self:emit(Opcodes.CLOSURE, funcIdx)
    
    -- Assign to variable
    if stmt.name then
        if stmt.isLocal then
            local localIdx = self:registerLocal(stmt.name.name)
            self:emit(Opcodes.SETLOCAL, localIdx)
        else
            local constIdx = self:addConstant(stmt.name.name)
            self:emit(Opcodes.SETGLOBAL, constIdx)
        end
    end
end

-- === Expression Compilation ===

function VMCompiler:visitExpression(expr)
    if not expr or not expr.kind then
        self:emit(Opcodes.LOADNIL)
        return
    end
    
    local exprType = expr.kind
    
    if exprType == "NumberExpression" or exprType == "Number" then
        local constIdx = self:addConstant(tonumber(expr.value))
        self:emit(Opcodes.LOADK, constIdx)
        
    elseif exprType == "StringExpression" or exprType == "String" then
        local value = expr.value
        -- Remove quotes if present
        if type(value) == "string" then
            value = value:match('^"(.*)"$') or value:match("^'(.*)'$") or value
        end
        local constIdx = self:addConstant(value)
        self:emit(Opcodes.LOADK, constIdx)
        
    elseif exprType == "BooleanExpression" or exprType == "Boolean" then
        self:emit(Opcodes.LOADBOOL, expr.value and 1 or 0)
        
    elseif exprType == "NilExpression" or exprType == "Nil" then
        self:emit(Opcodes.LOADNIL)
        
    elseif exprType == "VariableExpression" or exprType == "Identifier" then
        local varName = expr.name or expr.value
        local localIdx = self:findLocal(varName)
        
        if localIdx then
            self:emit(Opcodes.GETLOCAL, localIdx)
        else
            local constIdx = self:addConstant(varName)
            self:emit(Opcodes.GETGLOBAL, constIdx)
        end
        
    elseif exprType == "BinaryExpression" or exprType == "BinaryOp" then
        self:compileBinaryExpression(expr)
        
    elseif exprType == "UnaryExpression" or exprType == "UnaryOp" then
        self:compileUnaryExpression(expr)
        
    elseif exprType == "TableConstructorExpression" or exprType == "Table" then
        self:compileTableConstructor(expr)
        
    elseif exprType == "IndexExpression" or exprType == "Index" then
        self:visitExpression(expr.base)
        self:visitExpression(expr.index)
        self:emit(Opcodes.GETTABLE)
        
    elseif exprType == "FunctionCallExpression" or exprType == "Call" then
        self:compileFunctionCall(expr)
        
    else
        -- Unknown expression type, load nil
        self:emit(Opcodes.LOADNIL)
    end
end

-- === Binary Expression ===

function VMCompiler:compileBinaryExpression(expr)
    local op = expr.operator or expr.op
    
    -- Handle short-circuit operators
    if op == "and" then
        self:visitExpression(expr.left)
        self:emit(Opcodes.DUP)
        local skipJump = self:emitJump(Opcodes.JMPF)
        self:emit(Opcodes.POP)
        self:visitExpression(expr.right)
        self:patchJump(skipJump)
        return
        
    elseif op == "or" then
        self:visitExpression(expr.left)
        self:emit(Opcodes.DUP)
        local skipJump = self:emitJump(Opcodes.JMPT)
        self:emit(Opcodes.POP)
        self:visitExpression(expr.right)
        self:patchJump(skipJump)
        return
    end
    
    -- Regular binary operators
    self:visitExpression(expr.left)
    self:visitExpression(expr.right)
    
    if op == "+" then
        self:emit(Opcodes.ADD)
    elseif op == "-" then
        self:emit(Opcodes.SUB)
    elseif op == "*" then
        self:emit(Opcodes.MUL)
    elseif op == "/" then
        self:emit(Opcodes.DIV)
    elseif op == "%" then
        self:emit(Opcodes.MOD)
    elseif op == "^" then
        self:emit(Opcodes.POW)
    elseif op == "==" then
        self:emit(Opcodes.EQ)
    elseif op == "~=" then
        self:emit(Opcodes.NE)
    elseif op == "<" then
        self:emit(Opcodes.LT)
    elseif op == ">" then
        self:emit(Opcodes.GT)
    elseif op == "<=" then
        self:emit(Opcodes.LE)
    elseif op == ">=" then
        self:emit(Opcodes.GE)
    elseif op == ".." then
        self:emit(Opcodes.CONCAT)
    end
end

-- === Unary Expression ===

function VMCompiler:compileUnaryExpression(expr)
    self:visitExpression(expr.operand or expr.argument)
    
    local op = expr.operator or expr.op
    
    if op == "-" then
        self:emit(Opcodes.UNM)
    elseif op == "not" then
        self:emit(Opcodes.NOT)
    elseif op == "#" then
        self:emit(Opcodes.LEN)
    end
end

-- === Table Constructor ===

function VMCompiler:compileTableConstructor(expr)
    self:emit(Opcodes.NEWTABLE)
    
    local entries = expr.entries or expr.fields or {}
    
    for i, entry in ipairs(entries) do
        if entry.type == "KeyedField" or (entry.key and entry.value) then
            -- Key-value pair
            self:emit(Opcodes.DUP) -- Duplicate table
            self:visitExpression(entry.key)
            self:visitExpression(entry.value)
            self:emit(Opcodes.SETTABLE)
        else
            -- Array element
            self:emit(Opcodes.DUP)
            self:emit(Opcodes.LOADK, self:addConstant(i))
            self:visitExpression(entry.value or entry)
            self:emit(Opcodes.SETTABLE)
        end
    end
end

return VMCompiler