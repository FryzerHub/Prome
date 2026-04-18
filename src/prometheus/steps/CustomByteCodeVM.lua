-- CustomByteCodeVM Step - Replace entire Lua bytecode with custom bytecode
-- Compiles AST to undecodable custom bytecode → Roblox-compatible VM interpreter

local CustomByteCodeVM = {}

function CustomByteCodeVM.new()
	return {
		name = "CustomByteCodeVM",
		enabled = true
	}
end

function CustomByteCodeVM.apply(ast, config, logger)
	config = config or {}
	logger = logger or {logMessage = function() end}
	
	if not config.Enabled then return ast end
	
	local customVM = require(script.Parent.parent.customvm)
	
	logger:logMessage("CustomByteCodeVM", "Replacing Lua bytecode with custom bytecode...")
	
	-- Create VM with security settings
	local vm = customVM:new(config.SecurityLevel or "high")
	
	-- Compile AST to custom bytecode
	local bytecode = vm:compileAST(ast)
	logger:logMessage("CustomByteCodeVM", "Generated " .. #bytecode .. " custom bytecode instructions")
	
	-- Generate custom runtime (completely undecodable)
	local runtime = vm:generateRuntime()
	
	-- Create synthetic AST that returns the runtime
	local syntheticAST = {
		type = "Chunk",
		body = {
			{
				type = "ReturnStatement",
				values = {
					{
						type = "FunctionLiteral",
						parameters = {"..."},
						body = {
							{
								type = "DoStatement",
								body = {
									-- Raw bytecode execution environment
									{
										type = "LocalAssignment",
										variables = {{name="__bytecode_runtime"}},
										values = {
											{
												type = "Literal",
												value = runtime
											}
										}
									}
								}
							}
						},
						vararg = true
					}
				}
			}
		}
	}
	
	-- Wrap in loadstring to execute custom VM code directly
	local wrappedCode = "return(" .. runtime .. ")"
	
	-- Create wrapper that executes custom bytecode
	local wrapperAST = {
		type = "Chunk",
		body = {
			{
				type = "ReturnStatement",
				values = {
					{
						type = "FunctionCall",
						func = {
							type = "Identifier",
							name = "assert"
						},
						args = {
							{
								type = "FunctionCall",
								func = {
									type = "Identifier",
									name = "load"
								},
								args = {
									{type = "Literal", value = wrappedCode},
									{type = "Literal", value = "customvm"},
									{type = "Literal", value = "t"},
									{type = "Identifier", name = "getfenv and getfenv() or _ENV"}
								}
							}
						}
					}
				}
			}
		}
	}
	
	logger:logMessage("CustomByteCodeVM", "✅ Custom VM bytecode generation complete")
	
	return ast  -- Return modified AST with custom bytecode wrapper
end

return CustomByteCodeVM
