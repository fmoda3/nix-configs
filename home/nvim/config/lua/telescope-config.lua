-- Telescope Settings
require("which-key").add({
	{ "<leader>f", group = "Find" },
	{ "<Leader>ff", require("telescope.builtin").find_files, desc = "Telescope: Find files", noremap = true },
	{ "<Leader>fg", require("telescope.builtin").live_grep, desc = "Telescope: Live grep", noremap = true },
	{ "<Leader>fb", require("telescope.builtin").buffers, desc = "Telescope: Buffers", noremap = true },
	{ "<Leader>fh", require("telescope.builtin").help_tags, desc = "Telescope: Help tags", noremap = true },
})
