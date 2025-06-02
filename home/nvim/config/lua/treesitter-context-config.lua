require("treesitter-context").setup({})

require("which-key").add({
	{
		"<leader>jc",
		function()
			require("treesitter-context").go_to_context(vim.v.count1)
		end,
		mode = { "n" },
		desc = "Jump to Context",
		silent = true,
	},
})
