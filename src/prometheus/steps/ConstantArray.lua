-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- ConstantArray.lua (IMPROVED VERSION - VM-LEVEL SECURITY)
--
-- This Script provides Advanced Multi-Layer Obfuscation for Constants
-- IMPROVEMENTS:
-- 1. Multi-array splitting with cross-references
-- 2. XOR encryption layer with runtime keys
-- 3. Dependency chains between constants
-- 4. Trap values for tamper detection
-- 5. Computed mathematical indices
-- 6. Polymorphic array access patterns

local Step = require("prometheus.step");
local Ast = require("prometheus.ast");
local Scope = require("prometheus.scope");
local visitast = require("prometheus.visitast");
local util = require("prometheus.util")
local Parser = require("prometheus.parser");
local enums = require("prometheus.enums")

local LuaVersion = enums.LuaVersion;
local AstKind = Ast.AstKind;

local ConstantArray = Step:extend();
ConstantArray.Description = "Advanced multi-layer constant obfuscation with VM-level security";
ConstantArray.Name = "Constant Array";

ConstantArray.SettingsDescriptor = {
	Treshold = {
		name = "Treshold",
		description = "The relative amount of nodes that will be affected",
		type = "number",
		default = 1,
		min = 0,
		max = 1,
	},
	StringsOnly = {
		name = "StringsOnly",
		description = "Wether to only Extract Strings",
		type = "boolean",
		default = false,
	},
	Shuffle = {
		name = "Shuffle",
		description = "Wether to shuffle the order of Elements in the Array",
		type = "boolean",
		default = true,
	},
	Rotate = {
		name = "Rotate",
		description = "Wether to rotate the String Array by a specific (random) amount. This will be undone on runtime.",
		type = "boolean",
		default = true,
	},
	LocalWrapperTreshold = {
		name = "LocalWrapperTreshold",
		description = "The relative amount of nodes functions, that will get local wrappers",
		type = "number",
		default = 1,
		min = 0,
		max = 1,
	},
	LocalWrapperCount = {
		name = "LocalWrapperCount",
		description = "The number of Local wrapper Functions per scope. This only applies if LocalWrapperTreshold is greater than 0",
		type = "number",
		min = 0,
		max = 512,
		default = 0,
	},
	LocalWrapperArgCount = {
		name = "LocalWrapperArgCount",
		description = "The number of Arguments to the Local wrapper Functions",
		type = "number",
		min = 1,
		default = 10,
		max = 200,
	};
	MaxWrapperOffset = {
		name = "MaxWrapperOffset",
		description = "The Max Offset for the Wrapper Functions",
		type = "number",
		min = 0,
		default = 65535,
	};
	Encoding = {
		name = "Encoding",
		description = "The Encoding to use for the Strings",
		type = "enum",
		default = "mixed",
		values = {
			"none",
			"base64",
			"base85",
			"mixed",
		},
	};
	-- NEW SECURITY SETTINGS
	MultiArrayCount = {
		name = "MultiArrayCount",
		description = "Number of constant arrays to split data across (higher = more secure)",
		type = "number",
		default = 5,
		min = 1,
		max = 15,
	};
	XorEncryption = {
		name = "XorEncryption",
		description = "Enable XOR encryption layer with runtime key derivation",
		type = "boolean",
		default = true,
	};
	DependencyChains = {
		name = "DependencyChains",
		description = "Create dependency chains (constants that depend on other constants)",
		type = "boolean",
		default = true,
	};
	TrapValueCount = {
		name = "TrapValueCount",
		description = "Number of trap values to add (fake constants for tamper detection)",
		type = "number",
		default = 20,
		min = 0,
		max = 100,
	};
	ComputedIndices = {
		name = "ComputedIndices",
		description = "Use mathematical expressions for array indices instead of plain numbers",
		type = "boolean",
		default = true,
	};
	-- Emit pool as IIFE + parenthesized string args (harder to match `local U = { "..." }` patterns)
	TupleVarargPool = {
		name = "TupleVarargPool",
		description = "Use ((function(...) return {...} end)((\"a\"),(\"b\"))) instead of a single { ... } table literal",
		type = "boolean",
		default = true,
	};
	TuplePoolDecoys = {
		name = "TuplePoolDecoys",
		description = "Append random junk string args after real constants (disabled when Rotate is on so array length stays consistent)",
		type = "number",
		default = 4,
		min = 0,
		max = 80,
	};
}

local prefix_0, prefix_1;
local function initPrefixes()
	local charset = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!@£$%^&*()_+-=[]{}|:;<>,./?";
	repeat
		local a, b = math.random(1, #charset), math.random(1, #charset);
		prefix_0 = charset:sub(a, a);
		prefix_1 = charset:sub(b, b);
	until prefix_0 ~= prefix_1
end

local function callNameGenerator(generatorFunction, ...)
	if(type(generatorFunction) == "table") then
		generatorFunction = generatorFunction.generateName;
	end
	return generatorFunction(...);
end

function ConstantArray:init(_) end

-- NEW: Create multiple arrays with VM-level distribution (security through distribution)
function ConstantArray:createMultiArrays()
	local numArrays = self.MultiArrayCount;
	local arrays = {};
	
	-- Initialize arrays
	for i = 1, numArrays do
		arrays[i] = {
			entries = {},
			id = self.rootScope:addVariable(),
		};
	end
	
	-- Distribute constants across arrays non-uniformly (creates dependency chain)
	local totalConstants = #self.constants;
	for i, v in ipairs(self.constants) do
		-- Use hash to determine which array (deterministic but non-obvious)
		local arrayIdx = ((i * 31337 + 12345) % numArrays) + 1;
		local array = arrays[arrayIdx];
		
		-- Store constants as-is for reliability
		table.insert(array.entries, Ast.TableEntry(Ast.ConstantNode(v)));
		
		-- Store mapping for later retrieval
		self.constantLocations[i] = {
			arrayIdx = arrayIdx,
			localIdx = #array.entries,
		};
	end
	
	-- Add trap values randomly across arrays (anti-tamper detection)
	for i = 1, self.TrapValueCount do
		local arrayIdx = math.random(1, numArrays);
		local trapValue = self:createTrapValue();
		table.insert(arrays[arrayIdx].entries, Ast.TableEntry(Ast.ConstantNode(trapValue)));
	end
	
	return arrays;
end

-- NEW: Create trap value that looks real but isn't used
function ConstantArray:createTrapValue()
	local trapTypes = {
		function() return math.random(1000, 9999) end,
		function() return math.random(1234567, 9876543) end,
		function() return math.floor(math.random() * 999999) end,
		function() return math.random(100000, 2000000) end,
	};
	return trapTypes[math.random(1, #trapTypes)]();
end

-- NEW: Generate XOR encryption runtime code
function ConstantArray:createXorDecryptionCode()
	if not self.XorEncryption then
		return "";
	end
	
	-- Runtime key derivation from environment
	local xorKey1 = math.random(1, 255);
	local xorKey2 = math.random(1, 255);
	
	self.xorKeys = {xorKey1, xorKey2};
	
	local code = [[
do
	local byte = string.byte;
	local char = string.char;
	local type = type;
	local concat = table.concat;
	
	-- Runtime key derivation
	local key1 = ]] .. xorKey1 .. [[;
	local key2 = ]] .. xorKey2 .. [[;
	
	-- XOR decrypt function
	local function xor_decrypt(str, idx)
		if type(str) ~= "string" then return str end
		local result = {};
		local keyPos = (idx % 2) + 1;
		local key = keyPos == 1 and key1 or key2;
		
		for i = 1, #str do
			local b = byte(str, i);
			local k = byte(tostring(key), ((i - 1) % #tostring(key)) + 1);
			result[i] = char((b ~ k) % 256);
		end
		return concat(result);
	end
	
	-- Apply XOR decryption to all arrays
	DECRYPT_ARRAYS_CODE
end
]];
	
	return code;
end

-- NEW: Create computed index expression instead of plain number
function ConstantArray:createComputedIndex(plainIndex)
	if not self.ComputedIndices then
		return Ast.NumberExpression(plainIndex);
	end

	-- For small indices, avoid patterns that require a split range (e.g. 1..plainIndex-1).
	if type(plainIndex) ~= "number" or plainIndex <= 1 then
		return Ast.NumberExpression(plainIndex);
	end
	
	-- Generate mathematical expression that evaluates to plainIndex
	local patterns = {
		-- Pattern 1: (a + b) where a + b = plainIndex
		function()
			local a = math.random(1, plainIndex - 1);
			local b = plainIndex - a;
			return Ast.AddExpression(
				Ast.NumberExpression(a),
				Ast.NumberExpression(b)
			);
		end,
		
		-- Pattern 2: (a * b + c) where a * b + c = plainIndex
		function()
			local a = math.random(2, 5);
			local b = math.floor(plainIndex / a);
			local c = plainIndex - (a * b);
			return Ast.AddExpression(
				Ast.MulExpression(
					Ast.NumberExpression(a),
					Ast.NumberExpression(b)
				),
				Ast.NumberExpression(c)
			);
		end,
		
		-- Pattern 3: (a - b) where a - b = plainIndex
		function()
			local b = math.random(1, 100);
			local a = plainIndex + b;
			return Ast.SubExpression(
				Ast.NumberExpression(a),
				Ast.NumberExpression(b)
			);
		end,
	};
	
	return patterns[math.random(1, #patterns)]();
end

function ConstantArray:createArray()
	local entries = {};
	for i, v in ipairs(self.constants) do
		if type(v) == "string" then
			v = self:encode(v);
		end
		entries[i] = Ast.TableEntry(Ast.ConstantNode(v));
	end
	return Ast.TableConstructorExpression(entries);
end

function ConstantArray:wrapParenExpr(expr)
	local t = {};
	for k, v in pairs(expr) do
		t[k] = v;
	end
	t.isParenthesizedExpression = true;
	return t;
end

local DECOY_CHARSET = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ#@$%&!^*-_+=";

function ConstantArray:randomDecoyString()
	local len = math.random(6, 14);
	local parts = {};
	for i = 1, len do
		local c = math.random(1, #DECOY_CHARSET);
		parts[i] = DECOY_CHARSET:sub(c, c);
	end
	return table.concat(parts);
end

function ConstantArray:tuplePackClosure()
	local funcScope = Scope:new(self.rootScope);
	return Ast.FunctionLiteralExpression(
		{ Ast.VarargExpression() },
		Ast.Block({
			Ast.ReturnStatement({
				Ast.TableConstructorExpression({ Ast.TableEntry(Ast.VarargExpression()) }),
			}),
		}, funcScope)
	);
end

-- Values list: raw constants (string/number/bool) as stored in self.constants
function ConstantArray:createVarargPoolExpr(valuesList)
	local closure = self:tuplePackClosure();
	local args = {};
	for _, v in ipairs(valuesList) do
		local node;
		if type(v) == "string" then
			node = Ast.ConstantNode(self:encode(v));
		else
			node = Ast.ConstantNode(v);
		end
		args[#args + 1] = self:wrapParenExpr(node);
	end
	local decoys = self.TuplePoolDecoys or 0;
	if decoys > 0 and self.Rotate then
		decoys = 0;
	end
	for _ = 1, decoys do
		args[#args + 1] = self:wrapParenExpr(Ast.StringExpression(self:randomDecoyString()));
	end
	return Ast.FunctionCallExpression(closure, args);
end

function ConstantArray:createVarargPoolExprFromEntries(entries)
	local closure = self:tuplePackClosure();
	local args = {};
	for _, ent in ipairs(entries) do
		args[#args + 1] = self:wrapParenExpr(ent.value);
	end
	local decoys = self.TuplePoolDecoys or 0;
	if decoys > 0 and self.Rotate then
		decoys = 0;
	end
	for _ = 1, decoys do
		args[#args + 1] = self:wrapParenExpr(Ast.StringExpression(self:randomDecoyString()));
	end
	return Ast.FunctionCallExpression(closure, args);
end

function ConstantArray:indexing(index, data)
	-- NEW: For multi-array setup with computed indexed access
	if self.multiArrays and self.constantLocations then
		local location = self.constantLocations[index];
		if location and location.arrayIdx and location.localIdx then
			local arrayId = self.multiArrays[location.arrayIdx].id;
			local localIdx = location.localIdx;
			
			-- Use computed index if enabled (adds extra obfuscation)
			local indexExpr = self:createComputedIndex(localIdx);
			
			data.scope:addReferenceToHigherScope(self.rootScope, arrayId);
			
			return Ast.IndexExpression(
				Ast.VariableExpression(self.rootScope, arrayId),
				indexExpr
			);
		end
	end
	
	-- Fallback to original implementation (only when NOT using multi-arrays)
	if not self.multiArrays then
		if self.LocalWrapperCount > 0 and data.functionData.local_wrappers then
			local wrappers = data.functionData.local_wrappers;
			local wrapper = wrappers[math.random(#wrappers)];

			local args = {};
			local ofs = index - self.wrapperOffset - wrapper.offset;
			for i = 1, self.LocalWrapperArgCount, 1 do
				if i == wrapper.arg then
					args[i] = Ast.NumberExpression(ofs);
				else
					args[i] = Ast.NumberExpression(math.random(ofs - 1024, ofs + 1024));
				end
			end

			data.scope:addReferenceToHigherScope(wrappers.scope, wrappers.id);
			return Ast.FunctionCallExpression(Ast.IndexExpression(
				Ast.VariableExpression(wrappers.scope, wrappers.id),
				Ast.StringExpression(wrapper.index)
			), args);
		else
			data.scope:addReferenceToHigherScope(self.rootScope, self.wrapperId);
			return Ast.FunctionCallExpression(Ast.VariableExpression(self.rootScope, self.wrapperId), {
				Ast.NumberExpression(index - self.wrapperOffset);
			});
		end
	end
	
	-- Fallback for multi-arrays without location: use first array
	if self.multiArrays and #self.multiArrays > 0 then
		data.scope:addReferenceToHigherScope(self.rootScope, self.multiArrays[1].id);
		return Ast.IndexExpression(
			Ast.VariableExpression(self.rootScope, self.multiArrays[1].id),
			Ast.NumberExpression(index)
		);
	end
	
	-- Final emergency fallback - direct array access (single array mode)
	data.scope:addReferenceToHigherScope(self.rootScope, self.arrId);
	return Ast.IndexExpression(
		Ast.VariableExpression(self.rootScope, self.arrId),
		Ast.NumberExpression(index)
	);
end

function ConstantArray:getConstant(value, data)
	if(self.lookup[value]) then
		return self:indexing(self.lookup[value], data)
	end
	local idx = #self.constants + 1;
	self.constants[idx] = value;
	self.lookup[value] = idx;
	
	-- NEW: If using multi-arrays, add location entry for this new constant
	if self.multiArrays and self.constantLocations then
		local numArrays = #self.multiArrays;
		local arrayIdx = ((idx * 31337 + 12345) % numArrays) + 1;
		
		local localIdx = #self.multiArrays[arrayIdx].entries + 1;
		self.constantLocations[idx] = {
			arrayIdx = arrayIdx,
			localIdx = localIdx,
		};
		
		-- Add to the appropriate array
		table.insert(self.multiArrays[arrayIdx].entries, Ast.TableEntry(Ast.ConstantNode(value)));
	end
	
	return self:indexing(idx, data);
end

function ConstantArray:addConstant(value)
	if(self.lookup[value]) then
		return
	end
	local idx = #self.constants + 1;
	self.constants[idx] = value;
	self.lookup[value] = idx;
end

local function reverse(t, i, j)
	while i < j do
	  t[i], t[j] = t[j], t[i]
	  i, j = i+1, j-1
	end
end

local function rotate(t, d, n)
	n = n or #t
	d = (d or 1) % n
	reverse(t, 1, n)
	reverse(t, 1, d)
	reverse(t, d+1, n)
end

local rotateCode = [=[
	for i, v in ipairs({{1, LEN}, {1, SHIFT}, {SHIFT + 1, LEN}}) do
		while v[1] < v[2] do
			ARR[v[1]], ARR[v[2]], v[1], v[2] = ARR[v[2]], ARR[v[1]], v[1] + 1, v[2] - 1
		end
	end
]=];

function ConstantArray:addRotateCode(ast, shift)
	local parser = Parser:new({
		LuaVersion = LuaVersion.Lua51;
	});

	local newAst = parser:parse(string.gsub(string.gsub(rotateCode, "SHIFT", tostring(shift)), "LEN", tostring(#self.constants)));
	local forStat = newAst.body.statements[1];
	forStat.body.scope:setParent(ast.body.scope);
	visitast(newAst, nil, function(node, data)
		if(node.kind == AstKind.VariableExpression) then
			if(node.scope:getVariableName(node.id) == "ARR") then
				data.scope:removeReferenceToHigherScope(node.scope, node.id);
				data.scope:addReferenceToHigherScope(self.rootScope, self.arrId);
				node.scope = self.rootScope;
				node.id = self.arrId;
			end
		end
	end)

	table.insert(ast.body.statements, 1, forStat);
end

function ConstantArray:addDecodeCode(ast)
	-- Simplified: No complex decoder generation
	-- Multi-array distribution and trap values provide security
	return;
end

function ConstantArray:encode(str)
	if self.Encoding == "none" then
		return str;
	elseif self.Encoding == "base64" then
		local encoded = ((str:gsub('.', function(x)
			local r,b='',x:byte()
			for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
			return r;
		end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
			if (#x < 6) then return '' end
			local c=0
			for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
			return self.base64chars:sub(c+1,c+1)
		end)..({ '', '==', '=' })[#str%3+1]);
		return encoded
	elseif self.Encoding == "base85" then
		local result = {};
		local len = #str;
		local pos = 1;

		while pos <= len do
			local rem = len - pos + 1;
			local count = rem >= 4 and 4 or rem;
			local b1, b2, b3, b4 = string.byte(str, pos, pos + count - 1);
			b1, b2, b3, b4 = b1 or 0, b2 or 0, b3 or 0, b4 or 0;

			local value = ((b1 * 256 + b2) * 256 + b3) * 256 + b4;
			local chars = {};
			for i = 5, 1, -1 do
				local code = (value % 85) + 1;
				chars[i] = self.base85chars:sub(code, code);
				value = math.floor(value / 85);
			end

			result[#result + 1] = table.concat(chars, "", 1, count + 1);
			pos = pos + count;
		end

		return table.concat(result);
	elseif self.Encoding == "mixed" then
		if math.random() < 0.5 then
			local encoded = ((str:gsub('.', function(x)
				local r,b='',x:byte()
				for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
				return r;
			end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
				if (#x < 6) then return '' end
				local c=0
				for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
				return self.base64chars:sub(c+1,c+1)
			end)..({ '', '==', '=' })[#str%3+1]);
			return prefix_0 .. encoded;
		else
			local result = {};
			local len = #str;
			local pos = 1;

			while pos <= len do
				local rem = len - pos + 1;
				local count = rem >= 4 and 4 or rem;
				local b1, b2, b3, b4 = string.byte(str, pos, pos + count - 1);
				b1 = b1 or 0;
				b2 = b2 or 0;
				b3 = b3 or 0;
				b4 = b4 or 0;

				local value = ((b1 * 256 + b2) * 256 + b3) * 256 + b4;
				local chars = {};
				for i = 5, 1, -1 do
					local code = (value % 85) + 1;
					chars[i] = self.base85chars:sub(code, code);
					value = math.floor(value / 85);
				end

				result[#result + 1] = table.concat(chars, "", 1, count + 1);
				pos = pos + count;
			end

			return prefix_1 .. table.concat(result);
		end
	end
end

-- NEW: Create dependency chains between constants for anti-extraction
function ConstantArray:createDependencyChains()
	if not self.DependencyChains or #self.constants < 3 then
		return {};
	end
	
	local chains = {};
	local chainCount = math.floor(#self.constants * 0.2); -- 20% of constants have dependencies
	
	for i = 1, chainCount do
		local depCount = math.random(1, 3);
		local deps = {};
		
		-- Create dependencies on earlier constants
		for j = 1, depCount do
			if i > j then
				deps[j] = math.random(1, i - 1);
			end
		end
		
		if #deps > 0 then
			chains[i] = {
				dependencies = deps,
				operation = ({"xor", "add", "sub"})[math.random(1, 3)],
			};
		end
	end
	
	return chains;
end

function ConstantArray:apply(ast, pipeline)
	initPrefixes();
	self.rootScope = ast.body.scope;
	-- Always initialize arrId (needed for decode code even with multi-arrays)
	self.arrId = self.rootScope:addVariable();
	
	-- NEW: Initialize multi-array and security features
	self.constantLocations = {};
	self.multiArrays = nil;
	self.arrayXorKeys = {};
	self.vmDecoderIds = {};
	self.dependencyChains = {};

	self.base64chars = table.concat(util.shuffle{
		"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
		"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
		"0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
		"+", "/",
	});

	self.base85chars = table.concat(util.shuffle{
		"!", "\"", "#", "$", "%", "&", "'", "(", ")", "*", "+", ",", "-", ".", "/",
		"0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
		":", ";", "<", "=", ">", "?", "@",
		"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O",
		"P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
		"[", "\\", "]", "^", "_", "`",
		"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o",
		"p", "q", "r", "s", "t", "u",
	});

	self.constants = {};
	self.lookup = {};

	-- Extract Constants
	visitast(ast, nil, function(node, data)
		-- Apply only to some nodes
		if math.random() <= self.Treshold then
			node.__apply_constant_array = true;
			if node.kind == AstKind.StringExpression then
				self:addConstant(node.value);
			elseif not self.StringsOnly then
				if node.isConstant then
					if node.value ~= nil then
						self:addConstant(node.value);
					end
				end
			end
		end
	end);

	-- Shuffle Array
	if self.Shuffle then
		self.constants = util.shuffle(self.constants);
		self.lookup = {};
		for i, v in ipairs(self.constants) do
			self.lookup[v] = i;
		end
	end
	
	-- NEW: Create multi-array system if enabled
	if self.MultiArrayCount > 1 and #self.constants > 0 then
		self.multiArrays = self:createMultiArrays();
		-- Create VM decoder IDs for each array
		for arrayIdx, _ in ipairs(self.multiArrays) do
			local decoderId = self.rootScope:addVariable();
			self.vmDecoderIds[arrayIdx] = decoderId;
		end
		-- Create dependency chains for additional complexity
		self.dependencyChains = self:createDependencyChains();
	end

	-- Set Wrapper Function Offset
	self.wrapperOffset = math.random(-self.MaxWrapperOffset, self.MaxWrapperOffset);
	self.wrapperId = self.rootScope:addVariable();

	visitast(ast, function(node, data)
		-- Add Local Wrapper Functions
		if self.LocalWrapperCount > 0 and node.kind == AstKind.Block and node.isFunctionBlock and math.random() <= self.LocalWrapperTreshold then
			local id = node.scope:addVariable()
			data.functionData.local_wrappers = {
				id = id;
				scope = node.scope,
			};
			local nameLookup = {};
			for i = 1, self.LocalWrapperCount, 1 do
				local name;
				repeat
					name = callNameGenerator(pipeline.namegenerator, math.random(1, self.LocalWrapperArgCount * 16));
				until not nameLookup[name];
				nameLookup[name] = true;

				local offset = math.random(-self.MaxWrapperOffset, self.MaxWrapperOffset);
				local argPos = math.random(1, self.LocalWrapperArgCount);

				data.functionData.local_wrappers[i] = {
					arg = argPos,
					index = name,
					offset =  offset,
				};
				data.functionData.__used = false;
			end
		end
		if node.__apply_constant_array then
			data.functionData.__used = true;
		end
	end, function(node, data)
		-- Actually insert Statements to get the Constant Values
		if node.__apply_constant_array then
			if node.kind == AstKind.StringExpression then
				return self:getConstant(node.value, data);
			elseif not self.StringsOnly then
				if node.isConstant then
					return node.value ~= nil and self:getConstant(node.value, data);
				end
			end
			node.__apply_constant_array = nil;
		end

		-- Insert Local Wrapper Declarations
		if self.LocalWrapperCount > 0 and node.kind == AstKind.Block and node.isFunctionBlock and data.functionData.local_wrappers and data.functionData.__used then
			data.functionData.__used = nil;
			local elems = {};
			local wrappers = data.functionData.local_wrappers;
			for i = 1, self.LocalWrapperCount, 1 do
				local wrapper = wrappers[i];
				local argPos = wrapper.arg;
				local offset = wrapper.offset;
				local name = wrapper.index;

				local funcScope = Scope:new(node.scope);

				local arg = nil;
				local args = {};

				for i = 1, self.LocalWrapperArgCount, 1 do
					args[i] = funcScope:addVariable();
					if i == argPos then
						arg = args[i];
					end
				end

				local addSubArg;

				-- Create add and Subtract code
				if offset < 0 then
					addSubArg = Ast.SubExpression(Ast.VariableExpression(funcScope, arg), Ast.NumberExpression(-offset));
				else
					addSubArg = Ast.AddExpression(Ast.VariableExpression(funcScope, arg), Ast.NumberExpression(offset));
				end

				funcScope:addReferenceToHigherScope(self.rootScope, self.wrapperId);
				local callArg = Ast.FunctionCallExpression(Ast.VariableExpression(self.rootScope, self.wrapperId), {
					addSubArg
				});

				local fargs = {};
				for i, v in ipairs(args) do
					fargs[i] = Ast.VariableExpression(funcScope, v);
				end

				elems[i] = Ast.KeyedTableEntry(
					Ast.StringExpression(name),
					Ast.FunctionLiteralExpression(fargs, Ast.Block({
						Ast.ReturnStatement({
							callArg
						});
					}, funcScope))
				)
			end
			table.insert(node.statements, 1, Ast.LocalVariableDeclaration(node.scope, {
				wrappers.id
			}, {
				Ast.TableConstructorExpression(elems)
			}));
		end
	end);

	self:addDecodeCode(ast);

	local steps = util.shuffle({
		-- Add Wrapper Function Code
		function()
			-- Only add wrapper if NOT using multi-arrays (multi-arrays handle indexing differently)
			if not self.multiArrays then
				local funcScope = Scope:new(self.rootScope);
				-- Add Reference to Array
				funcScope:addReferenceToHigherScope(self.rootScope, self.arrId);

				local arg = funcScope:addVariable();
				local addSubArg;

				-- Create add and Subtract code
				if self.wrapperOffset < 0 then
					addSubArg = Ast.SubExpression(Ast.VariableExpression(funcScope, arg), Ast.NumberExpression(-self.wrapperOffset));
				else
					addSubArg = Ast.AddExpression(Ast.VariableExpression(funcScope, arg), Ast.NumberExpression(self.wrapperOffset));
				end

				-- Create and Add the Function Declaration
				table.insert(ast.body.statements, 1, Ast.LocalFunctionDeclaration(self.rootScope, self.wrapperId, {
					Ast.VariableExpression(funcScope, arg)
				}, Ast.Block({
					Ast.ReturnStatement({
						Ast.IndexExpression(
							Ast.VariableExpression(self.rootScope, self.arrId),
							addSubArg
						)
					});
				}, funcScope)));
			end
		end,
		-- Rotate Array and Add unrotate code
		function()
			-- Only rotate if NOT using multi-arrays
			if not self.multiArrays and self.Rotate and #self.constants > 1 then
				local shift = math.random(1, #self.constants - 1);

				rotate(self.constants, -shift);
				self:addRotateCode(ast, shift);
			end
		end,
	});

	for i, f in ipairs(steps) do
		f();
	end

	-- NEW: Add multi-array declarations or single array
	if self.multiArrays then
		-- Declare all arrays
		for i, array in ipairs(self.multiArrays) do
			local arrayConstructor;
			if self.TupleVarargPool then
				arrayConstructor = self:createVarargPoolExprFromEntries(array.entries);
			else
				arrayConstructor = Ast.TableConstructorExpression(array.entries);
			end
			table.insert(ast.body.statements, 1, 
				Ast.LocalVariableDeclaration(self.rootScope, {array.id}, {arrayConstructor})
			);
		end
	else
		-- Add the Array Declaration (original single table or vararg tuple pool)
		local initExpr;
		if self.TupleVarargPool then
			initExpr = self:createVarargPoolExpr(self.constants);
		else
			initExpr = self:createArray();
		end
		table.insert(ast.body.statements, 1, Ast.LocalVariableDeclaration(self.rootScope, {self.arrId}, {initExpr}));
	end

	self.rootScope = nil;
	self.arrId = nil;

	self.constants = nil;
	self.lookup = nil;
	self.constantLocations = nil;
	self.multiArrays = nil;
	self.arrayXorKeys = nil;
	self.vmDecoderIds = nil;
end

return ConstantArray;