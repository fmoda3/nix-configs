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
	{
		"]b",
		"<cmd>BufferLineCycleNext<cr>",
		desc = "BufferLine: Next buffer",
		icon = "󰒭",
		silent = true,
		noremap = true,
	},
	{
		"[b",
		"<cmd>BufferLineCyclePrev<cr>",
		desc = "BufferLine: Previous buffer",
		icon = "󰒮",
		silent = true,
		noremap = true,
	},
	{ "<leader>bl", group = "BufferLine", icon = "󰕘" },
	{
		"<Leader>ble",
		"<cmd>BufferLineSortByExtension<cr>",
		desc = "BufferLine: Organize by extension",
		icon = "󰒺",
		silent = true,
		noremap = true,
	},
	{
		"<Leader>bld",
		"<cmd>BufferLineSortByDirectory<cr>",
		desc = "BufferLine: Organize by directory",
		icon = "󰝰",
		silent = true,
		noremap = true,
	},
})
