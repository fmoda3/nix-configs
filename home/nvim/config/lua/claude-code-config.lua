require("claude-code").setup({
	keymaps = {
		toggle = {
			normal = "<leader>cc",
			terminal = "<leader>cc",
			variants = {
				continue = "<leader>cC",
				verbose = "<leader>cV",
			},
		},
	},
})
