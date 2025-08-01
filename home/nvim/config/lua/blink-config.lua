require("blink.cmp").setup({
	fuzzy = {
		implementation = "lua",
		prebuilt_binaries = {
			download = false,
		},
	},
	keymap = {
		preset = "super-tab",
	},
	completion = {
		list = {
			selection = {
				preselect = function(ctx)
					return not require("blink.cmp").snippet_active({ direction = 1 })
				end,
			},
		},
	},
	signature = {
		enabled = true,
		window = {
			show_documentation = true,
		},
	},
})
require("blink.cmp.fuzzy").set_implementation("rust")
