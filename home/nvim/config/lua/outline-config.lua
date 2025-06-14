require("outline").setup({
	outline_window = {
		auto_jump = true,
		focus_on_open = false,
	},
})

-- Register outline keybindings with which-key
require("which-key").add({
	{ "<leader>o", group = "Outline", icon = "󰙅" },
	{ "<leader>oo", "<cmd>Outline<cr>", desc = "Toggle outline", icon = "󰔡" },
	{ "<leader>oO", "<cmd>OutlineOpen<cr>", desc = "Open outline", icon = "󰏋" },
})
