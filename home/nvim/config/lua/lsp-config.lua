-- Setup lspconfig.
-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("my.lsp", {}),
	callback = function(args)
		local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
		local bufnr = args.buf

		require("illuminate").on_attach(client)

		-- Mappings.
		require("which-key").add({
			{ "<leader>l", group = "LSP", icon = "󰿘" },
			{
				"<leader>lD",
				vim.lsp.buf.declaration,
				desc = "LSP: Go to declaration",
				icon = "",
				noremap = true,
				silent = true,
				buffer = bufnr,
			},
			{
				"<leader>ld",
				"<cmd>Glance definitions<cr>",
				desc = "LSP: Go to definition",
				icon = "",
				noremap = true,
				silent = true,
				buffer = bufnr,
			},
			{
				"<leader>lk",
				vim.lsp.buf.hover,
				desc = "LSP: Hover",
				icon = "󰋖",
				noremap = true,
				silent = true,
				buffer = bufnr,
			},
			{
				"<leader>li",
				"<cmd>Glance implementations<cr>",
				desc = "LSP: Go to implementation",
				icon = "",
				noremap = true,
				silent = true,
				buffer = bufnr,
			},
			{
				"<leader>ls",
				vim.lsp.buf.signature_help,
				desc = "LSP: Signature help",
				icon = "",
				mode = { "n", "i" },
				noremap = true,
				silent = true,
				buffer = bufnr,
			},
			{ "<leader>lw", group = "Workspace", icon = "" },
			{
				"<leader>lwa",
				vim.lsp.buf.add_workspace_folder,
				desc = "LSP: Add workspace folder",
				icon = "",
				noremap = true,
				silent = true,
				buffer = bufnr,
			},
			{
				"<leader>lwr",
				vim.lsp.buf.remove_workspace_folder,
				desc = "LSP: Remove workspace folder",
				icon = "",
				noremap = true,
				silent = true,
				buffer = bufnr,
			},
			{
				"<leader>lwl",
				function()
					print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
				end,
				desc = "LSP: List workspaces",
				icon = "",
				noremap = true,
				silent = true,
				buffer = bufnr,
			},
			{
				"<leader>lt",
				"<cmd>Glance type_definitions<cr>",
				desc = "LSP: Show type definition",
				icon = "",
				noremap = true,
				silent = true,
				buffer = bufnr,
			},
			{
				"<leader>ln",
				vim.lsp.buf.rename,
				desc = "LSP: Rename",
				icon = "󰑕",
				noremap = true,
				silent = true,
				buffer = bufnr,
			},
			{
				"<leader>la",
				vim.lsp.buf.code_action,
				desc = "LSP: Code Action",
				icon = "",
				noremap = true,
				silent = true,
				buffer = bufnr,
			},
			{
				"<leader>lr",
				"<cmd>Glance references<cr>",
				desc = "LSP: Show references",
				icon = "",
				noremap = true,
				silent = true,
				buffer = bufnr,
			},
			{
				"<leader>xw",
				function()
					vim.diagnostic.open_float({ scope = "line" })
				end,
				desc = "Diagnostics: Show window",
				icon = "󱖫",
				noremap = true,
				silent = true,
				buffer = bufnr,
			},
			{
				"[d",
				function()
					vim.diagnostic.jump({ count = -1, float = { border = "single" } })
				end,
				desc = "Diagnostics: Previous",
				icon = "󰒮",
				noremap = true,
				silent = true,
				buffer = bufnr,
			},
			{
				"]d",
				function()
					vim.diagnostic.jump({ count = 1, float = { border = "single" } })
				end,
				desc = "Diagnostics: Next",
				icon = "󰒭",
				noremap = true,
				silent = true,
				buffer = bufnr,
			},
			{
				"<leader>xq",
				vim.diagnostic.setloclist,
				desc = "Diagnostics: Show location list",
				icon = "󱖫",
				noremap = true,
				silent = true,
				buffer = bufnr,
			},
			{
				"<leader>lf",
				vim.lsp.buf.formatting,
				desc = "LSP: Format file",
				icon = "",
				noremap = true,
				silent = true,
				buffer = bufnr,
			},
			{
				"]u",
				function()
					require("illuminate").next_reference({ wrap = true })
				end,
				desc = "Illuminate: Next reference",
				icon = "󰒭",
				noremap = true,
				silent = true,
				buffer = bufnr,
			},
			{
				"[u",
				function()
					require("illuminate").next_reference({ reverse = true, wrap = true })
				end,
				desc = "Illuminate: Previous reference",
				icon = "󰒮",
				noremap = true,
				silent = true,
				buffer = bufnr,
			},
		})

		-- LSP-specific configurations
		if client and client.name == "ts_ls" then
			-- Let eslint format
			client.server_capabilities.document_formatting = false
			client.server_capabilities.document_range_formatting = false
		end

		if client and client.supports_method("textDocument/inlayHint") then
			vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
		end

		-- Auto-format ("lint") on save.
		-- Usually not needed if server supports "textDocument/willSaveWaitUntil".
		if
			not client:supports_method("textDocument/willSaveWaitUntil")
			and client:supports_method("textDocument/formatting")
		then
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = vim.api.nvim_create_augroup("my.lsp", { clear = false }),
				buffer = args.buf,
				callback = function()
					vim.lsp.buf.format({ bufnr = args.buf, id = client.id, timeout_ms = 1000 })
				end,
			})
		end
	end,
})

local notify = require("notify")
vim.lsp.handlers["window/showMessage"] = function(_, result, ctx)
	local client = vim.lsp.get_client_by_id(ctx.client_id)
	local lvl = ({ "ERROR", "WARN", "INFO", "DEBUG" })[result.type]
	notify({ result.message }, lvl, {
		title = "LSP | " .. client.name,
		timeout = 10000,
		keep = function()
			return lvl == "ERROR" or lvl == "WARN"
		end,
	})
end

local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

-- Global capabilities
local capabilities = require("blink.cmp").get_lsp_capabilities()
vim.lsp.config("*", {
	capabilities = capabilities,
	root_markers = { ".git" },
})

-- Enable Language Servers
-- Bash
vim.lsp.enable("bashls")
-- Dart
vim.lsp.enable("dartls")
-- Elixir
vim.lsp.enable("elixirls", {
	cmd = { "elixir-ls" },
	-- Settings block is required, as there is no default set for elixir
	settings = {
		elixirLs = {
			dialyzerEnabled = true,
			dialyzerFormat = "dialyxir_long",
		},
	},
})
-- Gleam
vim.lsp.enable("gleam")
-- Haskell
vim.lsp.enable("hls")
-- Kotlin
vim.lsp.enable("kotlin_lsp")
-- Lua
local runtime_path = vim.split(package.path, ";")
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")
vim.lsp.enable("lua_ls", {
	settings = {
		Lua = {
			runtime = {
				-- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
				version = "LuaJIT",
				-- Setup your lua path
				path = runtime_path,
			},
			completion = {
				callSnippet = "Replace",
			},
			diagnostics = {
				-- Get the language server to recognize the `vim` global
				globals = { "vim" },
			},
			workspace = {
				-- Make the server aware of Neovim runtime files
				library = vim.api.nvim_get_runtime_file("", true),
				checkThirdParty = false,
			},
			-- Do not send telemetry data containing a randomized but unique identifier
			telemetry = {
				enable = false,
			},
		},
	},
})
-- Nix
vim.lsp.enable("nixd", {
	settings = {
		nixd = {
			nixpkgs = {
				expr = 'import (builtins.getFlake "${builtins.getEnv "HOME"}/.nix-configs").inputs.nixpkgs { }',
			},
			formatting = {
				command = { "nixfmt" },
			},
			options = {
				nixos = {
					expr = '(builtins.getFlake "${builtins.getEnv "HOME"}/.nix-configs").nixosConfigurations.cicucci-homelab.options',
				},
				darwin = {
					expr = '(builtins.getFlake "${builtins.getEnv "HOME"}/.nix-configs").darwinConfigurations.cicucci-laptop.options',
				},
				home_manager = {
					expr = '(builtins.getFlake "${builtins.getEnv "HOME"}/.nix-configs").darwinConfigurations.cicucci-laptop.options.home-manager.users.type.getSubOptions []',
				},
			},
		},
	},
})
-- Python
vim.lsp.enable("pyright")
-- Typescript
vim.lsp.enable("ts_ls")
-- Web
-- ESLint
vim.lsp.enable("eslint")
-- CSS
vim.lsp.enable("cssls")
-- HTML
vim.lsp.enable("html")
-- JSON
vim.lsp.enable("jsonls")

-- NULL
local null_ls = require("null-ls")
null_ls.setup({
	sources = {
		-- Elixir
		null_ls.builtins.diagnostics.credo,

		-- Nix
		null_ls.builtins.diagnostics.statix,
		null_ls.builtins.code_actions.statix,

		-- Python
		null_ls.builtins.formatting.black,
	},
})

vim.api.nvim_exec_autocmds("FileType", {})
