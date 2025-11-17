require("telescope").load_extension("dap")

require("which-key").add({
	{ "<leader>d", group = "Debug", icon = "" },
	{ "<Leader>dc", require("dap").continue, desc = "DAP: Continue", icon = "", noremap = true },
	{ "<Leader>dn", require("dap").step_over, desc = "DAP: Step over", icon = "󰆷", noremap = true },
	{ "<Leader>di", require("dap").step_into, desc = "DAP: Step into", icon = "󰆹", noremap = true },
	{ "<Leader>do", require("dap").step_out, desc = "DAP: Step out", icon = "󰆸", noremap = true },
	{ "<Leader>db", require("dap").toggle_breakpoint, desc = "DAP: Toggle breakpoint", icon = "", noremap = true },
	{ "<Leader>dwh", require("dap.ui.widgets").hover, desc = "DAP: Widgets Hover", icon = "󰋖", noremap = true },
	{
		"<Leader>dws",
		function()
			require("dap.ui.widgets").centered_float(require("dap.ui.widgets").scopes)
		end,
		desc = "DAP: Widgets scopes",
		icon = "󰋖",
		noremap = true,
	},
	{
		"<Leader>dB",
		function()
			vim.ui.input({ prompt = "Breakpoint condition", default = "" }, function(input)
				require("dap").set_breakpoint(input)
			end)
		end,
		desc = "DAP: Set breakpoint condition",
		icon = "",
		noremap = true,
	},
	{
		"<Leader>dm",
		function()
			vim.ui.input({ prompt = "Log point message", default = "" }, function(input)
				require("dap").set_breakpoint(nil, nil, input)
			end)
		end,
		desc = "DAP: Log message",
		icon = "",
		noremap = true,
	},
	{ "<Leader>dr", require("dap").repl.open, desc = "DAP: Open repl", icon = "", noremap = true },
	{ "<Leader>dl", require("dap").repl.run_last, desc = "DAP: Run last", icon = "", noremap = true },
	-- Telescope extension
	{ "<leader>dt", group = "Telescope", icon = "󰋖" },
	{
		"<Leader>dtc",
		require("telescope").extensions.dap.commands,
		desc = "DAP: Show commands",
		icon = "󰋖",
		noremap = true,
	},
	{
		"<Leader>dto",
		require("telescope").extensions.dap.configurations,
		desc = "DAP: Show configurations",
		icon = "󰋖",
		noremap = true,
	},
	{
		"<Leader>dtb",
		require("telescope").extensions.dap.list_breakpoints,
		desc = "DAP: Show breakpoints",
		icon = "",
		noremap = true,
	},
	{
		"<Leader>dtv",
		require("telescope").extensions.dap.variables,
		desc = "DAP: Show variables",
		icon = "󰫧",
		noremap = true,
	},
	{
		"<Leader>dtf",
		require("telescope").extensions.dap.frames,
		desc = "DAP: Show frames",
		icon = "󰋖",
		noremap = true,
	},
	-- DAP UI
	{ "<Leader>du", require("dapui").toggle, desc = "DAP: Toggle UI", icon = "", noremap = true },
	{
		"<Leader>de",
		function()
			vim.ui.input({ prompt = "Eval", default = "" }, function(input)
				require("dapui").eval(input, { enter = true })
			end)
		end,
		desc = "DAP: Evaluate expression",
		icon = "",
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
