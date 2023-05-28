require("bufferline").setup({
	options = {
		always_show_bufferline = false,
		show_buffer_close_icons = false,
		show_close_icon = false,
		diagnostics = "nvim_lsp",
	},
})

local opts = { silent = true, noremap = true }
require("legendary").keymaps({
	{ "[b", "<cmd>BufferLineCycleNext<cr>", description = "BufferLine: Next buffer", opts = opts },
	{ "]b", "<cmd>BufferLineCyclePrev<cr>", description = "BufferLine: Previous buffer", opts = opts },
	{
		"<Leader>be",
		"<cmd>BufferLineSortByExtension<cr>",
		description = "BufferLine: Organize by extension",
		opts = opts,
	},
	{
		"<Leader>bd",
		"<cmd>BufferLineSortByDirectory<cr>",
		description = "BufferLine: Organize by directory",
		opts = opts,
	},
})
