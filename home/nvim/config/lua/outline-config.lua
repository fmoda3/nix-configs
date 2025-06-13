require("outline").setup({
	outline_window = {
		auto_jump = true,
		focus_on_open = false,
	},
})

-- Register outline keybindings with which-key
require("which-key").add({
	{ "<leader>o", "<cmd>Outline<cr>", desc = "Toggle outline" },
	{ "<leader>O", "<cmd>OutlineOpen<cr>", desc = "Open outline" },
})
