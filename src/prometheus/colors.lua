-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- colors.lua
-- This file provides ANSI color utilities for console output

local colors = {
	reset = "\27[0m",
	
	-- Foreground colors
	black = "\27[30m",
	red = "\27[31m",
	green = "\27[32m",
	yellow = "\27[33m",
	blue = "\27[34m",
	magenta = "\27[35m",
	cyan = "\27[36m",
	white = "\27[37m",
	
	-- Bright foreground colors
	brightBlack = "\27[90m",
	brightRed = "\27[91m",
	brightGreen = "\27[92m",
	brightYellow = "\27[93m",
	brightBlue = "\27[94m",
	brightMagenta = "\27[95m",
	brightCyan = "\27[96m",
	brightWhite = "\27[97m",
	
	-- Background colors
	bgBlack = "\27[40m",
	bgRed = "\27[41m",
	bgGreen = "\27[42m",
	bgYellow = "\27[43m",
	bgBlue = "\27[44m",
	bgMagenta = "\27[45m",
	bgCyan = "\27[46m",
	bgWhite = "\27[47m",
	
	-- Text styles
	bold = "\27[1m",
	dim = "\27[2m",
	italic = "\27[3m",
	underline = "\27[4m",
	blink = "\27[5m",
	reverse = "\27[7m",
	hidden = "\27[8m",
};

local colorsEnabled = true;

-- Function to enable/disable colors globally
local function setColorsEnabled(enabled)
	colorsEnabled = enabled;
end

-- Main color function
local function colorize(text, colorName)
	if not colorsEnabled then
		return text;
	end
	
	local colorCode = colors[colorName];
	if not colorCode then
		return text;
	end
	
	return colorCode .. text .. colors.reset;
end

-- Set module as callable
setmetatable(colors, {
	__call = function(_, text, colorName)
		return colorize(text, colorName);
	end
});

-- Export functions
colors.colorize = colorize;
colors.setEnabled = setColorsEnabled;

return colors;