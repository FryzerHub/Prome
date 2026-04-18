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
			{
				Name = "ConstantArray",
				Settings = {
					Threshold = 1,
					StringsOnly = true
				},
			},
			{ Name = "WrapInFunction", Settings = {} },
		},
	},

	-- This is here for the tests.lua file.
	-- It helps isolate any problems with the Vmify step.
	-- It is not recommended to use this preset for obfuscation.
	-- Use the Weak, Medium, Strong or Ultimate presets instead.
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
					Threshold = 1,
					StringsOnly = true,
					Shuffle = true,
					Rotate = true,
					LocalWrapperThreshold = 0,
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
					Threshold = 1,
					StringsOnly = true,
					Shuffle = true,
					Rotate = true,
					LocalWrapperThreshold = 0,
				},
			},
			{ Name = "NumbersToExpressions", Settings = {} },
			{ Name = "WrapInFunction", Settings = {} },
		},
	},

	-- ============================================================================
	-- ULTIMATE: Maximum protection combining ALL obfuscation techniques
	-- ============================================================================
	-- This preset applies EVERY available obfuscation step in optimal order
	-- All steps work together - Vmify is integrated as part of the pipeline
	-- Expected behavior: Code goes through ALL transformations sequentially
	-- ============================================================================
	["Ultimate"] = {
		LuaVersion = "Lua51",
		VarNamePrefix = "",
		NameGenerator = "Confuse",  -- Most complex variable names
		PrettyPrint = false,
		Seed = 0,
		Steps = {
			-- ================================================================
			-- STAGE 1: PRE-VM OBFUSCATION
			-- These steps obfuscate the code BEFORE VM transformation
			-- ================================================================
			
			-- Step 1: Encrypt all string literals
			{
				Name = "EncryptStrings",
				Settings = {}
			},
			
			-- Step 2: Add anti-tampering checks
			{
				Name = "AntiTamper",
				Settings = {
					UseDebug = false,
				},
			},
			
			-- Step 3: Proxify local variables (makes decompilation harder)
			{
				Name = "ProxifyLocals",
				Settings = {
					Threshold = 0.7,  -- 70% of locals will be proxified
				},
			},
			
			-- ================================================================
			-- STAGE 2: VM TRANSFORMATION
			-- CRITICAL: Vmify runs AFTER pre-obfuscation, BEFORE post-obfuscation
			-- This ensures the VM operates on already-obfuscated code
			-- ================================================================
			
			{
				Name = "Vmify",
				Settings = {}
			},
			
			-- ================================================================
			-- STAGE 3: POST-VM OBFUSCATION
			-- These steps further obfuscate the VM-wrapped code
			-- ================================================================
			
			-- Step 5: Move constants into arrays
			{
				Name = "ConstantArray",
				Settings = {
					Threshold = 1,        -- Obfuscate 100% of constants
					StringsOnly = false,  -- Include numbers, booleans, etc.
					Shuffle = true,       -- Randomize array order
					Rotate = true,        -- Add rotation obfuscation
					LocalWrapperThreshold = 0.3,  -- 30% wrapped in local functions
				},
			},
			
			-- Step 6: Split strings into fragments
			{
				Name = "SplitStrings",
				Settings = {
					Threshold = 0.8,  -- 80% of strings get split
				},
			},
			
			-- Step 7: Convert numbers to complex expressions
			{
				Name = "NumbersToExpressions",
				Settings = {
					NumberRepresentationMutation = true,  -- Maximum number obfuscation
				},
			},
			
			-- Step 8: Add control flow flattening (if available)
			-- Uncomment if your Prometheus version has this step:
			-- {
			-- 	Name = "ControlFlowFlattening",
			-- 	Settings = {
			-- 		Threshold = 0.75,
			-- 	},
			-- },
			
			-- ================================================================
			-- STAGE 4: FINAL WRAPPING
			-- ================================================================
			
			-- Step 9: Wrap everything in a function
			{
				Name = "WrapInFunction",
				Settings = {}
			},
		},
	},

	-- ============================================================================
	-- ULTIMATE_MAX: Same as Ultimate but with even more aggressive settings
	-- ============================================================================
	["Ultimate_Max"] = {
		LuaVersion = "Lua51",
		VarNamePrefix = "",
		NameGenerator = "Confuse",
		PrettyPrint = false,
		Seed = 0,
		Steps = {
			-- Pre-VM Maximum Obfuscation
			{ Name = "EncryptStrings", Settings = {} },
			{
				Name = "AntiTamper",
				Settings = {
					UseDebug = false,
				},
			},
			{
				Name = "ProxifyLocals",
				Settings = {
					Threshold = 1,  -- 100% of locals proxified
				},
			},
			
			-- VM Transformation
			{ Name = "Vmify", Settings = {} },
			
			-- Post-VM Maximum Obfuscation
			{
				Name = "ConstantArray",
				Settings = {
					Threshold = 1,
					StringsOnly = false,
					Shuffle = true,
					Rotate = true,
					LocalWrapperThreshold = 0.5,  -- 50% wrapped
				},
			},
			{
				Name = "SplitStrings",
				Settings = {
					Threshold = 1,  -- 100% of strings split
				},
			},
			{
				Name = "NumbersToExpressions",
				Settings = {
					NumberRepresentationMutation = true,
				},
			},
			{ Name = "WrapInFunction", Settings = {} },
		},
	},

	-- ============================================================================
	-- BALANCED: VM + Essential obfuscation with better performance
	-- ============================================================================
	["Balanced"] = {
		LuaVersion = "Lua51",
		VarNamePrefix = "",
		NameGenerator = "MangledShuffled",
		PrettyPrint = false,
		Seed = 0,
		Steps = {
			{ Name = "EncryptStrings", Settings = {} },
			{ Name = "Vmify", Settings = {} },
			{
				Name = "ConstantArray",
				Settings = {
					Threshold = 1,
					StringsOnly = true,  -- Only strings for performance
					Shuffle = true,
					Rotate = true,
					LocalWrapperThreshold = 0,
				},
			},
			{ Name = "WrapInFunction", Settings = {} },
		},
	},
}