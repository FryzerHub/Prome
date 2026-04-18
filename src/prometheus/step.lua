-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- step.lua
--
-- This Script provides the base class for Obfuscation Steps

local logger = require("logger");
local util = require("prometheus.util");

local lookupify = util.lookupify;

local Step = {};

Step.SettingsDescriptor = {}

function Step:new(settings)
	local instance = {};
	setmetatable(instance, self);
	self.__index = self;

	if type(settings) ~= "table" then
		settings = {};
	end

	-- Be tolerant to common config key typos/variants.
	-- This prevents presets from silently not applying intended settings.
	local normalized = {};
	for k, v in pairs(settings) do
		if type(k) == "string" then
			normalized[k] = v;
			normalized[string.lower(k)] = v;
		end
	end
	local function pickSetting(key)
		if settings[key] ~= nil then
			return settings[key];
		end
		if type(key) ~= "string" then
			return nil;
		end
		if normalized[key] ~= nil then
			return normalized[key];
		end
		local lk = string.lower(key);
		if normalized[lk] ~= nil then
			return normalized[lk];
		end
		-- Known legacy/preset typos
		if key == "Treshold" then
			return normalized["threshold"];
		elseif key == "Threshold" then
			return normalized["treshold"];
		elseif key == "LocalWrapperTreshold" then
			return normalized["localwrapperthreshold"] or normalized["localwrappertreshold"];
		elseif key == "LocalWrapperThreshold" then
			return normalized["localwrappertreshold"] or normalized["localwrapperthreshold"];
		elseif key == "NumberRepresentationMutaton" then
			return normalized["numberrepresentationmutation"] or normalized["numberrepresentationmutaton"];
		elseif key == "NumberRepresentationMutation" then
			return normalized["numberrepresentationmutaton"] or normalized["numberrepresentationmutation"];
		end
		return nil;
	end

	for key, data in pairs(self.SettingsDescriptor) do
		local provided = pickSetting(key);
		if provided == nil then
			if data.default == nil then
				logger:error(string.format("The Setting \"%s\" was not provided for the Step \"%s\"", key, self.Name));
			end
			instance[key] = data.default;
		elseif(data.type == "enum") then
			local lookup = lookupify(data.values);
			if not lookup[provided] then
				logger:error(string.format("Invalid value for the Setting \"%s\" of the Step \"%s\". It must be one of the following: %s", key, self.Name, table.concat(data, ", ")));
			end
			instance[key] = provided;
		elseif(type(provided) ~= data.type) then
			logger:error(string.format("Invalid value for the Setting \"%s\" of the Step \"%s\". It must be a %s", key, self.Name, data.type));
		else
			if data.min then
				if  provided < data.min then
					logger:error(string.format("Invalid value for the Setting \"%s\" of the Step \"%s\". It must be at least %d", key, self.Name, data.min));
				end
			end

			if data.max then
				if  provided > data.max then
					logger:error(string.format("Invalid value for the Setting \"%s\" of the Step \"%s\". The biggest allowed value is %d", key, self.Name, data.min));
				end
			end

			instance[key] = provided;
		end
	end

	instance:init();

	return instance;
end

function Step:init()
	logger:error("Abstract Steps cannot be Created");
end

function Step:extend()
	local ext = {};
	setmetatable(ext, self);
	self.__index = self;
	return ext;
end

function Step:apply(ast, pipeline)
	logger:error("Abstract Steps cannot be Applied")
end

Step.Name = "Abstract Step";
Step.Description = "Abstract Step";

return Step;
