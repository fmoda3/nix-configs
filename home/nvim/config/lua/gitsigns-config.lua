require("gitsigns").setup({
	on_attach = function(bufnr)
		local gitsigns = require("gitsigns")

		-- Navigation
		require("legendary").keymaps({
			{
				"]c",
				function()
					if vim.wo.diff then
						vim.cmd.normal({ "]c", bang = true })
					else
						gitsigns.nav_hunk("next")
					end
				end,
				description = "Gitsigns: Next hunk",
			},
			{
				"[c",
				function()
					if vim.wo.diff then
						vim.cmd.normal({ "[c", bang = true })
					else
						gitsigns.nav_hunk("prev")
					end
				end,
				description = "Gitsigns: Previous hunk",
			},
		})

		-- Actions
		require("legendary").keymaps({
			{ "<leader>hs", gitsigns.stage_hunk, description = "Gitsigns: Stage hunk" },
			{ "<leader>hr", gitsigns.reset_hunk, description = "Gitsigns: Reset hunk" },
			{
				"<leader>hs",
				function()
					gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end,
				mode = { "v" },
				description = "Gitsigns: Stage hunk (visual)",
			},
			{
				"<leader>hr",
				function()
					gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end,
				mode = { "v" },
				description = "Gitsigns: Reset hunk (visual)",
			},
			{ "<leader>hS", gitsigns.stage_buffer, description = "Gitsigns: Stage buffer" },
			{ "<leader>hR", gitsigns.reset_buffer, description = "Gitsigns: Reset buffer" },
			{ "<leader>hp", gitsigns.preview_hunk, description = "Gitsigns: Preview hunk" },
			{ "<leader>hi", gitsigns.preview_hunk_inline, description = "Gitsigns: Preview hunk inline" },
			{
				"<leader>hb",
				function()
					gitsigns.blame_line({ full = true })
				end,
				description = "Gitsigns: Blame line",
			},
			{ "<leader>hd", gitsigns.diffthis, description = "Gitsigns: Diff this" },
			{
				"<leader>hD",
				function()
					gitsigns.diffthis("~")
				end,
				description = "Gitsigns: Diff this (cached)",
			},
			{
				"<leader>hQ",
				function()
					gitsigns.setqflist("all")
				end,
				description = "Gitsigns: Set qflist",
			},
		})

		-- Toggles
		require("legendary").keymaps({
			{ "<leader>tb", gitsigns.toggle_current_line_blame, description = "Gitsigns: Toggle current line blame" },
			{ "<leader>td", gitsigns.toggle_deleted, description = "Gitsigns: Toggle deleted" },
			{ "<leader>tw", gitsigns.toggle_word_diff, description = "Gitsigns: Toggle word diff" },
		})

		-- Text object
		require("legendary").keymaps({
			{ "ih", gitsigns.select_hunk, description = "Gitsigns: Select hunk", mode = { "o", "x" } },
		})
	end,
})
