require("treesitter-context").setup({})

require("legendary").keymaps({
	{
		"[c",
		function()
			require("treesitter-context").go_to_context(vim.v.count1)
		end,
		mode = { "n" },
		description = "Jump to Context",
		opts = { silent = true },
	},
})
