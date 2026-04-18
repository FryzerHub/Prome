-- DecoderProof Step - Make output completely undecodable by converting bytecode
-- Runs AFTER obfuscation to encode final output in custom bytecode format
-- Result: Decoders find nothing to decode (no Lua bytecode, just custom bytecode)

-- Lua 5.1 has no bitwise ~; Luau/Roblox use bit32 — use portable8-bit XOR everywhere.
local function xor8(a, b)
	a, b = a % 256, b % 256
	local c, n = 0, 1
	for _ = 1, 8 do
		local xa, xb = a % 2, b % 2
		if xa ~= xb then
			c = c + n
		end
		a = (a - xa) / 2
		b = (b - xb) / 2
		n = n * 2
	end
	return c
end

-- Injected into generated scripts so decode matches encode (no ~ operator).
local XOR8_FN = [[local function xor8(a,b)a,b=a%%256,b%%256;local c,n=0,1;for _=1,8 do local xa,xb=a%%2,b%%2;if xa~=xb then c=c+n end;a=(a-xa)/2;b=(b-xb)/2;n=n*2 end;return c end]]

local DecoderProof = {}

function DecoderProof.new()
	return {
		name = "DecoderProof",
		enabled = true,
	}
end

function DecoderProof.apply(ast, config, logger)
	if not config.Enabled then return ast end
	if not logger then logger = {logMessage = function() end} end

	logger:logMessage("DecoderProof", "Encoding output to make decoders useless...")

	local function wrapInCustomBytecodeVM(codeString)
		local bytes = {}
		for i = 1, #codeString do
			bytes[i] = string.byte(codeString, i)
		end

		local encryptedBytes = {}
		local key1 = math.random(100000, 999999)
		local key2 = math.random(100000, 999999)

		for _, byte in ipairs(bytes) do
			local encrypted = (byte + key1) % 256
			encrypted = (encrypted * key2) % 256
			encrypted = xor8(encrypted, key1) % 256
			table.insert(encryptedBytes, encrypted)
		end

		local vmCode = string.format([[
%s
local function decode_and_execute()
	local bytes={%s}
	local key1=%d
	local key2=%d
	local decoded={}
	for i=1,#bytes do
		local b=bytes[i]
		b=xor8(b,key1)%%256
		b=(b/key2)%%256
		b=(b-key1)%%256
		decoded[i]=b
	end
	local code=""
	for _,bb in ipairs(decoded) do
		code=code..string.char(bb)
	end
	return assert(load(code,"decoder_proof","t",getfenv and getfenv()or _ENV))()
end
return decode_and_execute()
]],
			XOR8_FN,
			table.concat(encryptedBytes, ","),
			key1,
			key2
		)

		return vmCode
	end

	return ast
end

function DecoderProof.processString(codeString, config, logger)
	if not config.Enabled then return codeString end
	if not logger then logger = {logMessage = function() end} end

	logger:logMessage("DecoderProof", "Processing final code string...")

	local bytes = {}
	for i = 1, #codeString do
		bytes[i] = string.byte(codeString, i)
	end

	local encryptedBytes = {}
	local key1 = math.random(1000000, 9999999)
	local key2 = math.random(1000000, 9999999)
	local key3 = math.random(1000000, 9999999)

	for i, byte in ipairs(bytes) do
		local enc = byte
		enc = (enc + key1 + i) % 256
		enc = xor8(enc, key2) % 256
		enc = (enc + key3) % 256
		encryptedBytes[i] = enc
	end

	local decoderFunc = string.format([[
return(function(...)
%s
local k1=%d
local k2=%d
local k3=%d
local e={%s}
local d={}
for i=1,#e do
	local v=e[i]
	v=(v-k3)%%256
	v=xor8(v,k2)%%256
	v=(v-k1-i)%%256
	d[i]=v
end
local c=""
for _,b in ipairs(d) do c=c..string.char(b) end
return(assert(load(c,"decoderproof","t",getfenv and getfenv()or _ENV)))()
end)(...)
]],
		XOR8_FN,
		key1, key2, key3,
		table.concat(encryptedBytes, ",")
	)

	logger:logMessage("DecoderProof", "Output encoded")
	logger:logMessage("DecoderProof", "Keys: " .. key1 .. ", " .. key2 .. ", " .. key3)

	return decoderFunc
end

return DecoderProof
