require("trouble").setup({})

require("which-key").add({
	{ "<leader>x", group = "Trouble/Diagnostics", icon = "󱖫" },
	{
		"<Leader>xx",
		"<cmd>Trouble diagnostics toggle<cr>",
		desc = "Trouble: Diagnostics",
		icon = "󱖫",
		silent = true,
		noremap = true,
	},
	{
		"<Leader>xX",
		"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
		desc = "Trouble: Buffer Diagnostics",
		icon = "󱖫",
		silent = true,
		noremap = true,
	},
	{
		"<Leader>xs",
		"<cmd>Trouble symbols toggle focus=false<cr>",
		desc = "Trouble: Symbols",
		icon = "󱖫",
		silent = true,
		noremap = true,
	},
	{
		"<Leader>xl",
		"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
		desc = "Trouble: LSP Definitions / references / ...",
		icon = "󱖫",
		silent = true,
		noremap = true,
	},
	{
		"<Leader>xL",
		"<cmd>Trouble loclist toggle<cr>",
		desc = "Trouble: Location List",
		icon = "󱖫",
		silent = true,
		noremap = true,
	},
	{
		"<Leader>xQ",
		"<cmd>Trouble qflist toggle<cr>",
		desc = "Trouble: Quickfix List",
		icon = "󱖫",
		silent = true,
		noremap = true,
	},
})
