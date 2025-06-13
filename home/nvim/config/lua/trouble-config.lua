require("trouble").setup({})

require("which-key").add({
	{ "<leader>x", group = "Trouble/Diagnostics" },
	{
		"<Leader>xx",
		"<cmd>Trouble diagnostics toggle<cr>",
		desc = "Trouble: Diagnostics",
		silent = true,
		noremap = true,
	},
	{
		"<Leader>xX",
		"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
		desc = "Trouble: Buffer Diagnostics",
		silent = true,
		noremap = true,
	},
	{
		"<Leader>xs",
		"<cmd>Trouble symbols toggle focus=false<cr>",
		desc = "Trouble: Symbols",
		silent = true,
		noremap = true,
	},
	{
		"<Leader>xl",
		"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
		desc = "Trouble: LSP Definitions / references / ...",
		silent = true,
		noremap = true,
	},
	{ "<Leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Trouble: Location List", silent = true, noremap = true },
	{ "<Leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Trouble: Quickfix List", silent = true, noremap = true },
})
