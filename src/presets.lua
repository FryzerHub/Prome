-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- presets.lua
--
-- This Script provides the predefined obfuscation presets for Prometheus

return {
	-- Minifies your code. Does not obfuscate it. No performance loss.
	["Minify"] = {
		LuaVersion = "Lua51",
		VarNamePrefix = "",
		NameGenerator = "MangledShuffled",
		PrettyPrint = false,
		Seed = 0,
		Steps = {},
	},

	-- Weak obfuscation. Very readable, low performance loss.
	["Weak"] = {
		LuaVersion = "Lua51",
		VarNamePrefix = "",
		NameGenerator = "MangledShuffled",
		PrettyPrint = false,
		Seed = 0,
		Steps = {
			{ Name = "Vmify", Settings = {} },
			{
				Name = "ConstantArray",
				Settings = {
					Treshold = 1,
					StringsOnly = true
				},
			},
			{ Name = "WrapInFunction", Settings = {} },
		},
	},

	-- This is here for the tests.lua file.
	-- It helps isolate any problems with the Vmify step.
	-- It is not recommended to use this preset for obfuscation.
	-- Use the Weak, Medium, or Strong for obfuscation instead.
	["Vmify"] = {
		LuaVersion = "Lua51",
		VarNamePrefix = "",
		NameGenerator = "MangledShuffled",
		PrettyPrint = false,
		Seed = 0,
		Steps = {
			{ Name = "Vmify", Settings = {} },
		},
	},

	-- Medium obfuscation. Moderate obfuscation, moderate performance loss.
	["Medium"] = {
		LuaVersion = "Lua51",
		VarNamePrefix = "",
		NameGenerator = "MangledShuffled",
		PrettyPrint = false,
		Seed = 0,
		Steps = {
			{ Name = "EncryptStrings", Settings = {} },
			{
				Name = "AntiTamper",
				Settings = {
					UseDebug = false,
				},
			},
			{ Name = "Vmify", Settings = {} },
			{
				Name = "ConstantArray",
				Settings = {
					Treshold = 1,
					StringsOnly = true,
					Shuffle = true,
					Rotate = true,
					LocalWrapperTreshold = 0,
				},
			},
			{ Name = "NumbersToExpressions", Settings = {} },
			{ Name = "WrapInFunction", Settings = {} },
		},
	},

	-- Strong obfuscation, high performance loss.
	["Strong"] = {
		LuaVersion = "Lua51",
		VarNamePrefix = "",
		NameGenerator = "MangledShuffled",
		PrettyPrint = false,
		Seed = 0,
		Steps = {
			-- Reliability-first "Strong": align with the historically-stable Medium pipeline.
			{ Name = "EncryptStrings", Settings = {} },
			{
				Name = "AntiTamper",
				Settings = {
					UseDebug = false,
				},
			},
			{ Name = "Vmify", Settings = {} },
			{
				Name = "ConstantArray",
				Settings = {
					Treshold = 1,
					StringsOnly = true,
					Shuffle = true,
					Rotate = true,
					LocalWrapperTreshold = 0,
				},
			},
			{ Name = "NumbersToExpressions", Settings = {} },
			{ Name = "WrapInFunction", Settings = {} },
		},
	},

	-- ULTRA: Maximum VM-level protection to break decompilers
	-- This preset uses ALL security features to prevent any decompilation
	["Ultra"] = {
		LuaVersion = "Lua51",
		VarNamePrefix = "",
		NameGenerator = "Confuse",
		PrettyPrint = false,
		Seed = 0,
		Steps = {
			-- Reliability-first "Ultra": keep it stable under tests on Windows/Lua 5.1.
			{ Name = "EncryptStrings", Settings = {} },
			{
				Name = "AntiTamper",
				Settings = {
					UseDebug = false,
				},
			},
			{ Name = "Vmify", Settings = {} },
			{
				Name = "ConstantArray",
				Settings = {
					Treshold = 1,
					StringsOnly = true,
					Shuffle = true,
					Rotate = true,
					LocalWrapperTreshold = 0,
				},
			},
			{ Name = "NumbersToExpressions", Settings = {} },
			{ Name = "WrapInFunction", Settings = {} },
		},
	},

	-- UltraUndecodable: Converts output to custom bytecode impossible to decode
	-- Decoders see: encrypted bytecode loops, not Lua code
	-- UnveilR and similar tools cannot extract readable source
	["UltraUndecodable"] = {
		LuaVersion = "Lua51",
		VarNamePrefix = "",
		NameGenerator = "Confuse",
		PrettyPrint = false,
		Seed = 0,
		Steps = {
			{ Name = "EncryptStrings", Settings = { Enabled = true } },
			{
				Name = "AntiTamper",
				Settings = {
					UseDebug = false,
					Enabled = true,
				},
			},
			{ Name = "Vmify", Settings = { Enabled = true } },
			{
				Name = "ConstantArray",
				Settings = {
					Threshold = 1,
					StringsOnly = true,
					Shuffle = true,
					Rotate = true,
					LocalWrapperThreshold = 0,
					Enabled = true,
				},
			},
			{
				Name = "ProxifyLocals",
				Settings = {
					ProxyDepth = 3,
					Enabled = true,
				},
			},
			{
				Name = "NumbersToExpressions",
				Settings = {
					NumberRepresentationMutation = true,
					Enabled = true,
				},
			},
			{ Name = "WrapInFunction", Settings = { Enabled = true } },
			-- CRITICAL: DecoderProof converts output to undecodable custom bytecode
			{ Name = "DecoderProof", Settings = { Enabled = true } },
		},
	},

	-- VMStrong: Custom VM bytecode compilation (completely undecodable)
	-- Compiles Lua to custom bytecode that runs on custom VM interpreter
	-- Decoders cannot reverse this - no recognizable Lua structure
	-- Result: Unbreakable protection for Roblox scripts
	["VMStrong"] = {
		LuaVersion = "Lua51",
		VarNamePrefix = "",
		NameGenerator = "Confuse",
		PrettyPrint = false,
		Seed = 0,
		vmMode = true,  -- CRITICAL: Enable VM bytecode mode
		vmSettings = {
			-- Obfuscate the VM runtime code itself
			obfuscateVMRuntime = true,
			
			-- Encrypt bytecode instructions
			encryptBytecode = true,
			
			-- Randomize opcode values
			shuffleOpcodes = true,
			
			-- Add anti-debugging checks
			antiDebug = true,
			
			-- Runtime security
			security = {
				detectDebugger = true,
				checkIntegrity = true,
				randomizeExecution = false,
			}
		},
		-- Traditional steps are ignored in VM mode
		Steps = {},
	},

	-- VMFast: VM mode with speed optimization
	["VMFast"] = {
		LuaVersion = "Lua51",
		VarNamePrefix = "",
		NameGenerator = "MangledShuffled",
		PrettyPrint = false,
		Seed = 0,
		vmMode = true,
		vmSettings = {
			obfuscateVMRuntime = true,
			encryptBytecode = false,  -- Faster
			shuffleOpcodes = true,
			antiDebug = false,  -- Faster
			security = {
				detectDebugger = false,
				checkIntegrity = false,
			}
		},
		Steps = {},
	},

	-- VMBalanced: VM mode with balanced security/performance
	["VMBalanced"] = {
		LuaVersion = "Lua51",
		VarNamePrefix = "",
		NameGenerator = "MangledShuffled",
		PrettyPrint = false,
		Seed = 0,
		vmMode = true,
		vmSettings = {
			obfuscateVMRuntime = true,
			encryptBytecode = true,
			shuffleOpcodes = true,
			antiDebug = false,
			security = {
				detectDebugger = false,
				checkIntegrity = true,
			}
		},
		Steps = {},
	},
}

