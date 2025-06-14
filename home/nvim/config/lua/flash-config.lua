require("flash").setup({
	modes = {
		char = {
			enabled = true,
			jump_labels = true,
		},
	},
})

require("which-key").add({
	{
		"s",
		function()
			require("flash").jump()
		end,
		desc = "Flash: Jump",
		icon = "",
		mode = { "n", "x", "o" },
		noremap = true,
		silent = true,
	},
	{
		"S",
		function()
			require("flash").treesitter()
		end,
		desc = "Flash: Treesitter",
		icon = "",
		mode = { "n", "x", "o" },
		noremap = true,
		silent = true,
	},
	{
		"r",
		function()
			require("flash").remote()
		end,
		desc = "Flash: Remote",
		icon = "",
		mode = "o",
		noremap = true,
		silent = true,
	},
	{
		"R",
		function()
			require("flash").treesitter_search()
		end,
		desc = "Flash: Treesitter Search",
		icon = "",
		mode = { "o", "x" },
		noremap = true,
		silent = true,
	},
	{
		"<c-s>",
		function()
			require("flash").toggle()
		end,
		desc = "Toggle Flash Search",
		icon = "",
		mode = { "c" },
		noremap = true,
		silent = true,
	},
})
