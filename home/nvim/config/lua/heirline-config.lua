local conditions = require("heirline.conditions")
local utils = require("heirline.utils")

local Align = {
	provider = "%=",
	hl = {
		fg = colors.nord0_gui,
		bg = colors.nord0_gui,
	},
}
local Space = { provider = " " }
local LeftSeparator = ""
local RightSeparator = ""
local CircleIcon = ""

local WhiteSpace = {
	provider = " ",
	hl = {
		fg = colors.nord3_gui,
		bg = colors.nord5_gui,
	},
}

local GreySpace = {
	provider = " ",
	hl = {
		fg = colors.nord3_gui,
		bg = colors.nord3_gui,
	},
}

-- Left Side Components
local LeftSideLeftSeparator = {
	provider = LeftSeparator,
	hl = {
		fg = colors.nord5_gui,
		bg = colors.nord0_gui,
	},
}

local CircleComponent = {
	provider = CircleIcon,
	hl = {
		fg = colors.nord3_gui,
		bg = colors.nord5_gui,
	},
}

local FileNameBlock = {
	init = function(self)
		self.filename = vim.api.nvim_buf_get_name(0)
	end,
}

local FileIcon = {
	init = function(self)
		local filename = self.filename
		local extension = vim.fn.fnamemodify(filename, ":e")
		self.icon, self.icon_color =
			require("nvim-web-devicons").get_icon_color(filename, extension, { default = true })
	end,
	provider = function(self)
		return self.icon and (self.icon .. " ")
	end,
	hl = function(self)
		return {
			fg = self.icon_color,
			bg = colors.nord3_gui,
		}
	end,
}

local FileName = {
	provider = function(self)
		local filename = vim.fn.fnamemodify(self.filename, ":.")
		if filename == "" then
			return "[No Name]"
		end
		if not conditions.width_percent_below(#filename, 0.25) then
			filename = vim.fn.pathshorten(filename)
		end
		return filename
	end,
	hl = {
		fg = colors.nord6_gui,
		bg = colors.nord3_gui,
	},
}

local FileFlags = {
	{
		condition = function()
			return vim.bo.modified
		end,
		provider = " ",
		hl = {
			fg = colors.nord6_gui,
			bg = colors.nord3_gui,
		},
	},
	{
		condition = function()
			return not vim.bo.modifiable or vim.bo.readonly
		end,
		provider = " ",
		hl = {
			fg = colors.nord6_gui,
			bg = colors.nord3_gui,
		},
	},
}

local FileSize = {
	provider = function()
		-- stackoverflow, compute human readable file size
		local suffix = { "b", "k", "M", "G", "T", "P", "E" }
		local fsize = vim.fn.getfsize(vim.api.nvim_buf_get_name(0))
		fsize = (fsize < 0 and 0) or fsize
		if fsize < 1024 then
			return fsize .. suffix[1]
		end
		local i = math.floor((math.log(fsize) / math.log(1024)))
		return string.format("%.2g%s", fsize / math.pow(1024, i), suffix[i + 1])
	end,
	hl = {
		fg = colors.nord6_gui,
		bg = colors.nord3_gui,
	},
}

FileNameBlock =
	utils.insert(FileNameBlock, GreySpace, FileIcon, FileName, FileFlags, { provider = "%<" }, GreySpace, FileSize)

local LeftSideRightSeparator = {
	provider = RightSeparator,
	hl = {
		fg = colors.nord3_gui,
		bg = colors.nord0_gui,
	},
}

local LeftComponent = {
	LeftSideLeftSeparator,
	CircleComponent,
	WhiteSpace,
	FileNameBlock,
	LeftSideRightSeparator,
}

-- Middle Components
local MiddleLeftSeparator = {
	provider = LeftSeparator,
	hl = {
		fg = colors.nord3_gui,
		bg = colors.nord0_gui,
	},
}

local LSPActive = {
	condition = conditions.lsp_attached,
	update = { "LspAttach", "LspDetach" },
	provider = function()
		local names = {}
		for i, server in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
			table.insert(names, server.name)
		end
		return " [" .. table.concat(names, " ") .. "]"
	end,
	hl = {
		fg = colors.nord15_gui,
		bg = colors.nord3_gui,
	},
}

local error_icon = vim.diagnostic.config()["signs"]["text"][vim.diagnostic.severity.ERROR]
local warn_icon = vim.diagnostic.config()["signs"]["text"][vim.diagnostic.severity.WARN]
local info_icon = vim.diagnostic.config()["signs"]["text"][vim.diagnostic.severity.INFO]
local hint_icon = vim.diagnostic.config()["signs"]["text"][vim.diagnostic.severity.HINT]

local Diagnostics = {
	condition = conditions.has_diagnostics,
	init = function(self)
		self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
		self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
		self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
		self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
	end,
	update = { "DiagnosticChanged", "BufEnter" },
	{
		provider = function(self)
			-- 0 is just another output, we can decide to print it or not!
			return self.errors > 0 and (" " .. error_icon .. self.errors)
		end,
		hl = {
			fg = colors.nord11_gui,
			bg = colors.nord3_gui,
		},
	},
	{
		provider = function(self)
			return self.warnings > 0 and (" " .. warn_icon .. self.warnings)
		end,
		hl = {
			fg = colors.nord12_gui,
			bg = colors.nord3_gui,
		},
	},
	{
		provider = function(self)
			return self.info > 0 and (" " .. info_icon .. self.info)
		end,
		hl = {
			fg = colors.nord14_gui,
			bg = colors.nord3_gui,
		},
	},
	{
		provider = function(self)
			return self.hints > 0 and (" " .. hint_icon .. self.hints)
		end,
		hl = {
			fg = colors.nord10_gui,
			bg = colors.nord3_gui,
		},
	},
}

local MiddleRightSeparator = {
	provider = RightSeparator,
	hl = {
		fg = colors.nord3_gui,
		bg = colors.nord0_gui,
	},
}

local MiddleComponent = {
	condition = function()
		return conditions.lsp_attached() or conditions.has_diagnostics()
	end,
	MiddleLeftSeparator,
	LSPActive,
	Diagnostics,
	MiddleRightSeparator,
}

-- Right components
local Git = {
	condition = conditions.is_git_repo,
	init = function(self)
		self.status_dict = vim.b.gitsigns_status_dict
		self.has_changes = self.status_dict.added ~= 0 or self.status_dict.removed ~= 0 or self.status_dict.changed ~= 0
	end,
	hl = {
		fg = colors.nord10_gui,
		bg = colors.nord0_gui,
	},
	{ -- git branch name
		provider = function(self)
			return " " .. self.status_dict.head .. " "
		end,
		hl = { bold = true },
	},
	{
		provider = function(self)
			local count = self.status_dict.added or 0
			return count > 0 and (" " .. count .. " ")
		end,
		hl = {
			fg = colors.nord14_gui,
			bg = colors.nord0_gui,
		},
	},
	{
		provider = function(self)
			local count = self.status_dict.changed or 0
			return count > 0 and (" " .. count .. " ")
		end,
		hl = {
			fg = colors.nord13_gui,
			bg = colors.nord0_gui,
		},
	},
	{
		provider = function(self)
			local count = self.status_dict.removed or 0
			return count > 0 and (" " .. count .. " ")
		end,
		hl = {
			fg = colors.nord11_gui,
			bg = colors.nord0_gui,
		},
	},
}

local mode_names = {
	n = "Normal",
	no = "Normal-Operator Pending",
	nov = "Normal-Operator Pending-Visual",
	noV = "Normal-Operator Pending-Visual Line",
	["no\22"] = "Normal-Operator Pending-Visual Block",
	niI = "Normal-Insert",
	niR = "Normal-Replace",
	niV = "Normal-Visual",
	nt = "Normal-Terminal",
	v = "Visual",
	vs = "Visual-Select",
	V = "Visual Line",
	Vs = "Visual Line-Select",
	["\22"] = "Visual Block",
	["\22s"] = "Visual Block-Select",
	s = "Select",
	S = "Select Line",
	["\19"] = "Select Block",
	i = "Insert",
	ic = "Insert-Completion",
	ix = "Insert-Completion Extended",
	R = "Replace",
	Rc = "Replace-Completion",
	Rx = "Replace-Completion Extended",
	Rv = "Replace-Virtual",
	Rvc = "Replace-Virtual-Completion",
	Rvx = "Replace-Virtual-Completion Extended",
	c = "Command",
	cv = "Ex Mode",
	r = "Prompt",
	rm = "More Prompt",
	["r?"] = "Confirm Prompt",
	["!"] = "Shell",
	t = "Terminal",
}

local mode_colors = {
	n = { fg = colors.nord3_gui, bg = colors.nord8_gui },
	i = { fg = colors.nord3_gui, bg = colors.nord6_gui },
	v = { fg = colors.nord3_gui, bg = colors.nord7_gui },
	V = { fg = colors.nord3_gui, bg = colors.nord7_gui },
	["\22"] = { fg = colors.nord3_gui, bg = colors.nord7_gui },
	c = { fg = colors.nord3_gui, bg = colors.nord12_gui },
	s = { fg = colors.nord3_gui, bg = colors.nord15_gui },
	S = { fg = colors.nord3_gui, bg = colors.nord15_gui },
	["\19"] = { fg = colors.nord3_gui, bg = colors.nord15_gui },
	R = { fg = colors.nord3_gui, bg = colors.nord13_gui },
	r = { fg = colors.nord3_gui, bg = colors.nord13_gui },
	["!"] = { fg = colors.nord3_gui, bg = colors.nord11_gui },
	t = { fg = colors.nord3_gui, bg = colors.nord11_gui },
}

local ViMode = {
	init = function(self)
		self.mode = vim.fn.mode(1) -- :h mode()
	end,
	update = {
		"ModeChanged",
		pattern = "*:*",
		callback = vim.schedule_wrap(function()
			vim.cmd("redrawstatus")
		end),
	},
	{
		provider = LeftSeparator,
		hl = function(self)
			local mode = self.mode:sub(1, 1) -- get only the first mode character
			return { fg = mode_colors[mode].bg, bg = colors.nord0_gui }
		end,
	},
	{
		provider = function(self)
			return " " .. mode_names[self.mode] .. " "
		end,
		hl = function(self)
			local mode = self.mode:sub(1, 1) -- get only the first mode character
			return mode_colors[mode]
		end,
	},
}

local Ruler = {
	-- %l = current line number
	-- %L = number of lines in the buffer
	-- %c = column number
	-- %P = percentage through file of displayed window
	provider = " %(%-l/%3L%):%c %P ",
	hl = {
		fg = colors.nord3_gui,
		bg = colors.nord5_gui,
	},
}

local RideSideRightSeparator = {
	provider = RightSeparator,
	hl = {
		fg = colors.nord5_gui,
		bg = colors.nord0_gui,
	},
}

local RightComponent = {
	Git,
	ViMode,
	Ruler,
	RideSideRightSeparator,
}

-- Miscellaneous
local FileType = {
	provider = function()
		return string.upper(vim.bo.filetype)
	end,
	hl = { fg = utils.get_highlight("Type").fg, bold = true },
}

local TerminalName = {
	provider = function()
		local tname, _ = vim.api.nvim_buf_get_name(0):gsub(".*:", "")
		return "  " .. tname
	end,
	hl = {
		fg = colors.nord6_gui,
		bg = colors.nord3_gui,
	},
}

local HelpFileName = {
	condition = function()
		return vim.bo.filetype == "help"
	end,
	provider = function()
		local filename = vim.api.nvim_buf_get_name(0)
		return " " .. vim.fn.fnamemodify(filename, ":t")
	end,
	hl = {
		fg = colors.nord6_gui,
		bg = colors.nord3_gui,
	},
}

local DefaultStatusline = {
	LeftComponent,
	Align,
	MiddleComponent,
	Align,
	RightComponent,
}

local InactiveStatusline = {
	condition = conditions.is_not_active,
	LeftComponent,
	Align,
}

local HelpStatusline = {
	condition = function()
		return conditions.buffer_matches({
			buftype = { "help" },
		})
	end,
	LeftSideLeftSeparator,
	CircleComponent,
	WhiteSpace,
	HelpFileName,
	LeftSideRightSeparator,
	Align,
}

local SpecialLeftSideRightSeparator = {
	provider = RightSeparator,
	hl = {
		fg = colors.nord5_gui,
		bg = colors.nord0_gui,
	},
}

local SpecialStatusline = {
	condition = function()
		return conditions.buffer_matches({
			buftype = { "nofile", "prompt", "quickfix" },
			filetype = { "^git.*", "fugitive" },
		})
	end,
	LeftSideLeftSeparator,
	CircleComponent,
	SpecialLeftSideRightSeparator,
	Align,
}

local TerminalStatusline = {
	condition = function()
		return conditions.buffer_matches({ buftype = { "terminal" } })
	end,
	LeftSideLeftSeparator,
	CircleComponent,
	WhiteSpace,
	TerminalName,
	LeftSideRightSeparator,
	Align,
}

local StatusLines = {
	hl = function()
		if conditions.is_active() then
			return "StatusLine"
		else
			return "StatusLineNC"
		end
	end,
	fallthrough = false,
	HelpStatusline,
	SpecialStatusline,
	TerminalStatusline,
	InactiveStatusline,
	DefaultStatusline,
}

require("heirline").setup({ statusline = StatusLines })
