require("gitsigns").setup({
	on_attach = function(bufnr)
		local gitsigns = require("gitsigns")

		-- Navigation
		require("which-key").add({
			{
				"]g",
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
				"[g",
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
			{ "<leader>g", group = "Git" },
			{ "<leader>gs", gitsigns.stage_hunk, desc = "Gitsigns: Stage hunk" },
			{ "<leader>gr", gitsigns.reset_hunk, desc = "Gitsigns: Reset hunk" },
			{
				"<leader>gs",
				function()
					gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end,
				mode = { "v" },
				desc = "Gitsigns: Stage hunk (visual)",
			},
			{
				"<leader>gr",
				function()
					gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end,
				mode = { "v" },
				desc = "Gitsigns: Reset hunk (visual)",
			},
			{ "<leader>gS", gitsigns.stage_buffer, desc = "Gitsigns: Stage buffer" },
			{ "<leader>gR", gitsigns.reset_buffer, desc = "Gitsigns: Reset buffer" },
			{ "<leader>gp", gitsigns.preview_hunk, desc = "Gitsigns: Preview hunk" },
			{ "<leader>gi", gitsigns.preview_hunk_inline, desc = "Gitsigns: Preview hunk inline" },
			{
				"<leader>gb",
				function()
					gitsigns.blame_line({ full = true })
				end,
				desc = "Gitsigns: Blame line",
			},
			{ "<leader>gd", gitsigns.diffthis, desc = "Gitsigns: Diff this" },
			{
				"<leader>gD",
				function()
					gitsigns.diffthis("~")
				end,
				desc = "Gitsigns: Diff this (cached)",
			},
			{
				"<leader>gQ",
				function()
					gitsigns.setqflist("all")
				end,
				desc = "Gitsigns: Set qflist",
			},
		})

		-- Toggles
		require("which-key").add({
			{ "<leader>gt", group = "Toggle" },
			{ "<leader>gtb", gitsigns.toggle_current_line_blame, desc = "Gitsigns: Toggle current line blame" },
			{ "<leader>gtd", gitsigns.toggle_deleted, desc = "Gitsigns: Toggle deleted" },
			{ "<leader>gtw", gitsigns.toggle_word_diff, desc = "Gitsigns: Toggle word diff" },
		})

		-- Text object
		require("which-key").add({
			{ "<leader>gi", gitsigns.select_hunk, desc = "Gitsigns: Select hunk", mode = { "o", "x" } },
		})
	end,
})
