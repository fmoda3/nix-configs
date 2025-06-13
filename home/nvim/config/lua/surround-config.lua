require("nvim-surround").setup({
	highlight = {
		duration = 200,
	},
})

-- Register surround help with which-key
require("which-key").add({
	{ "ys", group = "Surround (add)" },
	{ "cs", group = "Surround (change)" },
	{ "ds", group = "Surround (delete)" },
	{ "S", group = "Surround (visual)", mode = "v" },
})
