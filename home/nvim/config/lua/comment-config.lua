require("Comment").setup({
	---LHS of toggle mappings in NORMAL mode
	toggler = {
		---Line-comment toggle keymap
		line = "<leader>ctb",
		---Block-comment toggle keymap
		block = "<leader>ctb",
	},
	---LHS of operator-pending mappings in NORMAL and VISUAL mode
	opleader = {
		---Line-comment keymap
		line = "<leader>cc",
		---Block-comment keymap
		block = "<leader>cb",
	},
	---LHS of extra mappings
	extra = {
		---Add comment on the line above
		above = "<leader>cO",
		---Add comment on the line below
		below = "<leader>co",
		---Add comment at the end of line
		eol = "<leader>cA",
	},
})

require("which-key").add({
	{ "<leader>c", group = "Comment", icon = "󰅺" },
	{ "<leader>ct", group = "Toggle", icon = "󰔡" },
})
