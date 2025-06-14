require("which-key").setup({
	preset = "modern",
	spec = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer Local Keymaps (which-key)",
			icon = "󰘳",
		},
		{ "<leader><leader>", ":Telescope keymaps<cr>", desc = "Open keymaps", icon = "󰌌", noremap = true },
		-- Movement keybinds
		{ "<C-h>", "<C-w>h", desc = "Panes: Move left", icon = "󰁍", noremap = true },
		{ "<C-j>", "<C-w>j", desc = "Panes: Move down", icon = "󰁅", noremap = true },
		{ "<C-k>", "<C-w>k", desc = "Panes: Move up", icon = "󰁝", noremap = true },
		{ "<C-l>", "<C-w>l", desc = "Panes: Move right", icon = "󰁔", noremap = true },
		-- High level groups
		{ "]", group = "Next", icon = "󰒭" },
		{ "[", group = "Previous", icon = "󰒮" },
		{ "<leader>j", group = "Jump", icon = "󰉁" },
		{ "<leader>s", group = "Swap", icon = "󰓡" },
		-- Buffers
		{ "<leader>b", group = "Buffers", icon = "󰓩" },
		{ "<leader>bd", ":bdelete<cr>", desc = "Delete buffer", icon = "󰆴" },
		{ "<leader>bn", ":bnext<cr>", desc = "Next buffer", icon = "󰒭" },
		{ "<leader>bp", ":bprev<cr>", desc = "Previous buffer", icon = "󰒮" },
		-- Window management
		{ "<leader>w", group = "Windows", icon = "󰖲" },
		{ "<leader>wv", "<C-w>v", desc = "Split vertical", icon = "󰤼" },
		{ "<leader>wh", "<C-w>s", desc = "Split horizontal", icon = "󰤻" },
		{ "<leader>wc", "<C-w>c", desc = "Close window", icon = "󰅖" },
		{ "<leader>wo", "<C-w>o", desc = "Close other windows", icon = "󰆴" },
		-- Quit
		{ "<leader>q", group = "Quit", icon = "󰿅" },
		{ "<leader>qq", ":q<cr>", desc = "Quit", icon = "󰿅" },
		{ "<leader>qQ", ":q!<cr>", desc = "Force quit", icon = "󰗼" },
		{ "<leader>qs", ":wq<cr>", desc = "Save and Quit", icon = "󰆓" },
	},
})
