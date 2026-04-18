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
	colorsEnabled = true,
};

function Logger:setLogLevel(level)
	self.logLevel = level;
end

function Logger:setColorsEnabled(enabled)
	self.colorsEnabled = enabled;
	colors.setEnabled(enabled);
end

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
	else
		prefix = "[LOG]     ";
		color = "white";
	end

	local msg;
	if select("#", ...) > 0 then
		msg = string.format(message, ...);
	else
		msg = tostring(message);
	end
	
	if self.colorsEnabled then
		print(colors(prefix, color) .. msg);
	else
		print(prefix .. msg);
	end
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