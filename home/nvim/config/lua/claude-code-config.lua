require("claude-code").setup({
	keymaps = {
		toggle = {
			normal = "<leader>ac",
			terminal = "<leader>ac",
			variants = {
				continue = "<leader>aC",
				verbose = "<leader>aV",
			},
		},
	},
})

require("which-key").add({
	{ "<leader>a", group = "AI" },
})
