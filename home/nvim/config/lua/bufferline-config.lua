require("bufferline").setup({
	options = {
		always_show_bufferline = false,
		show_buffer_close_icons = false,
		show_close_icon = false,
		diagnostics = "nvim_lsp",
	},
	highlights = require("catppuccin.groups.integrations.bufferline").get(),
})

require("which-key").add({
	{ "[b", "<cmd>BufferLineCycleNext<cr>", desc = "BufferLine: Next buffer", silent = true, noremap = true },
	{ "]b", "<cmd>BufferLineCyclePrev<cr>", desc = "BufferLine: Previous buffer", silent = true, noremap = true },
	{
		"<Leader>be",
		"<cmd>BufferLineSortByExtension<cr>",
		desc = "BufferLine: Organize by extension",
		silent = true,
		noremap = true,
	},
	{
		"<Leader>bd",
		"<cmd>BufferLineSortByDirectory<cr>",
		desc = "BufferLine: Organize by directory",
		silent = true,
		noremap = true,
	},
})
