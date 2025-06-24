require("claudecode").setup({})

require("which-key").add({
	{ "<leader>a", group = "AI", icon = "󱜙" },
	{ "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude", icon = "󱜙" },
	{ "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude", icon = "󱜙" },
	{ "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude", icon = "󱜙" },
	{ "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude", icon = "󱜙" },
	{ "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer", icon = "󱜙" },
	{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude", icon = "󱜙" },
	-- Diff management
	{ "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff", icon = "󱜙" },
	{ "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff", icon = "󱜙" },
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "NvimTree", "neo-tree", "oil" },
	callback = function()
		require("which-key").register({
			{
				"<leader>as",
				"<cmd>ClaudeCodeTreeAdd<cr>",
				desc = "Add file",
				ft = { "NvimTree", "neo-tree", "oil" },
				icon = "󱜙",
			},
		}, { buffer = 0 })
	end,
})
