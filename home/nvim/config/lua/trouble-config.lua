require("trouble").setup({})

local opts = { silent = true, noremap = true }
require("legendary").keymaps({
	{ "<Leader>xx", "<cmd>Trouble diagnostics toggle<cr>", description = "Trouble: Diagnostics", opts = opts },
	{
		"<Leader>xX",
		"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
		description = "Trouble: Buffer Diagnostics",
		opts = opts,
	},
	{ "<Leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>", description = "Trouble: Symbols", opts = opts },
	{
		"<Leader>xl",
		"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
		description = "Trouble: LSP Definitions / references / ...",
		opts = opts,
	},
	{ "<Leader>xL", "<cmd>Trouble loclist toggle<cr>", description = "Trouble: Location List", opts = opts },
	{ "<Leader>xQ", "<cmd>Trouble qflist toggle<cr>", description = "Trouble: Quickfix List", opts = opts },
})
