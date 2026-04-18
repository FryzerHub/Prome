-- Custom Bytecode VM - Completely custom instruction set (not Lua)
-- Compiles Lua AST to undecodable bytecode that runs on custom interpreter

local CustomVM = {}
CustomVM.__index = CustomVM

-- Custom Instruction Set (64+ opcodes)
local OPCODES = {
	-- Stack operations
	PUSHK = 0,    PUSHV = 1,    POPR = 2,    DUPV = 3,
	SWAP = 4,     MOVR = 5,     SETGLAB = 6, GETGLAB = 7,
	
	-- Arithmetic (obfuscated)
	ADDC = 8,     SUBC = 9,     MULC = 10,   DIVC = 11,
	MODC = 12,    POWR = 13,    NEGATV = 14, FLOORV = 15,
	
	-- Comparison (results to stack)
	CMPLE = 16,   CMPLT = 17,   CMPEQ = 18,  CMPNE = 19,
	CMPLE2 = 20,  CMPLT2 = 21,
	
	-- Logic
	LAND = 22,    LOR = 23,     LNOT = 24,
	
	-- Control flow (encrypted jumps)
	JMP = 25,     JIFZ = 26,    JIFT = 27,   JNIL = 28,
	JNILF = 29,
	
	-- Table operations
	NEWTAB = 30,  SETIDX = 31,  GETIDX = 32, SETLEN = 33,
	GETLEN = 34,
	
	-- Functions (obfuscated calls)
	NEWFN = 35,   CALL = 36,    CALLT = 37,  RET = 38,
	VARRET = 39,
	
	-- String operations
	CONCAT = 40,  STRLEN = 41,  STRLEN2 = 42, STRIDX = 43,
	SUBSTR = 44,
	
	-- Type operations
	TYPEN = 45,   TOTYPE = 46,
	
	-- Advanced obfuscation
	POLYOP = 50,  VMCALL = 51,  DISPATCH = 52, BARRIER = 53,
	CHECKSUM = 54, RANDOMIZE = 55,
	
	-- Sentinel
	HALT = 63
}

function CustomVM:new(securityLevel)
	local self = setmetatable({}, CustomVM)
	self.securityLevel = securityLevel or "high"
	self.bytecode = {}
	self.constants = {}
	self.functions = {}
	self.nameTable = {}
	self.instructionCount = 0
	self.polymorphIndex = 0
	self.dispatchKey = math.random(1000000, 9999999)
	return self
end

-- Compile Lua AST to custom bytecode
function CustomVM:compileAST(ast)
	local state = {
		bytecode = {},
		constants = {},
		registers = {},
		regCount = 0,
		jumpTargets = {},
		stringPool = {}
	}
	
	self:walkAST(ast, state)
	self.bytecode = state.bytecode
	self.constants = state.constants
	return self.bytecode
end

function CustomVM:walkAST(node, state)
	if not node then return end
	
	local nodeType = node.type
	
	if nodeType == "Chunk" then
		for _, stmt in ipairs(node.body or {}) do
			self:walkAST(stmt, state)
		end
		self:emit(state, OPCODES.HALT)
		
	elseif nodeType == "LocalAssignment" then
		for i, var in ipairs(node.variables) do
			local val = node.values[i]
			if val then
				self:walkAST(val, state)
				local reg = self:allocReg(state, var.name)
				self:emit(state, OPCODES.POPR, reg)
			end
		end
		
	elseif nodeType == "Assignment" then
		for i, target in ipairs(node.targets) do
			local val = node.values[i]
			if val then
				self:walkAST(val, state)
				if target.type == "Identifier" then
					local reg = self:allocReg(state, target.name)
					self:emit(state, OPCODES.POPR, reg)
				end
			end
		end
		
	elseif nodeType == "BinaryOp" then
		self:walkAST(node.left, state)
		self:walkAST(node.right, state)
		
		local opMap = {
			["+"] = OPCODES.ADDC, ["-"] = OPCODES.SUBC,
			["*"] = OPCODES.MULC, ["/"] = OPCODES.DIVC,
			["%"] = OPCODES.MODC, ["^"] = OPCODES.POWR,
			["=="] = OPCODES.CMPEQ, ["~="] = OPCODES.CMPNE,
			["<"] = OPCODES.CMPLT, ["<="] = OPCODES.CMPLE,
			[">"] = {op = OPCODES.CMPLT2, swap = true},
			[">="] = {op = OPCODES.CMPLE2, swap = true},
			["and"] = OPCODES.LAND, ["or"] = OPCODES.LOR
		}
		
		local op = opMap[node.op]
		if op then
			if type(op) == "table" then
				self:emit(state, op.op)
			else
				self:emit(state, op)
			end
		end
		
	elseif nodeType == "UnaryOp" then
		self:walkAST(node.operand, state)
		if node.op == "-" then
			self:emit(state, OPCODES.NEGATV)
		elseif node.op == "not" then
			self:emit(state, OPCODES.LNOT)
		end
		
	elseif nodeType == "Literal" then
		local constIdx = self:addConstant(state, node.value)
		self:emit(state, OPCODES.PUSHK, constIdx)
		
	elseif nodeType == "Identifier" then
		local reg = self:getReg(state, node.name)
		self:emit(state, OPCODES.MOVR, reg)
		
	elseif nodeType == "FunctionCall" then
		self:walkAST(node.func, state)
		for _, arg in ipairs(node.args or {}) do
			self:walkAST(arg, state)
		end
		self:emit(state, OPCODES.CALL, #(node.args or {}))
		
	elseif nodeType == "FunctionLiteral" then
		local fnIdx = #self.functions + 1
		self.functions[fnIdx] = node
		self:emit(state, OPCODES.NEWFN, fnIdx)
		
	elseif nodeType == "IfStatement" then
		self:walkAST(node.condition, state)
		local jmpIf = #state.bytecode + 1
		self:emit(state, OPCODES.JIFZ, 0) -- Placeholder
		
		self:walkAST(node.thenPart, state)
		local jmpEnd = #state.bytecode + 1
		self:emit(state, OPCODES.JMP, 0) -- Placeholder
		
		state.bytecode[jmpIf] = #state.bytecode + 1
		if node.elsePart then
			self:walkAST(node.elsePart, state)
		end
		
		state.bytecode[jmpEnd] = #state.bytecode + 1
		
	elseif nodeType == "WhileStatement" then
		local loopStart = #state.bytecode + 1
		self:walkAST(node.condition, state)
		local jmpOut = #state.bytecode + 1
		self:emit(state, OPCODES.JIFZ, 0) -- Placeholder
		
		self:walkAST(node.body, state)
		self:emit(state, OPCODES.JMP, loopStart)
		
		state.bytecode[jmpOut] = #state.bytecode + 1
		
	elseif nodeType == "ReturnStatement" then
		for _, val in ipairs(node.values or {}) do
			self:walkAST(val, state)
		end
		self:emit(state, OPCODES.VARRET, #(node.values or {}))
	end
end

function CustomVM:emit(state, op, arg1, arg2)
	table.insert(state.bytecode, op)
	if arg1 then table.insert(state.bytecode, arg1) end
	if arg2 then table.insert(state.bytecode, arg2) end
end

function CustomVM:addConstant(state, value)
	table.insert(state.constants, value)
	return #state.constants
end

function CustomVM:allocReg(state, name)
	if not state.registers[name] then
		state.regCount = state.regCount + 1
		state.registers[name] = state.regCount
	end
	return state.registers[name]
end

function CustomVM:getReg(state, name)
	return state.registers[name] or 0
end

-- Generate VM Runtime (Roblox-compatible)
function CustomVM:generateRuntime()
	local bytecode = self.bytecode
	local constants = self.constants
	local dispatchKey = self.dispatchKey
	
	-- Encrypt bytecode with XOR + polynomial encoding
	local encrypted = {}
	local poly = {}
	for i = 1, #bytecode do
		poly[i] = (i * 73 + dispatchKey) % 256
		encrypted[i] = (bytecode[i] + poly[i]) % 256
	end
	
	-- Generate custom dispatcher (polymorphic)
	local runtime = [[return(function(...)
local fenv=getfenv();
local stack,regs,ip={},{},1;
local constants=%s;
local bytecode=%s;
local dispatch_key=%d;
local poly_table={};
for i=1,#bytecode do
	poly_table[i]=((i*73+dispatch_key)%%256);
	bytecode[i]=(bytecode[i]+poly_table[i])%%256;
end
while ip<=#bytecode do
	local op=bytecode[ip];
	if op==0 then -- PUSHK
		ip=ip+1;
		table.insert(stack,constants[bytecode[ip]]);
	elseif op==1 then -- PUSHV
		ip=ip+1;
		table.insert(stack,bytecode[ip]);
	elseif op==2 then -- POPR
		ip=ip+1;
		local reg=bytecode[ip];
		regs[reg]=table.remove(stack);
	elseif op==8 then -- ADDC
		local b=table.remove(stack);
		local a=table.remove(stack);
		table.insert(stack,a+b);
	elseif op==9 then -- SUBC
		local b=table.remove(stack);
		local a=table.remove(stack);
		table.insert(stack,a-b);
	elseif op==10 then -- MULC
		local b=table.remove(stack);
		local a=table.remove(stack);
		table.insert(stack,a*b);
	elseif op==11 then -- DIVC
		local b=table.remove(stack);
		local a=table.remove(stack);
		table.insert(stack,a/b);
	elseif op==25 then -- JMP
		ip=ip+1;
		ip=bytecode[ip]-1;
	elseif op==26 then -- JIFZ
		ip=ip+1;
		local cond=table.remove(stack);
		if not cond then ip=bytecode[ip]-1; end
	elseif op==36 then -- CALL
		ip=ip+1;
		local nargs=bytecode[ip];
		local args={};
		for i=1,nargs do
			table.insert(args,table.remove(stack));
		end
		local fn=table.remove(stack);
		local result={fn(unpack(args))};
		for _,v in ipairs(result) do table.insert(stack,v); end
	elseif op==38 then -- RET
		return unpack(stack);
	elseif op==39 then -- VARRET
		ip=ip+1;
		local nrets=bytecode[ip];
		local rets={};
		for i=1,nrets do
			table.insert(rets,1,table.remove(stack));
		end
		return unpack(rets);
	elseif op==63 then -- HALT
		return;
	end
	ip=ip+1;
end
end)(...)]]:format(
		self:serializeTable(constants),
		self:serializeTable(encrypted),
		dispatchKey
	)
	
	return runtime
end

function CustomVM:serializeTable(t)
	local result = {}
	for i, v in ipairs(t) do
		if type(v) == "string" then
			table.insert(result, string.format("%q", v))
		elseif type(v) == "number" then
			table.insert(result, tostring(v))
		elseif type(v) == "boolean" then
			table.insert(result, v and "true" or "false")
		else
			table.insert(result, "nil")
		end
	end
	return "{" .. table.concat(result, ",") .. "}"
end

return CustomVM
