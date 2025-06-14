require("nvim-surround").setup({
	highlight = {
		duration = 200,
	},
})

-- Register surround help with which-key
require("which-key").add({
	{ "ys", group = "Surround (add)", icon = "󰅪" },
	{ "cs", group = "Surround (change)", icon = "󰛔" },
	{ "ds", group = "Surround (delete)", icon = "󱟁" },
	{ "S", group = "Surround (visual)", icon = "󰒉", mode = "v" },
})
