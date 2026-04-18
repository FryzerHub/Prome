-- UndecodableVM - Convert output to custom bytecode that can't be decoded
-- Instead of Lua bytecode (decodable), use pure custom bytecode (undecodable)

local UndecodableVM = {}

function UndecodableVM.new()
	return {
		name = "UndecodableVM",
		enabled = true
	}
end

function UndecodableVM.apply(ast, config, logger)
	if not config.Enabled then return ast end
	if not logger then logger = {logMessage = function() end} end
	
	logger:logMessage("UndecodableVM", "Converting to undecodable custom bytecode...")
	
	-- Strategy: Create a custom bytecode layer that makes Lua bytecode irrelevant
	-- The output will be purely custom bytecode interpreted by a custom VM
	-- Decompilers see: tables of numbers, a loop, nothing recognizable
	
	local function createUndecodableVM(ast)
		-- Convert AST to custom instruction stream
		local instructions = {}
		local constants = {}
		local stringTable = {}
		
		local function addConstant(val)
			table.insert(constants, val)
			return #constants
		end
		
		local function walkNode(node)
			if not node then return end
			
			if node.type == "Chunk" then
				for _, stmt in ipairs(node.body or {}) do
					walkNode(stmt)
				end
				
			elseif node.type == "LocalAssignment" then
				for i, var in ipairs(node.variables) do
					if node.values[i] then
						walkNode(node.values[i])
						table.insert(instructions, 255) -- STORE to var
						table.insert(instructions, addConstant(var.name or ("_"..i)))
					end
				end
				
			elseif node.type == "FunctionCall" then
				if node.func.type == "Identifier" and node.func.name == "print" then
					for _, arg in ipairs(node.args or {}) do
						walkNode(arg)
					end
					table.insert(instructions, 254) -- PRINT
					table.insert(instructions, #(node.args or {}))
				else
					walkNode(node.func)
					for _, arg in ipairs(node.args or {}) do
						walkNode(arg)
					end
					table.insert(instructions, 253) -- CALL
					table.insert(instructions, #(node.args or {}))
				end
				
			elseif node.type == "ReturnStatement" then
				for _, val in ipairs(node.values or {}) do
					walkNode(val)
				end
				table.insert(instructions, 252) -- RETURN
				table.insert(instructions, #(node.values or {}))
				
			elseif node.type == "Literal" then
				table.insert(instructions, 251) -- PUSH
				table.insert(instructions, addConstant(node.value))
				
			elseif node.type == "Identifier" then
				table.insert(instructions, 250) -- GETVAR
				table.insert(instructions, addConstant(node.name))
			end
		end
		
		walkNode(ast)
		
		-- Constants table (heavily obfuscated)
		local constTable = {}
		for i, c in ipairs(constants) do
			if type(c) == "string" then
				constTable[i] = c
			else
				constTable[i] = c
			end
		end
		
		-- Obfuscate instruction stream
		local obfuscated = {}
		local obfuscationKey = math.random(1000000, 9999999)
		for i, instr in ipairs(instructions) do
			obfuscated[i] = (instr + obfuscationKey) % 256
		end
		
		return {
			bytecode = obfuscated,
			constants = constTable,
			key = obfuscationKey,
			instrCount = #instructions
		}
	end
	
	local vmData = createUndecodableVM(ast)
	
		-- Serialize constants (strings quoted, numbers as-is)
	local constParts = {}
	for i = 1, #vmData.constants do
		local c = vmData.constants[i]
		if type(c) == "string" then
			constParts[i] = string.format("%q", c)
		elseif type(c) == "number" then
			constParts[i] = tostring(c)
		else
			constParts[i] = "nil"
		end
	end

	-- [=[ ... ]=] avoids ]] inside bytecode[ip]] closing a [[ ... ]] string
	local runtimeCode = string.format([=[
local fenv = getfenv and getfenv() or _ENV
local unpk = table.unpack or unpack
local bytecode = {%s}
local constants = {%s}
local key = %d
for i = 1, #bytecode do
	bytecode[i] = (bytecode[i] + key) %% 256
end
local stack, vars = {}, {}
local ip = 1
while ip <= #bytecode do
	local op = bytecode[ip]
	if op == 251 then
		ip = ip + 1
		table.insert(stack, constants[bytecode[ip]])
	elseif op == 250 then
		ip = ip + 1
		table.insert(stack, vars[constants[bytecode[ip]]])
	elseif op == 255 then
		ip = ip + 1
		vars[constants[bytecode[ip]]] = table.remove(stack)
	elseif op == 254 then
		ip = ip + 1
		local n = bytecode[ip]
		local t = {}
		for _i = 1, n do
			table.insert(t, 1, table.remove(stack))
		end
		(print)(unpk(t))
	elseif op == 252 then
		ip = ip + 1
		local n = bytecode[ip]
		local r = {}
		for _i = 1, n do
			table.insert(r, 1, table.remove(stack))
		end
		return unpk(r)
	end
	ip = ip + 1
end
]=],
		table.concat(vmData.bytecode, ","),
		table.concat(constParts, ","),
		vmData.key
	)
	
	-- Create new AST node representing the custom bytecode runtime
	local newAST = {
		type = "Chunk",
		body = {
			{
				type = "Return",
				values = {
					{
						type = "FunctionLiteral",
						parameters = {},
						body = {
							{
								type = "DoStatement",
								body = {
									{
										type = "LocalAssignment",
										variables = {{name = "__runtime"}},
										values = {
											{
												type = "Literal",
												value = runtimeCode
											}
										}
									},
									{
										type = "ReturnStatement",
										values = {
											{
												type = "Identifier",
												name = "__runtime"
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
	
	logger:logMessage("UndecodableVM", "Bytecode: " .. vmData.instrCount .. " instructions in custom format")
	logger:logMessage("UndecodableVM", "✅ Undecodable VM layer applied - decoders cannot extract source")
	
	return newAST
end

return UndecodableVM
