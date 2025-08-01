require("nvim-tree").setup({
	disable_netrw = true,
	hijack_netrw = true,

	hijack_directories = {
		enable = true,
		auto_open = true,
	},

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
	{ "<leader>t", group = "Tree", icon = "󱏒" },
	{ "<leader>tt", ":NvimTreeToggle<cr>", desc = "Tree: Toggle", icon = "󰔡", silent = true },
	{ "<leader>tr", ":NvimTreeRefresh<cr>", desc = "Tree: Refresh", icon = "󰑐", silent = true },
	{ "<leader>tf", ":NvimTreeFindFile<cr>", desc = "Tree: Find file", icon = "󰍉", silent = true },
})
