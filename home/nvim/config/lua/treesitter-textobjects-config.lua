require("nvim-treesitter-textobjects").setup({
	select = {
		lookahead = true,
	},
	move = {
		set_jumps = true,
	},
})

require("which-key").add({
	-- Select
	{
		"af",
		function()
			require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
		end,
		mode = { "x", "o" },
		desc = "Select outer function",
		silent = true,
	},
	{
		"if",
		function()
			require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects")
		end,
		mode = { "x", "o" },
		desc = "Select inner function",
		silent = true,
	},
	{
		"ac",
		function()
			require("nvim-treesitter-textobjects.select").select_textobject("@class.outer", "textobjects")
		end,
		mode = { "x", "o" },
		desc = "Select outer class",
		silent = true,
	},
	{
		"ic",
		function()
			require("nvim-treesitter-textobjects.select").select_textobject("@class.inner", "textobjects")
		end,
		mode = { "x", "o" },
		desc = "Select inner class",
		silent = true,
	},
	{
		"aa",
		function()
			require("nvim-treesitter-textobjects.select").select_textobject("@parameter.outer", "textobjects")
		end,
		mode = { "x", "o" },
		desc = "Select outer parameter",
		silent = true,
	},
	{
		"ia",
		function()
			require("nvim-treesitter-textobjects.select").select_textobject("@parameter.inner", "textobjects")
		end,
		mode = { "x", "o" },
		desc = "Select inner parameter",
		silent = true,
	},
	{
		"ab",
		function()
			require("nvim-treesitter-textobjects.select").select_textobject("@block.outer", "textobjects")
		end,
		mode = { "x", "o" },
		desc = "Select outer block",
		silent = true,
	},
	{
		"ib",
		function()
			require("nvim-treesitter-textobjects.select").select_textobject("@block.inner", "textobjects")
		end,
		mode = { "x", "o" },
		desc = "Select inner block",
		silent = true,
	},
	{
		"al",
		function()
			require("nvim-treesitter-textobjects.select").select_textobject("@loop.outer", "textobjects")
		end,
		mode = { "x", "o" },
		desc = "Select outer loop",
		silent = true,
	},
	{
		"il",
		function()
			require("nvim-treesitter-textobjects.select").select_textobject("@loop.inner", "textobjects")
		end,
		mode = { "x", "o" },
		desc = "Select inner loop",
		silent = true,
	},
	{
		"ai",
		function()
			require("nvim-treesitter-textobjects.select").select_textobject("@conditional.outer", "textobjects")
		end,
		mode = { "x", "o" },
		desc = "Select outer conditional",
		silent = true,
	},
	{
		"ii",
		function()
			require("nvim-treesitter-textobjects.select").select_textobject("@conditional.inner", "textobjects")
		end,
		mode = { "x", "o" },
		desc = "Select inner conditional",
		silent = true,
	},
	-- move
	{
		"]f",
		function()
			require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects")
		end,
		mode = { "n", "x", "o" },
		desc = "Go to next start function",
		silent = true,
	},
	{
		"]c",
		function()
			require("nvim-treesitter-textobjects.move").goto_next_start("@class.outer", "textobjects")
		end,
		mode = { "n", "x", "o" },
		desc = "Go to next start class",
		silent = true,
	},
	{
		"]a",
		function()
			require("nvim-treesitter-textobjects.move").goto_next_start("@parameter.inner", "textobjects")
		end,
		mode = { "n", "x", "o" },
		desc = "Go to next start parameter",
		silent = true,
	},
	{
		"]F",
		function()
			require("nvim-treesitter-textobjects.move").goto_next_end("@function.outer", "textobjects")
		end,
		mode = { "n", "x", "o" },
		desc = "Go to next end function",
		silent = true,
	},
	{
		"]C",
		function()
			require("nvim-treesitter-textobjects.move").goto_next_end("@class.outer", "textobjects")
		end,
		mode = { "n", "x", "o" },
		desc = "Go to next end class",
		silent = true,
	},
	{
		"]A",
		function()
			require("nvim-treesitter-textobjects.move").goto_next_end("@parameter.inner", "textobjects")
		end,
		mode = { "n", "x", "o" },
		desc = "Go to next end parameter",
		silent = true,
	},
	{
		"[f",
		function()
			require("nvim-treesitter-textobjects.move").goto_previous_start("@function.outer", "textobjects")
		end,
		mode = { "n", "x", "o" },
		desc = "Go to previous start function",
		silent = true,
	},
	{
		"[c",
		function()
			require("nvim-treesitter-textobjects.move").goto_previous_start("@class.outer", "textobjects")
		end,
		mode = { "n", "x", "o" },
		desc = "Go to previous start class",
		silent = true,
	},
	{
		"[a",
		function()
			require("nvim-treesitter-textobjects.move").goto_previous_start("@parameter.inner", "textobjects")
		end,
		mode = { "n", "x", "o" },
		desc = "Go to previous start parameter",
		silent = true,
	},
	{
		"[F",
		function()
			require("nvim-treesitter-textobjects.move").goto_previous_end("@function.outer", "textobjects")
		end,
		mode = { "n", "x", "o" },
		desc = "Go to previous end function",
		silent = true,
	},
	{
		"[C",
		function()
			require("nvim-treesitter-textobjects.move").goto_previous_end("@class.outer", "textobjects")
		end,
		mode = { "n", "x", "o" },
		desc = "Go to previous end class",
		silent = true,
	},
	{
		"[A",
		function()
			require("nvim-treesitter-textobjects.move").goto_previous_end("@parameter.inner", "textobjects")
		end,
		mode = { "n", "x", "o" },
		desc = "Go to previous end parameter",
		silent = true,
	},
	-- Swap
	{
		"<leader>sn",
		function()
			require("nvim-treesitter-textobjects.swap").swap_next("@parameter.inner")
		end,
		mode = { "n" },
		desc = "Swap next parameter",
		silent = true,
	},
	{
		"<leader>sp",
		function()
			require("nvim-treesitter-textobjects.swap").swap_previous("@parameter.inner")
		end,
		mode = { "n" },
		desc = "Swap previous parameter",
		silent = true,
	},
})
