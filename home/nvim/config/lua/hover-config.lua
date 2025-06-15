require("hover").setup({
	init = function()
		-- Require providers
		require("hover.providers.lsp")
		require("hover.providers.dap")
		require("hover.providers.fold_preview")
		require("hover.providers.diagnostic")
		require("hover.providers.man")
		require("hover.providers.dictionary")
	end,
	preview_opts = {
		border = "rounded",
	},
	-- Whether the contents of a currently open hover window should be moved
	-- to a :h preview-window when pressing the hover keymap.
	preview_window = false,
	title = true,
	mouse_providers = {
		"LSP",
	},
	mouse_delay = 1000,
})

-- Setup keymaps
require("which-key").add({
	{
		"K",
		require("hover").hover,
		desc = "Hover",
		noremap = true,
		silent = true,
	},
	{
		"gK",
		require("hover").hover_select,
		desc = "Hover select source",
		noremap = true,
		silent = true,
	},
	{
		"<C-p>",
		function()
			require("hover").hover_switch("previous")
		end,
		desc = "Hover previous source",
		noremap = true,
		silent = true,
	},
	{
		"<C-n>",
		function()
			require("hover").hover_switch("next")
		end,
		desc = "Hover next source",
		noremap = true,
		silent = true,
	},
})

-- Mouse support
vim.keymap.set("n", "<MouseMove>", require("hover").hover_mouse, { desc = "hover.nvim (mouse)" })
