-- ================================================================
-- Opcode Handlers
-- Implementation of each VM instruction
-- ================================================================

local Opcode = {};

-- Opcode definitions (Lua 5.1 standard)
Opcode.MOVE = 0;
Opcode.LOADK = 1;
Opcode.LOADBOOL = 2;
Opcode.LOADNIL = 3;
Opcode.GETUPVAL = 4;
Opcode.GETGLOBAL = 5;
Opcode.GETTABLE = 6;
Opcode.SETGLOBAL = 7;
Opcode.SETUPVAL = 8;
Opcode.SETTABLE = 9;
Opcode.NEWTABLE = 10;
Opcode.SELF = 11;
Opcode.ADD = 12;
Opcode.SUB = 13;
Opcode.MUL = 14;
Opcode.DIV = 15;
Opcode.MOD = 16;
Opcode.POW = 17;
Opcode.UNM = 18;
Opcode.NOT = 19;
Opcode.LEN = 20;
Opcode.CONCAT = 21;
Opcode.JMP = 22;
Opcode.EQ = 23;
Opcode.LT = 24;
Opcode.LE = 25;
Opcode.TEST = 26;
Opcode.TESTSET = 27;
Opcode.CALL = 28;
Opcode.TAILCALL = 29;
Opcode.RETURN = 30;
Opcode.FORLOOP = 31;
Opcode.FORPREP = 32;
Opcode.TFORLOOP = 33;
Opcode.SETLIST = 34;
Opcode.CLOSE = 35;
Opcode.CLOSURE = 36;
Opcode.VARARG = 37;

-- Handler templates
local handlers = {};

handlers[0] = [[ -- MOVE
            Stack[A] = Stack[B]
]];

handlers[1] = [[ -- LOADK
            Stack[A] = Const[Bx]
]];

handlers[2] = [[ -- LOADBOOL
            Stack[A] = B ~= 0
            if C ~= 0 then PC = PC + 1 end
]];

handlers[3] = [[ -- LOADNIL
            for i = A, B do
                Stack[i] = nil
            end
]];

handlers[4] = [[ -- GETUPVAL
            Stack[A] = Upval[B]
]];

handlers[5] = [[ -- GETGLOBAL
            Stack[A] = Env[Const[Bx]]
]];

handlers[6] = [[ -- GETTABLE
            local index = B > 255 and Const[B - 256] or Stack[B]
            Stack[A] = Stack[C][index]
]];

handlers[7] = [[ -- SETGLOBAL
            Env[Const[Bx]] = Stack[A]
]];

handlers[8] = [[ -- SETUPVAL
            Upval[B] = Stack[A]
]];

handlers[9] = [[ -- SETTABLE
            local key = B > 255 and Const[B - 256] or Stack[B]
            local val = C > 255 and Const[C - 256] or Stack[C]
            Stack[A][key] = val
]];

handlers[10] = [[ -- NEWTABLE
            Stack[A] = {}
]];

handlers[11] = [[ -- SELF
            local key = C > 255 and Const[C - 256] or Stack[C]
            Stack[A + 1] = Stack[B]
            Stack[A] = Stack[B][key]
]];

handlers[12] = [[ -- ADD
            local lhs = B > 255 and Const[B - 256] or Stack[B]
            local rhs = C > 255 and Const[C - 256] or Stack[C]
            Stack[A] = lhs + rhs
]];

handlers[13] = [[ -- SUB
            local lhs = B > 255 and Const[B - 256] or Stack[B]
            local rhs = C > 255 and Const[C - 256] or Stack[C]
            Stack[A] = lhs - rhs
]];

handlers[14] = [[ -- MUL
            local lhs = B > 255 and Const[B - 256] or Stack[B]
            local rhs = C > 255 and Const[C - 256] or Stack[C]
            Stack[A] = lhs * rhs
]];

handlers[15] = [[ -- DIV
            local lhs = B > 255 and Const[B - 256] or Stack[B]
            local rhs = C > 255 and Const[C - 256] or Stack[C]
            Stack[A] = lhs / rhs
]];

handlers[16] = [[ -- MOD
            local lhs = B > 255 and Const[B - 256] or Stack[B]
            local rhs = C > 255 and Const[C - 256] or Stack[C]
            Stack[A] = lhs % rhs
]];

handlers[17] = [[ -- POW
            local lhs = B > 255 and Const[B - 256] or Stack[B]
            local rhs = C > 255 and Const[C - 256] or Stack[C]
            Stack[A] = lhs ^ rhs
]];

handlers[18] = [[ -- UNM
            Stack[A] = -Stack[B]
]];

handlers[19] = [[ -- NOT
            Stack[A] = not Stack[B]
]];

handlers[20] = [[ -- LEN
            Stack[A] = #Stack[B]
]];

handlers[21] = [[ -- CONCAT
            local str = ""
            for i = B, C do
                str = str .. tostring(Stack[i])
            end
            Stack[A] = str
]];

handlers[22] = [[ -- JMP
            PC = PC + sBx
]];

handlers[23] = [[ -- EQ
            local lhs = B > 255 and Const[B - 256] or Stack[B]
            local rhs = C > 255 and Const[C - 256] or Stack[C]
            if (lhs == rhs) ~= (A ~= 0) then
                PC = PC + 1
            end
]];

handlers[24] = [[ -- LT
            local lhs = B > 255 and Const[B - 256] or Stack[B]
            local rhs = C > 255 and Const[C - 256] or Stack[C]
            if (lhs < rhs) ~= (A ~= 0) then
                PC = PC + 1
            end
]];

handlers[25] = [[ -- LE
            local lhs = B > 255 and Const[B - 256] or Stack[B]
            local rhs = C > 255 and Const[C - 256] or Stack[C]
            if (lhs <= rhs) ~= (A ~= 0) then
                PC = PC + 1
            end
]];

handlers[26] = [[ -- TEST
            if not not Stack[A] ~= (C ~= 0) then
                PC = PC + 1
            end
]];

handlers[27] = [[ -- TESTSET
            if not not Stack[B] == (C ~= 0) then
                Stack[A] = Stack[B]
            else
                PC = PC + 1
            end
]];

handlers[28] = [[ -- CALL
            local func = Stack[A]
            local args = {}
            if B == 0 then
                for i = A + 1, Top do
                    table.insert(args, Stack[i])
                end
            else
                for i = A + 1, A + B - 1 do
                    table.insert(args, Stack[i])
                end
            end
            
            local results = {func(unpack(args))}
            
            if C == 0 then
                Top = A - 1 + #results
                for i, v in ipairs(results) do
                    Stack[A + i - 1] = v
                end
            elseif C == 1 then
                -- No results
            else
                for i = 1, C - 1 do
                    Stack[A + i - 1] = results[i]
                end
            end
]];

handlers[29] = [[ -- TAILCALL
            local func = Stack[A]
            local args = {}
            if B == 0 then
                for i = A + 1, Top do
                    table.insert(args, Stack[i])
                end
            else
                for i = A + 1, A + B - 1 do
                    table.insert(args, Stack[i])
                end
            end
            return func(unpack(args))
]];

handlers[30] = [[ -- RETURN
            if B == 0 then
                local results = {}
                for i = A, Top do
                    table.insert(results, Stack[i])
                end
                return unpack(results)
            elseif B == 1 then
                return
            else
                local results = {}
                for i = A, A + B - 2 do
                    table.insert(results, Stack[i])
                end
                return unpack(results)
            end
]];

handlers[31] = [[ -- FORLOOP
            local step = Stack[A + 2]
            local idx = Stack[A] + step
            Stack[A] = idx
            
            if step > 0 then
                if idx <= Stack[A + 1] then
                    PC = PC + sBx
                    Stack[A + 3] = idx
                end
            else
                if idx >= Stack[A + 1] then
                    PC = PC + sBx
                    Stack[A + 3] = idx
                end
            end
]];

handlers[32] = [[ -- FORPREP
            Stack[A] = Stack[A] - Stack[A + 2]
            PC = PC + sBx
]];

handlers[33] = [[ -- TFORLOOP
            local func = Stack[A]
            local state = Stack[A + 1]
            local control = Stack[A + 2]
            local results = {func(state, control)}
            
            for i = 1, C do
                Stack[A + 2 + i] = results[i]
            end
            
            if Stack[A + 3] ~= nil then
                Stack[A + 2] = Stack[A + 3]
            else
                PC = PC + 1
            end
]];

handlers[34] = [[ -- SETLIST
            local offset = (C - 1) * 50
            if B == 0 then
                for i = A + 1, Top do
                    Stack[A][offset + i - A] = Stack[i]
                end
            else
                for i = 1, B do
                    Stack[A][offset + i] = Stack[A + i]
                end
            end
]];

handlers[35] = [[ -- CLOSE
            -- Close upvalues
]];

handlers[36] = [[ -- CLOSURE
            Stack[A] = Proto[Bx]
]];

handlers[37] = [[ -- VARARG
            local args = {...}
            if B == 0 then
                for i, v in ipairs(args) do
                    Stack[A + i - 1] = v
                end
                Top = A + #args - 1
            else
                for i = 1, B - 1 do
                    Stack[A + i - 1] = args[i]
                end
            end
]];

-- Get handler code for opcode
function Opcode.getHandler(opcode)
    return handlers[opcode] or [[
            error("Unknown opcode: " .. Opcode)
    ]];
end

return Opcode;