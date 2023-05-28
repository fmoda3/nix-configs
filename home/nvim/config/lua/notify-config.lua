require("notify").setup({})

local colors = require("nord-colors")
local util = require("util")
util.colorize({
	-- Error
	NotifyERRORBorder = { fg = colors.nord11_gui },
	NotifyERRORIcon = { fg = colors.nord11_gui },
	NotifyERRORTitle = { fg = colors.nord11_gui },
	-- Warn
	NotifyWARNBorder = { fg = colors.nord13_gui },
	NotifyWARNIcon = { fg = colors.nord13_gui },
	NotifyWARNTitle = { fg = colors.nord13_gui },
	-- Info
	NotifyINFOBorder = { fg = colors.nord14_gui },
	NotifyINFOIcon = { fg = colors.nord14_gui },
	NotifyINFOTitle = { fg = colors.nord14_gui },
	-- Debug
	NotifyDEBUGBorder = { fg = colors.nord10_gui },
	NotifyDEBUGIcon = { fg = colors.nord10_gui },
	NotifyDEBUGTitle = { fg = colors.nord10_gui },
	-- Trace
	NotifyTRACEBorder = { fg = colors.nord15_gui },
	NotifyTRACEIcon = { fg = colors.nord15_gui },
	NotifyTRACETitle = { fg = colors.nord15_gui },
})
