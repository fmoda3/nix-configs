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
				icon = "󰒭",
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
				icon = "󰒮",
			},
		})

		-- Actions
		require("which-key").add({
			{ "<leader>g", group = "Git", icon = "" },
			{ "<leader>gs", gitsigns.stage_hunk, desc = "Gitsigns: Stage hunk", icon = "" },
			{ "<leader>gr", gitsigns.reset_hunk, desc = "Gitsigns: Reset hunk", icon = "" },
			{
				"<leader>gs",
				function()
					gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end,
				mode = { "v" },
				desc = "Gitsigns: Stage hunk (visual)",
				icon = "",
			},
			{
				"<leader>gr",
				function()
					gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end,
				mode = { "v" },
				desc = "Gitsigns: Reset hunk (visual)",
				icon = "",
			},
			{ "<leader>gS", gitsigns.stage_buffer, desc = "Gitsigns: Stage buffer", icon = "" },
			{ "<leader>gR", gitsigns.reset_buffer, desc = "Gitsigns: Reset buffer", icon = "" },
			{ "<leader>gp", gitsigns.preview_hunk, desc = "Gitsigns: Preview hunk", icon = "" },
			{ "<leader>gi", gitsigns.preview_hunk_inline, desc = "Gitsigns: Preview hunk inline", icon = "" },
			{
				"<leader>gb",
				function()
					gitsigns.blame_line({ full = true })
				end,
				desc = "Gitsigns: Blame line",
				icon = "",
			},
			{ "<leader>gd", gitsigns.diffthis, desc = "Gitsigns: Diff this", icon = "" },
			{
				"<leader>gD",
				function()
					gitsigns.diffthis("~")
				end,
				desc = "Gitsigns: Diff this (cached)",
				icon = "",
			},
			{
				"<leader>gQ",
				function()
					gitsigns.setqflist("all")
				end,
				desc = "Gitsigns: Set qflist",
				icon = "󱖫",
			},
		})

		-- Toggles
		require("which-key").add({
			{ "<leader>gt", group = "Toggle", icon = "󰔡" },
			{
				"<leader>gtb",
				gitsigns.toggle_current_line_blame,
				desc = "Gitsigns: Toggle current line blame",
				icon = "",
			},
			{ "<leader>gtd", gitsigns.toggle_deleted, desc = "Gitsigns: Toggle deleted", icon = "" },
			{ "<leader>gtw", gitsigns.toggle_word_diff, desc = "Gitsigns: Toggle word diff", icon = "" },
		})

		-- Text object
		require("which-key").add({
			{ "<leader>gi", gitsigns.select_hunk, desc = "Gitsigns: Select hunk", icon = "󰒅", mode = { "o", "x" } },
		})
	end,
})
