-- Opcode Definitions for Custom VM
local Opcode = {
    -- Constant Loading
    LOADK = 0,      -- Load constant
    LOADBOOL = 1,   -- Load boolean
    LOADNIL = 2,    -- Load nil
    
    -- Arithmetic Operations
    ADD = 3,        -- Addition
    SUB = 4,        -- Subtraction
    MUL = 5,        -- Multiplication
    DIV = 6,        -- Division
    MOD = 7,        -- Modulo
    POW = 8,        -- Power
    UNM = 9,        -- Unary minus
    
    -- Logical Operations
    NOT = 10,       -- Logical NOT
    LEN = 11,       -- Length operator
    
    -- Comparison Operations
    EQ = 12,        -- Equal
    LT = 13,        -- Less than
    LE = 14,        -- Less or equal
    
    -- Table Operations
    NEWTABLE = 15,  -- Create new table
    GETTABLE = 16,  -- Get table value
    SETTABLE = 17,  -- Set table value
    GETGLOBAL = 18, -- Get global variable
    SETGLOBAL = 19, -- Set global variable
    
    -- Function Operations
    CALL = 20,      -- Function call
    RETURN = 21,    -- Return from function
    CLOSURE = 22,   -- Create closure
    
    -- Control Flow
    JMP = 23,       -- Unconditional jump
    FORPREP = 24,   -- For loop preparation
    FORLOOP = 25,   -- For loop iteration
    TEST = 26,      -- Conditional test
    
    -- Variable Operations
    MOVE = 27,      -- Move value between registers
    GETUPVAL = 28,  -- Get upvalue
    SETUPVAL = 29,  -- Set upvalue
    
    -- Concatenation
    CONCAT = 30,    -- String concatenation
    
    -- Vararg
    VARARG = 31,    -- Variable arguments
    
    -- Advanced
    SELF = 32,      -- Method call setup
    TAILCALL = 33,  -- Tail call optimization
    TFORLOOP = 34,  -- Generic for loop
    SETLIST = 35,   -- Set list of values
    CLOSE = 36,     -- Close upvalues
}

-- Opcode Metadata
local OpcodeInfo = {
    [Opcode.LOADK] = {name = "LOADK", args = 2},
    [Opcode.LOADBOOL] = {name = "LOADBOOL", args = 3},
    [Opcode.LOADNIL] = {name = "LOADNIL", args = 2},
    [Opcode.ADD] = {name = "ADD", args = 3},
    [Opcode.SUB] = {name = "SUB", args = 3},
    [Opcode.MUL] = {name = "MUL", args = 3},
    [Opcode.DIV] = {name = "DIV", args = 3},
    [Opcode.MOD] = {name = "MOD", args = 3},
    [Opcode.POW] = {name = "POW", args = 3},
    [Opcode.UNM] = {name = "UNM", args = 2},
    [Opcode.NOT] = {name = "NOT", args = 2},
    [Opcode.LEN] = {name = "LEN", args = 2},
    [Opcode.EQ] = {name = "EQ", args = 3},
    [Opcode.LT] = {name = "LT", args = 3},
    [Opcode.LE] = {name = "LE", args = 3},
    [Opcode.NEWTABLE] = {name = "NEWTABLE", args = 3},
    [Opcode.GETTABLE] = {name = "GETTABLE", args = 3},
    [Opcode.SETTABLE] = {name = "SETTABLE", args = 3},
    [Opcode.GETGLOBAL] = {name = "GETGLOBAL", args = 2},
    [Opcode.SETGLOBAL] = {name = "SETGLOBAL", args = 2},
    [Opcode.CALL] = {name = "CALL", args = 3},
    [Opcode.RETURN] = {name = "RETURN", args = 2},
    [Opcode.CLOSURE] = {name = "CLOSURE", args = 2},
    [Opcode.JMP] = {name = "JMP", args = 1},
    [Opcode.FORPREP] = {name = "FORPREP", args = 2},
    [Opcode.FORLOOP] = {name = "FORLOOP", args = 2},
    [Opcode.TEST] = {name = "TEST", args = 2},
    [Opcode.MOVE] = {name = "MOVE", args = 2},
    [Opcode.GETUPVAL] = {name = "GETUPVAL", args = 2},
    [Opcode.SETUPVAL] = {name = "SETUPVAL", args = 2},
    [Opcode.CONCAT] = {name = "CONCAT", args = 3},
    [Opcode.VARARG] = {name = "VARARG", args = 2},
    [Opcode.SELF] = {name = "SELF", args = 3},
    [Opcode.TAILCALL] = {name = "TAILCALL", args = 3},
    [Opcode.TFORLOOP] = {name = "TFORLOOP", args = 2},
    [Opcode.SETLIST] = {name = "SETLIST", args = 3},
    [Opcode.CLOSE] = {name = "CLOSE", args = 1},
}

return {
    Opcode = Opcode,
    OpcodeInfo = OpcodeInfo,
}