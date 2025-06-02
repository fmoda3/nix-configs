require("nvim-tree").setup({
	disable_netrw = true,
	hijack_netrw = true,

	hijack_directories = {
		enable = true,
		auto_open = true,
	},

	open_on_tab = false,
	hijack_cursor = false,
	update_cwd = false,
	diagnostics = {
		enable = true,
		icons = {
			hint = "",
			info = "",
			warning = "",
			error = "",
		},
	},
	update_focused_file = {
		enable = false,
		update_cwd = false,
		ignore_list = {},
	},
	system_open = {
		cmd = nil,
		args = {},
	},
	view = {
		width = 25,
		side = "left",
	},
	actions = {
		open_file = {
			resize_window = true,
		},
	},
})

require("which-key").add({
	{ "<leader>tt", ":NvimTreeToggle<cr>", desc = "Nvim Tree: Toggle", silent = true },
	{ "<leader>tr", ":NvimTreeRefresh<cr>", desc = "Nvim Tree: Refresh", silent = true },
	{ "<leader>tf", ":NvimTreeFindFile<cr>", desc = "Nvim Tree: Find file", silent = true },
})
