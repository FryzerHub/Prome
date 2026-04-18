-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- logger.lua
-- This file provides Logging Utilities

local colors = require("prometheus.colors");

local Logger = {
	LogLevel = {
		Error   = 0,
		Warning = 1,
		Success = 2,
		Info    = 3,
		Debug   = 4,
	},
	logLevel = 3, -- Default to Info level
};

function Logger:log(level, message, ...)
	if self.logLevel < level then
		return;
	end

	local prefix;
	local color;
	if level == self.LogLevel.Error then
		prefix = "[ERROR]   ";
		color = "red";
	elseif level == self.LogLevel.Warning then
		prefix = "[WARNING] ";
		color = "yellow";
	elseif level == self.LogLevel.Success then
		prefix = "[SUCCESS] ";
		color = "green";
	elseif level == self.LogLevel.Info then
		prefix = "[INFO]    ";
		color = "blue";
	elseif level == self.LogLevel.Debug then
		prefix = "[DEBUG]   ";
		color = "magenta";
	end

	local msg = string.format(message, ...);
	print(colors(prefix, color) .. msg);
end

function Logger:error(message, ...)
	self:log(self.LogLevel.Error, message, ...);
end

function Logger:warn(message, ...)
	self:log(self.LogLevel.Warning, message, ...);
end

function Logger:success(message, ...)
	self:log(self.LogLevel.Success, message, ...);
end

function Logger:info(message, ...)
	self:log(self.LogLevel.Info, message, ...);
end

function Logger:debug(message, ...)
	self:log(self.LogLevel.Debug, message, ...);
end

return Logger;