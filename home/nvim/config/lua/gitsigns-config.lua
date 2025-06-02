require("gitsigns").setup({
	on_attach = function(bufnr)
		local gitsigns = require("gitsigns")

		-- Navigation
		require("which-key").add({
			{
				"]c",
				function()
					if vim.wo.diff then
						vim.cmd.normal({ "]c", bang = true })
					else
						gitsigns.nav_hunk("next")
					end
				end,
				desc = "Gitsigns: Next hunk",
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
				desc = "Gitsigns: Previous hunk",
			},
		})

		-- Actions
		require("which-key").add({
			{ "<leader>hs", gitsigns.stage_hunk, desc = "Gitsigns: Stage hunk" },
			{ "<leader>hr", gitsigns.reset_hunk, desc = "Gitsigns: Reset hunk" },
			{
				"<leader>hs",
				function()
					gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end,
				mode = { "v" },
				desc = "Gitsigns: Stage hunk (visual)",
			},
			{
				"<leader>hr",
				function()
					gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end,
				mode = { "v" },
				desc = "Gitsigns: Reset hunk (visual)",
			},
			{ "<leader>hS", gitsigns.stage_buffer, desc = "Gitsigns: Stage buffer" },
			{ "<leader>hR", gitsigns.reset_buffer, desc = "Gitsigns: Reset buffer" },
			{ "<leader>hp", gitsigns.preview_hunk, desc = "Gitsigns: Preview hunk" },
			{ "<leader>hi", gitsigns.preview_hunk_inline, desc = "Gitsigns: Preview hunk inline" },
			{
				"<leader>hb",
				function()
					gitsigns.blame_line({ full = true })
				end,
				desc = "Gitsigns: Blame line",
			},
			{ "<leader>hd", gitsigns.diffthis, desc = "Gitsigns: Diff this" },
			{
				"<leader>hD",
				function()
					gitsigns.diffthis("~")
				end,
				desc = "Gitsigns: Diff this (cached)",
			},
			{
				"<leader>hQ",
				function()
					gitsigns.setqflist("all")
				end,
				desc = "Gitsigns: Set qflist",
			},
		})

		-- Toggles
		require("which-key").add({
			{ "<leader>tb", gitsigns.toggle_current_line_blame, desc = "Gitsigns: Toggle current line blame" },
			{ "<leader>td", gitsigns.toggle_deleted, desc = "Gitsigns: Toggle deleted" },
			{ "<leader>tw", gitsigns.toggle_word_diff, desc = "Gitsigns: Toggle word diff" },
		})

		-- Text object
		require("which-key").add({
			{ "ih", gitsigns.select_hunk, desc = "Gitsigns: Select hunk", mode = { "o", "x" } },
		})
	end,
})
