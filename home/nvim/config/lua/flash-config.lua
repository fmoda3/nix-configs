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
		mode = { "c" },
		noremap = true,
		silent = true,
	},
})
