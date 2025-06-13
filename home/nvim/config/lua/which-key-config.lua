require("which-key").setup({
	preset = "modern",
	spec = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer Local Keymaps (which-key)",
		},
		{ "<leader><leader>", ":Telescope keymaps<cr>", desc = "Open keymaps", noremap = true },
		-- Movement keybinds
		{ "<C-h>", "<C-w>h", desc = "Panes: Move left", noremap = true },
		{ "<C-j>", "<C-w>j", desc = "Panes: Move down", noremap = true },
		{ "<C-k>", "<C-w>k", desc = "Panes: Move up", noremap = true },
		{ "<C-l>", "<C-w>l", desc = "Panes: Move right", noremap = true },
		-- High level groups
		{ "]", group = "Next" },
		{ "[", group = "Previous" },
		{ "<leader>j", group = "Jump" },
		{ "<leader>s", group = "Swap" },
	},
})
