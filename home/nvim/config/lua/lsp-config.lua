-- Setup lspconfig.
local nvim_lsp = require("lspconfig")
-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
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

	if client and client.supports_method("textDocument/inlayHint") then
		vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
	end

	-- if client.server_capabilities.document_formatting then
	--     vim.cmd([[
	--         augroup LspFormatting
	--             autocmd! * <buffer>
	--             autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()
	--         augroup END
	--         ]])
	-- end
end

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

local capabilities = require("blink.cmp").get_lsp_capabilities()
-- Enable Language Servers
local function default_lsp_setup(module)
	nvim_lsp[module].setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end
-- Bash
default_lsp_setup("bashls")
-- Dart
default_lsp_setup("dartls")
-- Elixir
nvim_lsp.elixirls.setup({
	cmd = { "elixir-ls" },
	-- Settings block is required, as there is no default set for elixir
	settings = {
		elixirLs = {
			dialyzerEnabled = true,
			dialyzerFormat = "dialyxir_long",
		},
	},
	on_attach = on_attach,
	capabilities = capabilities,
})
-- Gleam
default_lsp_setup("gleam")
-- Haskell
default_lsp_setup("hls")
-- Kotlin
default_lsp_setup("kotlin_lsp")
-- Lua
local runtime_path = vim.split(package.path, ";")
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")
nvim_lsp.lua_ls.setup({
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
	on_attach = on_attach,
	capabilities = capabilities,
})
-- Nix
nvim_lsp.nixd.setup({
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
	on_attach = on_attach,
})
-- Python
default_lsp_setup("pyright")
-- Typescript
nvim_lsp.ts_ls.setup({
	init_options = require("nvim-lsp-ts-utils").init_options,
	on_attach = function(client, bufnr)
		on_attach(client, bufnr)

		-- Let eslint format
		client.server_capabilities.document_formatting = false
		client.server_capabilities.document_range_formatting = false

		local ts_utils = require("nvim-lsp-ts-utils")
		ts_utils.setup({
			enable_import_on_completion = true,
		})
		ts_utils.setup_client(client)

		-- Mappings.
		require("which-key").add({
			{
				"<leader>lio",
				":TSLspOrganize<CR>",
				desc = "LSP: Organize imports",
				icon = "󰋺",
				noremap = true,
				silent = true,
				buffer = true,
			},
			{
				"<leader>ltr",
				":TSLspRenameFile<CR>",
				desc = "LSP: Rename file",
				icon = "󰑕",
				noremap = true,
				silent = true,
				buffer = true,
			},
			{
				"<leader>lia",
				":TSLspImportAll<CR>",
				desc = "LSP: Import missing imports",
				icon = "󰋺",
				noremap = true,
				silent = true,
				buffer = true,
			},
		})
	end,
	capabilities = capabilities,
})
-- Web
-- ESLint
nvim_lsp.eslint.setup({
	on_attach = function(client, bufnr)
		on_attach(client, bufnr)
		-- Run all eslint fixes on save
		vim.cmd([[
            augroup EslintOnSave
                autocmd! * <buffer>
                autocmd BufWritePre <buffer> EslintFixAll
            augroup END
            ]])
	end,
	capabilities = capabilities,
})
-- CSS
default_lsp_setup("cssls")
-- HTML
default_lsp_setup("html")
-- JSON
default_lsp_setup("jsonls")

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
