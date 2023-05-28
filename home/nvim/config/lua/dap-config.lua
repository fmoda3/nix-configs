require("telescope").load_extension("dap")

local opts = { noremap = true }
require("legendary").keymaps({
	{ "<Leader>dct", require("dap").continue, description = "DAP: Continue", opts = opts },
	{ "<Leader>dsv", require("dap").step_over, description = "DAP: Step over", opts = opts },
	{ "<Leader>dsi", require("dap").step_into, description = "DAP: Step into", opts = opts },
	{ "<Leader>dso", require("dap").step_out, description = "DAP: Step out", opts = opts },
	{ "<Leader>dtb", require("dap").toggle_breakpoint, description = "DAP: Toggle breakpoint", opts = opts },
	{ "<Leader>duh", require("dap.ui.widgets").hover, description = "DAP: Widgets Hover", opts = opts },
	{
		"<Leader>duf",
		function()
			require("dap.ui.widgets").centered_float(require("dap.ui.widgets").scopes)
		end,
		description = "DAP: Widgets scopes",
		opts = opts,
	},
	{
		"<Leader>dsbr",
		function()
			vim.ui.input({ prompt = "Breakpoint condition", default = "" }, function(input)
				require("dap").set_breakpoint(input)
			end)
		end,
		description = "DAP: Set breakpoint condition",
		opts = opts,
	},
	{
		"<Leader>dsbm",
		function()
			vim.ui.input({ prompt = "Log point message", default = "" }, function(input)
				require("dap").set_breakpoint(nil, nil, input)
			end)
		end,
		description = "DAP: Log message",
		opts = opts,
	},
	{ "<Leader>dro", require("dap").repl.open, description = "DAP: Open repl", opts = opts },
	{ "<Leader>drl", require("dap").repl.run_last, description = "DAP: Run last", opts = opts },
	-- Telescope extension
	{ "<Leader>dcc", require("telescope").extensions.dap.commands, description = "DAP: Show commands", opts = opts },
	{
		"<Leader>dco",
		require("telescope").extensions.dap.configurations,
		description = "DAP: Show configurations",
		opts = opts,
	},
	{
		"<Leader>dlb",
		require("telescope").extensions.dap.list_breakpoints,
		description = "DAP: Show breakpoints",
		opts = opts,
	},
	{ "<Leader>dv", require("telescope").extensions.dap.variables, description = "DAP: Show variables", opts = opts },
	{ "<Leader>df", require("telescope").extensions.dap.frames, description = "DAP: Show frames", opts = opts },
	-- DAP UI
	{ "<Leader>dui", require("dapui").toggle, description = "DAP: Toggle UI", opts = opts },
	{
		"<Leader>dev",
		function()
			vim.ui.input({ prompt = "Eval", default = "" }, function(input)
				require("dapui").eval(input, { enter = true })
			end)
		end,
		description = "DAP: Evaluate expression",
		opts = opts,
	},
})

require("dapui").setup({
	layouts = {
		{
			elements = {
				"watches",
				"stacks",
				"breakpoints",
				"scopes",
			},
			size = 60,
			position = "left",
		},
		{
			elements = {
				"repl",
				"console",
			},
			size = 15,
			position = "bottom",
		},
	},
})
require("nvim-dap-virtual-text").setup({})

local colors = require("nord-colors")
local util = require("util")
util.colorize({
	DapBreakpointColor = { fg = colors.nord11_gui },
	DapBreakpointConditionColor = { fg = colors.nord11_gui },
	DapLogPointColor = { fg = colors.nord13_gui },
	DapStoppedColor = { fg = colors.nord14_gui },
	DapBreakpointRejectedColor = { fg = colors.nord11_gui },
})
vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DapBreakpointColor", linehl = "", numhl = "" })
vim.fn.sign_define(
	"DapBreakpointCondition",
	{ text = "", texthl = "DapBreakpointConditionColor", linehl = "", numhl = "" }
)
vim.fn.sign_define("DapLogPoint", { text = "ﯽ", texthl = "DapLogPointColor", linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped", { text = "", texthl = "DapStoppedColor", linehl = "", numhl = "" })
vim.fn.sign_define(
	"DapBreakpointRejected",
	{ text = "", texthl = "DapBreakpointRejectedColor", linehl = "", numhl = "" }
)

local dap = require("dap")
-- Elixir
local elixir_ls_home = vim.api.nvim_get_var("elixir_ls_home")
dap.adapters.mix_task = {
	type = "executable",
	command = elixir_ls_home .. "/lib/debugger.sh",
	args = {},
}

dap.configurations.elixir = {
	{
		type = "mix_task",
		name = "mix test",
		task = "test",
		taskArgs = { "--trace" },
		request = "launch",
		startApps = true,
		projectDir = "${workspaceFolder}",
		requireFiles = {
			"test/**/test_helper.exs",
			"test/**/*_test.exs",
		},
	},
}

-- Python
local python_debug_home = vim.api.nvim_get_var("python_debug_home")
dap.adapters.python = {
	type = "executable",
	command = python_debug_home .. "/bin/python",
	args = { "-m", "debugpy.adapter" },
}

dap.configurations.python = {
	{
		type = "python",
		request = "launch",
		name = "Launch file",

		-- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options
		program = "${file}", -- This configuration will launch the current file if used.
		python = { "python" },
	},
	{
		type = "python",
		request = "launch",
		name = "Django",

		program = "${workspaceFolder}/manage.py",
		args = { "runserver", "--noreload" },
		python = { "python" },
	},
	{
		type = "python",
		request = "attach",
		name = "Attach remote",

		host = "127.0.0.1",
		port = 5678,
	},
}
