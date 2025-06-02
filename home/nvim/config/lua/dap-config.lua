require("telescope").load_extension("dap")

require("which-key").add({
	{ "<Leader>dct", require("dap").continue, desc = "DAP: Continue", noremap = true },
	{ "<Leader>dsv", require("dap").step_over, desc = "DAP: Step over", noremap = true },
	{ "<Leader>dsi", require("dap").step_into, desc = "DAP: Step into", noremap = true },
	{ "<Leader>dso", require("dap").step_out, desc = "DAP: Step out", noremap = true },
	{ "<Leader>dtb", require("dap").toggle_breakpoint, desc = "DAP: Toggle breakpoint", noremap = true },
	{ "<Leader>duh", require("dap.ui.widgets").hover, desc = "DAP: Widgets Hover", noremap = true },
	{
		"<Leader>duf",
		function()
			require("dap.ui.widgets").centered_float(require("dap.ui.widgets").scopes)
		end,
		desc = "DAP: Widgets scopes",
		noremap = true,
	},
	{
		"<Leader>dsbr",
		function()
			vim.ui.input({ prompt = "Breakpoint condition", default = "" }, function(input)
				require("dap").set_breakpoint(input)
			end)
		end,
		desc = "DAP: Set breakpoint condition",
		noremap = true,
	},
	{
		"<Leader>dsbm",
		function()
			vim.ui.input({ prompt = "Log point message", default = "" }, function(input)
				require("dap").set_breakpoint(nil, nil, input)
			end)
		end,
		desc = "DAP: Log message",
		noremap = true,
	},
	{ "<Leader>dro", require("dap").repl.open, desc = "DAP: Open repl", noremap = true },
	{ "<Leader>drl", require("dap").repl.run_last, desc = "DAP: Run last", noremap = true },
	-- Telescope extension
	{ "<Leader>dcc", require("telescope").extensions.dap.commands, desc = "DAP: Show commands", noremap = true },
	{
		"<Leader>dco",
		require("telescope").extensions.dap.configurations,
		desc = "DAP: Show configurations",
		noremap = true,
	},
	{
		"<Leader>dlb",
		require("telescope").extensions.dap.list_breakpoints,
		desc = "DAP: Show breakpoints",
		noremap = true,
	},
	{ "<Leader>dv", require("telescope").extensions.dap.variables, desc = "DAP: Show variables", noremap = true },
	{ "<Leader>df", require("telescope").extensions.dap.frames, desc = "DAP: Show frames", noremap = true },
	-- DAP UI
	{ "<Leader>dui", require("dapui").toggle, desc = "DAP: Toggle UI", noremap = true },
	{
		"<Leader>dev",
		function()
			vim.ui.input({ prompt = "Eval", default = "" }, function(input)
				require("dapui").eval(input, { enter = true })
			end)
		end,
		desc = "DAP: Evaluate expression",
		noremap = true,
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
dap.adapters.mix_task = {
	type = "executable",
	command = "@elixir_ls_home@" .. "/lib/debugger.sh",
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
dap.adapters.python = {
	type = "executable",
	command = "@python_debug_home@" .. "/bin/python",
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
