require("trouble").setup({})

local opts = { silent = true, noremap = true }
require("legendary").keymaps({
	{ "<Leader>xx", "<cmd>TroubleToggle<cr>", description = "Trouble: Toggle", opts = opts },
	{ "<Leader>xs", "<cmd>Trouble<cr>", description = "Trouble: Open", opts = opts },
	{ "<Leader>xc", "<cmd>TroubleClose<cr>", description = "Trouble: Close", opts = opts },
	{ "<Leader>xr", "<cmd>TroubleRefresh<cr>", description = "Trouble: Refresh", opts = opts },
	{
		"<Leader>xw",
		"<cmd>Trouble workspace_diagnostics<cr>",
		description = "Trouble: Workspace diagnostics",
		opts = opts,
	},
	{
		"<Leader>xd",
		"<cmd>Trouble document_diagnostics<cr>",
		description = "Trouble: Document diagnostics",
		opts = opts,
	},
	{ "<Leader>xl", "<cmd>Trouble loclist<cr>", description = "Trouble: Loclist diagnostics", opts = opts },
	{ "<Leader>xq", "<cmd>Trouble quickfix<cr>", description = "Trouble: Quickfix", opts = opts },
	{ "gR", "<cmd>Trouble lsp_references<cr>", description = "Trouble: LSP references", opts = opts },
})
