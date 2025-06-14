-- Telescope Settings
require("which-key").add({
	{ "<leader>f", group = "Find", icon = "󰍉" },
	{
		"<Leader>ff",
		require("telescope.builtin").find_files,
		desc = "Telescope: Find files",
		icon = "󰈞",
		noremap = true,
	},
	{
		"<Leader>fg",
		require("telescope.builtin").live_grep,
		desc = "Telescope: Live grep",
		icon = "󰊄",
		noremap = true,
	},
	{ "<Leader>fb", require("telescope.builtin").buffers, desc = "Telescope: Buffers", icon = "󰕘", noremap = true },
	{
		"<Leader>fh",
		require("telescope.builtin").help_tags,
		desc = "Telescope: Help tags",
		icon = "󰋖",
		noremap = true,
	},
})
