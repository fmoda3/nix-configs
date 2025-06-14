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
		-- Buffers
		{ "<leader>b", group = "Buffers" },
		{ "<leader>bd", ":bdelete<cr>", desc = "Delete buffer" },
		{ "<leader>bn", ":bnext<cr>", desc = "Next buffer" },
		{ "<leader>bp", ":bprev<cr>", desc = "Previous buffer" },
		-- Window management
		{ "<leader>w", group = "Windows" },
		{ "<leader>wv", "<C-w>v", desc = "Split vertical" },
		{ "<leader>wh", "<C-w>s", desc = "Split horizontal" },
		{ "<leader>wc", "<C-w>c", desc = "Close window" },
		{ "<leader>wo", "<C-w>o", desc = "Close other windows" },
		-- Quit
		{ "<leader>q", group = "Quit" },
		{ "<leader>qq", ":q<cr>", desc = "Quit" },
		{ "<leader>qQ", ":q!<cr>", desc = "Force quit" },
		{ "<leader>qs", ":wq<cr>", desc = "Save and Quit" },
	},
})
