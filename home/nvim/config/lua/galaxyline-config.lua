-- This file configures galaxyline, a fast and small statusline for nvim.
-- The configuration was taken from github.com/siduck76/neovim-dotfiles/
-- All I did was change the colors. Full credit goes to siduck76

local gl = require("galaxyline")
local gls = gl.section
local condition = require("galaxyline.condition")

gl.short_line_list = { "NvimTree", "minimap" }

vim.api.nvim_command("hi GalaxyLineFillSection guibg=NONE")

local colors = require("nord-colors")

gls.left[1] = {
	leftStart = {
		provider = function()
			return ""
		end,
		highlight = { colors.nord5_gui, colors.nord0_gui },
	},
}

gls.left[2] = {
	statusIcon = {
		provider = function()
			return "  "
		end,
		highlight = { colors.nord3_gui, colors.nord5_gui },
		separator = " ",
		separator_highlight = { colors.nord2_gui, colors.nord3_gui },
	},
}

gls.left[3] = {
	FileIcon = {
		provider = "FileIcon",
		condition = condition.buffer_not_empty,
		highlight = { require("galaxyline.providers.fileinfo").get_file_icon_color, colors.nord3_gui },
	},
}

gls.left[4] = {
	FileName = {
		provider = { "FileName", "FileSize" },
		condition = condition.buffer_not_empty,
		highlight = { colors.nord6_gui, colors.nord3_gui },
	},
}

gls.left[5] = {
	leftEnd = {
		provider = function()
			return ""
		end,
		separator = " ",
		highlight = { colors.nord3_gui, colors.nord0_gui },
	},
}

gls.mid[1] = {
	midStart = {
		provider = function()
			return ""
		end,
		highlight = { colors.nord3_gui, colors.nord0_gui },
	},
}

gls.mid[2] = {
	lspIcon = {
		provider = function()
			return ""
		end,
		highlight = { colors.nord15_gui, colors.nord3_gui },
	},
}

gls.mid[3] = {
	GetLspClient = {
		provider = "GetLspClient",
		separator = { " ", " " },
		separator_highlight = { colors.nord3_gui, colors.nord3_gui },
		highlight = { colors.nord15_gui, colors.nord3_gui },
	},
}

gls.mid[4] = {
	DiagnosticError = {
		provider = "DiagnosticError",
		icon = " ",
		highlight = { colors.nord11_gui, colors.nord3_gui },
	},
}

gls.mid[5] = {
	DiagnosticWarn = {
		provider = "DiagnosticWarn",
		icon = " ",
		highlight = { colors.nord12_gui, colors.nord3_gui },
	},
}

gls.mid[7] = {
	DiagnosticInfo = {
		provider = "DiagnosticInfo",
		icon = "\u{f05a} ",
		highlight = { colors.nord11_gui, colors.nord3_gui },
	},
}

gls.mid[8] = {
	DiagnosticHint = {
		provider = "DiagnosticHint",
		icon = " ",
		highlight = { colors.nord10_gui, colors.nord3_gui },
	},
}

gls.mid[9] = {
	midEnd = {
		provider = function()
			return ""
		end,
		highlight = { colors.nord3_gui, colors.nord0_gui },
	},
}

gls.right[1] = {
	GitIcon = {
		provider = function()
			return ""
		end,
		condition = require("galaxyline.providers.vcs").check_git_workspace,
		highlight = { colors.nord10_gui, colors.nord0_gui },
	},
}

gls.right[2] = {
	GitBranch = {
		provider = "GitBranch",
		condition = require("galaxyline.providers.vcs").check_git_workspace,
		separator = " ",
		separator_highlight = { colors.nord0_gui, colors.nord0_gui },
		highlight = { colors.nord10_gui, colors.nord0_gui },
	},
}

gls.right[3] = {
	GitSpace = {
		provider = function()
			return " "
		end,
		condition = require("galaxyline.providers.vcs").check_git_workspace,
		highlight = { colors.nord0_gui, colors.nord0_gui },
	},
}

gls.right[4] = {
	DiffAdd = {
		provider = "DiffAdd",
		condition = condition.hide_in_width,
		icon = " ",
		highlight = { colors.nord14_gui, colors.nord0_gui },
	},
}

gls.right[5] = {
	DiffModified = {
		provider = "DiffModified",
		condition = condition.hide_in_width,
		icon = " ",
		highlight = { colors.nord12_gui, colors.nord0_gui },
	},
}

gls.right[6] = {
	DiffRemove = {
		provider = "DiffRemove",
		condition = condition.hide_in_width,
		icon = " ",
		highlight = { colors.nord13_gui, colors.nord0_gui },
	},
}

gls.right[7] = {
	rightStart = {
		provider = function()
			return ""
		end,
		separator = " ",
		separator_highlight = { colors.nord0_gui, colors.nord0_gui },
		highlight = { colors.nord8_gui, colors.nord0_gui },
	},
}

gls.right[8] = {
	ViMode = {
		provider = function()
			local alias = {
				n = "NORMAL",
				i = "INSERT",
				c = "COMMAND",
				V = "VISUAL",
				[""] = "VISUAL",
				v = "VISUAL",
				R = "REPLACE",
			}
			return alias[vim.fn.mode()]
		end,
		highlight = { colors.nord3_gui, colors.nord8_gui },
	},
}

gls.right[9] = {
	PerCent = {
		provider = "LinePercent",
		separator = " ",
		separator_highlight = { colors.nord3_gui, colors.nord8_gui },
		highlight = { colors.nord3_gui, colors.nord5_gui },
	},
}

gls.right[10] = {
	rightEnd = {
		provider = function()
			return ""
		end,
		highlight = { colors.nord5_gui, colors.nord0_gui },
	},
}
