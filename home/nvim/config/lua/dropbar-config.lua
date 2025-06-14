local dropbar_api = require("dropbar.api")
require("which-key").add({
	{ "<Leader>;", dropbar_api.pick, desc = "Pick symbols in winbar", icon = "" },
	{ "[;", dropbar_api.goto_context_start, desc = "Go to start of current context", icon = "󰆸" },
	{ "];", dropbar_api.select_next_context, desc = "Select next context", icon = "󰆹" },
})
