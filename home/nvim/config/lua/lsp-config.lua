-- Setup lspconfig.
-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("my.lsp", {}),
	callback = function(args)
		local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
		local bufnr = args.buf

		-- Initialize code action lib
		require("tiny-code-action").setup({
			backend = "vim",
		})

		-- Mappings
		local wk = require("which-key")
		wk.add({
			{ "<leader>l", group = "LSP", icon = "󰿘" },
		})

		-- Navigation
		if client:supports_method("textDocument/declaration") then
			wk.add({
				{
					"<leader>lD",
					vim.lsp.buf.declaration,
					desc = "LSP: Go to declaration",
					icon = "",
					noremap = true,
					silent = true,
					buffer = bufnr,
				},
			})
		end
		if client:supports_method("textDocument/definition") then
			wk.add({
				{
					"<leader>ld",
					"<cmd>Glance definitions<cr>",
					desc = "LSP: Go to definition",
					icon = "",
					noremap = true,
					silent = true,
					buffer = bufnr,
				},
			})
		end
		if client:supports_method("textDocument/typeDefinition") then
			wk.add({
				{
					"<leader>lt",
					"<cmd>Glance type_definitions<cr>",
					desc = "LSP: Show type definition",
					icon = "",
					noremap = true,
					silent = true,
					buffer = bufnr,
				},
			})
		end
		if client:supports_method("textDocument/implementation") then
			wk.add({
				{
					"<leader>li",
					"<cmd>Glance implementations<cr>",
					desc = "LSP: Go to implementation",
					icon = "",
					noremap = true,
					silent = true,
					buffer = bufnr,
				},
			})
		end
		if client:supports_method("textDocument/references") then
			wk.add({
				{
					"<leader>lr",
					"<cmd>Glance references<cr>",
					desc = "LSP: Show references",
					icon = "",
					noremap = true,
					silent = true,
					buffer = bufnr,
				},
			})
		end

		-- Code Actions
		if client:supports_method("textDocument/codeAction") then
			wk.add({
				{
					"<leader>la",
					function()
						require("tiny-code-action").code_action()
					end,
					desc = "LSP: Code Action",
					icon = "",
					noremap = true,
					silent = true,
					buffer = bufnr,
				},
			})
		end
		if client:supports_method("textDocument/rename") then
			wk.add({
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
					"<leader>lN",
					function()
						return ":IncRename " .. vim.fn.expand("<cword>")
					end,
					desc = "LSP: Incremental Rename",
					icon = "󰑕",
					noremap = true,
					expr = true,
					buffer = bufnr,
				},
			})
		end
		if client:supports_method("textDocument/formatting") then
			wk.add({
				{
					"<leader>lf",
					function()
						vim.lsp.buf.format({ bufnr = bufnr, id = client.id, timeout_ms = 1000 })
					end,
					desc = "LSP: Format file",
					icon = "",
					noremap = true,
					silent = true,
					buffer = bufnr,
				},
			})
		end

		-- Information Displays
		if client:supports_method("textDocument/hover") then
			wk.add({
				{
					"<leader>lk",
					require("hover").hover,
					desc = "LSP: Hover",
					icon = "󰋖",
					noremap = true,
					silent = true,
					buffer = bufnr,
				},
				{
					"<leader>lK",
					require("hover").hover_select,
					desc = "LSP: Hover select source",
					icon = "󰋖",
					noremap = true,
					silent = true,
					buffer = bufnr,
				},
				{
					"<leader>lh",
					function()
						require("hover").hover_switch("previous")
					end,
					desc = "LSP: Hover previous source",
					icon = "󰋖",
					noremap = true,
					silent = true,
					buffer = bufnr,
				},
				{
					"<leader>lj",
					function()
						require("hover").hover_switch("next")
					end,
					desc = "LSP: Hover next source",
					icon = "󰋖",
					noremap = true,
					silent = true,
					buffer = bufnr,
				},
			})
		end
		if client:supports_method("textDocument/signatureHelp") then
			wk.add({
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
			})
		end

		-- Workspaces
		wk.add({
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
		})

		-- Diagnostics
		wk.add({
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
		})

		-- Illuminate
		require("illuminate").on_attach(client)
		require("which-key").add({
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
				buffer = bufnr,
				callback = function()
					vim.lsp.buf.format({ bufnr = bufnr, id = client.id, timeout_ms = 1000 })
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
vim.lsp.config("elixirls", {
	cmd = { "elixir-ls" },
	-- Settings block is required, as there is no default set for elixir
	settings = {
		elixirLs = {
			dialyzerEnabled = true,
			dialyzerFormat = "dialyxir_long",
		},
	},
})
vim.lsp.enable("elixirls")
-- Flix
vim.filetype.add({
	extension = {
		flix = "flix",
	},
})
vim.lsp.config("flix", {
	cmd = { "flix", "lsp" },
	filetypes = { "flix" },
	root_markers = { "flix.toml", "flix.jar" },
	settings = {},
})
vim.lsp.enable("flix")
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
vim.lsp.config("lua_ls", {
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
vim.lsp.enable("lua_ls")
-- Nix
vim.lsp.config("nixd", {
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
vim.lsp.enable("nixd")
-- Python
vim.lsp.enable("pyright")
-- Typescript
vim.lsp.enable("ts_ls")
-- Typst
vim.lsp.enable("tinymist")
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
