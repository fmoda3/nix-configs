-- Setup lspconfig.
local nvim_lsp = require("lspconfig")
-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
	require("illuminate").on_attach(client)

	-- Mappings.
	require("which-key").add({
		{
			"gD",
			vim.lsp.buf.declaration,
			desc = "LSP: Go to declaration",
			noremap = true,
			silent = true,
			buffer = bufnr,
		},
		{ "gd", vim.lsp.buf.definition, desc = "LSP: Go to definition", noremap = true, silent = true, buffer = bufnr },
		{ "K", vim.lsp.buf.hover, desc = "LSP: Hover", noremap = true, silent = true, buffer = bufnr },
		{
			"gi",
			vim.lsp.buf.implementation,
			desc = "LSP: Go to implementation",
			noremap = true,
			silent = true,
			buffer = bufnr,
		},
		{
			"<C-s>",
			vim.lsp.buf.signature_help,
			desc = "LSP: Signature help",
			mode = { "n", "i" },
			noremap = true,
			silent = true,
			buffer = bufnr,
		},
		{
			"<space>wa",
			vim.lsp.buf.add_workspace_folder,
			desc = "LSP: Add workspace folder",
			noremap = true,
			silent = true,
			buffer = bufnr,
		},
		{
			"<space>wr",
			vim.lsp.buf.remove_workspace_folder,
			desc = "LSP: Remove workspace folder",
			noremap = true,
			silent = true,
			buffer = bufnr,
		},
		{
			"<space>wl",
			function()
				print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
			end,
			desc = "LSP: List workspaces",
			noremap = true,
			silent = true,
			buffer = bufnr,
		},
		{
			"<space>D",
			vim.lsp.buf.type_definition,
			desc = "LSP: Show type definition",
			noremap = true,
			silent = true,
			buffer = bufnr,
		},
		{ "<space>rn", vim.lsp.buf.rename, desc = "LSP: Rename", noremap = true, silent = true, buffer = bufnr },
		{
			"<space>ca",
			vim.lsp.buf.code_action,
			desc = "LSP: Code Action",
			noremap = true,
			silent = true,
			buffer = bufnr,
		},
		{ "gr", vim.lsp.buf.references, desc = "LSP: Show references", noremap = true, silent = true, buffer = bufnr },
		{
			"<space>e",
			function()
				vim.diagnostic.open_float({ scope = "line" })
			end,
			desc = "Diagnostics: Show window",
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
			noremap = true,
			silent = true,
			buffer = bufnr,
		},
		{
			"]d",
			function()
				vim.diagnostic.jump({ float = { border = "single" } })
			end,
			desc = "Diagnostics: Next",
			noremap = true,
			silent = true,
			buffer = bufnr,
		},
		{
			"<space>q",
			vim.diagnostic.setloclist,
			desc = "Diagnostic: Show location list",
			noremap = true,
			silent = true,
			buffer = bufnr,
		},
		{
			"<space>f",
			vim.lsp.buf.formatting,
			desc = "LSP: Format file",
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
				"gto",
				":TSLspOrganize<CR>",
				desc = "LSP: Organize imports",
				noremap = true,
				silent = true,
				buffer = true,
			},
			{ "gtr", ":TSLspRenameFile<CR>", desc = "LSP: Rename file", noremap = true, silent = true, buffer = true },
			{
				"gti",
				":TSLspImportAll<CR>",
				desc = "LSP: Import missing imports",
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
