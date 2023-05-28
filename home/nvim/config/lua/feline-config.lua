local colors = require("nord-colors")

local components = {
	active = { {}, {}, {} },
	inactive = {},
}

-- Disable status bar on these buffers
local disable = {
	filetypes = {
		"^NvimTree$",
		"^packer$",
		"^startify$",
		"^fugitive$",
		"^fugitiveblame$",
		"^qf$",
		"^help$",
		"^minimap$",
		"^Trouble$",
		"^dap-repl$",
		"^dapui_watches$",
		"^dapui_stacks$",
		"^dapui_breakpoints$",
		"^dapui_scopes$",
	},
	buftypes = {
		"^terminal$",
	},
	bufnames = {},
}

-- Better lsp client retrieval than built in
local get_lsp_client = function(component)
	local msg = "No Active Lsp"

	local clients = vim.lsp.buf_get_clients()
	if next(clients) == nil then
		return msg
	end

	local client_names = ""
	for _, client in pairs(clients) do
		if string.len(client_names) < 1 then
			client_names = client_names .. client.name
		else
			client_names = client_names .. ", " .. client.name
		end
	end
	return string.len(client_names) > 0 and client_names or msg
end

-- LEFT
-- Circle icon
components.active[1][1] = {
	provider = "",
	hl = {
		fg = colors.nord3_gui,
		bg = colors.nord5_gui,
	},
	left_sep = {
		str = "left_rounded",
		hl = {
			fg = colors.nord5_gui,
			bg = colors.nord0_gui,
		},
	},
	right_sep = {
		str = " ",
		hl = {
			fg = colors.nord3_gui,
			bg = colors.nord5_gui,
		},
	},
}

-- File icon, name, status
components.active[1][2] = {
	provider = {
		name = "file_info",
		opts = {
			file_readonly_icon = "",
			file_modified_icon = "",
		},
	},
	-- enabled = buffer_not_empty,
	hl = {
		fg = colors.nord6_gui,
		bg = colors.nord3_gui,
	},
	left_sep = {
		str = " ",
		hl = {
			fg = colors.nord3_gui,
			bg = colors.nord3_gui,
		},
	},
	right_sep = {
		str = " ",
		hl = {
			fg = colors.nord3_gui,
			bg = colors.nord3_gui,
		},
	},
}

-- File size
components.active[1][3] = {
	provider = "file_size",
	-- enabled = buffer_not_empty,
	hl = {
		fg = colors.nord6_gui,
		bg = colors.nord3_gui,
	},
}

-- End of left side
components.active[1][4] = {
	provider = "",
	hl = {
		fg = colors.nord3_gui,
		bg = colors.nord0_gui,
	},
}

-- Middle
-- LSP icon
components.active[2][1] = {
	provider = "",
	hl = {
		fg = colors.nord15_gui,
		bg = colors.nord3_gui,
	},
	left_sep = {
		str = "left_rounded",
		hl = {
			fg = colors.nord3_gui,
			bg = colors.nord0_gui,
		},
	},
	right_sep = {
		str = " ",
		hl = {
			fg = colors.nord3_gui,
			bg = colors.nord3_gui,
		},
	},
}

-- LSP client names
components.active[2][2] = {
	provider = get_lsp_client,
	hl = {
		fg = colors.nord15_gui,
		bg = colors.nord3_gui,
	},
}

-- LSP errors
components.active[2][3] = {
	provider = "diagnostic_errors",
	hl = {
		fg = colors.nord11_gui,
		bg = colors.nord3_gui,
	},
}

-- LSP warns
components.active[2][4] = {
	provider = "diagnostic_warnings",
	hl = {
		fg = colors.nord12_gui,
		bg = colors.nord3_gui,
	},
}

-- LSP infos
components.active[2][5] = {
	provider = "diagnostic_info",
	hl = {
		fg = colors.nord14_gui,
		bg = colors.nord3_gui,
	},
}

-- LSP hints
components.active[2][6] = {
	provider = "diagnostic_hints",
	hl = {
		fg = colors.nord10_gui,
		bg = colors.nord3_gui,
	},
}

-- End of middle
components.active[2][7] = {
	provider = "",
	hl = {
		fg = colors.nord3_gui,
		bg = colors.nord0_gui,
	},
}

-- Right
-- Git branch
components.active[3][1] = {
	provider = "git_branch",
	enabled = require("feline.providers.git").git_info_exists,
	hl = {
		fg = colors.nord10_gui,
		bg = colors.nord0_gui,
	},
}

-- # added lines
components.active[3][2] = {
	provider = "git_diff_added",
	hl = {
		fg = colors.nord14_gui,
		bg = colors.nord0_gui,
	},
}

-- # changed lines
components.active[3][3] = {
	provider = "git_diff_changed",
	hl = {
		fg = colors.nord12_gui,
		bg = colors.nord0_gui,
	},
}

-- # removed linces
components.active[3][4] = {
	provider = "git_diff_removed",
	hl = {
		fg = colors.nord13_gui,
		bg = colors.nord0_gui,
	},
}

-- Extra space
components.active[3][5] = {
	provider = " ",
	hl = {
		fg = colors.nord0_gui,
		bg = colors.nord0_gui,
	},
}

-- VI mode name
components.active[3][6] = {
	provider = "vi_mode",
	icon = "",
	hl = {
		fg = colors.nord3_gui,
		bg = colors.nord8_gui,
	},
	left_sep = {
		str = "left_rounded",
		hl = {
			fg = colors.nord8_gui,
			bg = colors.nord0_gui,
		},
	},
	right_sep = {
		str = " ",
		hl = {
			fg = colors.nord8_gui,
			bg = colors.nord8_gui,
		},
	},
}

-- Line percent
components.active[3][7] = {
	provider = "line_percentage",
	hl = {
		fg = colors.nord3_gui,
		bg = colors.nord5_gui,
	},
	left_sep = {
		str = " ",
		hl = {
			fg = colors.nord5_gui,
			bg = colors.nord5_gui,
		},
	},
	right_sep = {
		str = "right_rounded",
		hl = {
			fg = colors.nord5_gui,
			bg = colors.nord0_gui,
		},
	},
}

-- Disable bar on inactive windows
components.inactive = components.active

require("feline").setup({
	components = components,
	disable = disable,
})
