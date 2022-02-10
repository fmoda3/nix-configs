local nord = require("nord-colors")
local util = require("util")

-- CMP Colors
util.colorize({
    CmpItemKind = { fg = nord.nord15_gui },
    CmpItemAbbrMatch =  { fg = nord.nord5_gui, style = 'bold' },
    CmpItemAbbrMatchFuzzy = { fg = nord.nord5_gui, style = 'bold' },
    CmpItemAbbr = { fg = nord.nord4_gui},
    CmpItemMenu = { fg = nord.nord14_gui },
})

-- Autocompletion setup
local has_words_before = function()
    local line, col = table.unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local feedkey = function(key, mode)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
end

local cmp = require'cmp'
local cmp_autopairs = require('nvim-autopairs.completion.cmp')
local lspkind = require('lspkind')

cmp.event:on( 'confirm_done', cmp_autopairs.on_confirm_done({ map_char = { tex = '' } }))

cmp.setup({
    completion = {
        completeopt = 'menu,menuone,noselect,noinsert'
    },
    snippet = {
        expand = function(args)
            vim.fn["vsnip#anonymous"](args.body)
        end,
    },
    mapping = {
        ['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
        ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
        ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
        ['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
        ['<C-e>'] = cmp.mapping({
            i = cmp.mapping.abort(),
            c = cmp.mapping.close(),
        }),
        ['<CR>'] = cmp.mapping.confirm({ select = false }),
        ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif vim.fn["vsnip#available"](1) == 1 then
                feedkey("<Plug>(vsnip-expand-or-jump)", "")
            elseif has_words_before() then
                cmp.complete()
            else
                fallback() -- The fallback function sends a already mapped key. In this case, it's probably `<Tab>`.
            end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function()
            if cmp.visible() then
                cmp.select_prev_item()
            elseif vim.fn["vsnip#jumpable"](-1) == 1 then
                feedkey("<Plug>(vsnip-jump-prev)", "")
            end
        end, { "i", "s" })
    },
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'nvim_lsp_signature_help' },
        { name = 'vsnip' },
    }, {
        { name = 'buffer' },
    }),
    formatting = {
        format = lspkind.cmp_format(),
    }
})

-- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline('/', {
    sources = {
        { name = 'buffer' }
    }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
-- cmp.setup.cmdline(':', {
--    sources = cmp.config.sources({
--        { name = 'path' }
--    }, {
--        { name = 'cmdline' }
--    })
--})

-- Setup lspconfig.
local nvim_lsp = require('lspconfig')
-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
    local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

    -- Enable completion triggered by <c-x><c-o>
    buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings.
    local opts = { noremap=true, silent=true, buffer=true }
    require('legendary').bind_keymaps({
        { 'gD', vim.lsp.buf.declaration, description = 'LSP: Go to declaration', opts = opts },
        { 'gd', vim.lsp.buf.definition, description = 'LSP: Go to definition', opts = opts },
        { 'K', vim.lsp.buf.hover, description = 'LSP: Hover', opts = opts },
        { 'gi', vim.lsp.buf.implementation, description = 'LSP: Go to implementation', opts = opts },
        { '<C-s>', vim.lsp.buf.signature_help, description = 'LSP: Signature help', opts = opts },
        { '<space>wa', vim.lsp.buf.add_workspace_folder, description = 'LSP: Add workspace folder', opts = opts },
        { '<space>wr', vim.lsp.buf.remove_workspace_folder, description = 'LSP: Remove workspace folder', opts = opts },
        { '<space>wl', function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end, description = 'LSP: List workspaces', opts = opts },
        { '<space>D', vim.lsp.buf.type_definition, description = 'LSP: Show type definition', opts = opts },
        { '<space>rn', vim.lsp.buf.rename, description = 'LSP: Rename', opts = opts },
        { '<space>ca', vim.lsp.buf.code_action, description = 'LSP: Code Action', opts = opts },
        { 'gr', vim.lsp.buf.references, description = 'LSP: Show references', opts = opts },
        { '<space>e', function() vim.diagnostic.open_float(0, {scope="line"}) end, description = 'Diagnostics: Show window', opts = opts },
        { '[d', function() vim.diagnostic.goto_prev({ float =  { border = "single" }}) end, description = 'Diagnostics: Previous', opts = opts },
        { ']d', function() vim.diagnostic.goto_next({ float =  { border = "single" }}) end, description = 'Diagnostics: Next', opts = opts },
        { '<space>q', vim.diagnostic.setloclist, description = 'Diagnostic: Show location list', opts = opts },
        { '<space>f', vim.lsp.buf.formatting, description = 'LSP: Format file', opts = opts }
    })

    -- if client.resolved_capabilities.document_formatting then
    --     vim.cmd([[
    --         augroup LspFormatting
    --             autocmd! * <buffer>
    --             autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()
    --         augroup END
    --         ]])
    -- end
end


local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
-- Enable Language Servers
local function default_lsp_setup(module)
    nvim_lsp[module].setup{
        on_attach = on_attach,
        capabilities = capabilities
    }
end
-- Bash
default_lsp_setup('bashls')
-- Elixir
nvim_lsp.elixirls.setup{
    cmd = { 'elixir-ls' },
    -- Settings block is required, as there is no default set for elixir
    settings = {
        elixirLs = {
            dialyzerEnabled = true,
            dialyzerFormat = "dialyxir_long"
        }
    },
    on_attach = on_attach,
    capabilities = capabilities
}
-- Erlang
default_lsp_setup('erlangls')
-- Java
nvim_lsp.java_language_server.setup{
    cmd = { 'java-language-server' },
    on_attach = on_attach,
    capabilities = capabilities
}
-- Kotlin
default_lsp_setup('kotlin_language_server')
-- Lua
local runtime_path = vim.split(package.path, ';')
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")
nvim_lsp.sumneko_lua.setup{
    settings = {
        Lua = {
            runtime = {
                -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                version = 'LuaJIT',
                -- Setup your lua path
                path = runtime_path,
            },
            diagnostics = {
                -- Get the language server to recognize the `vim` global
                globals = {'vim'},
            },
            workspace = {
                -- Make the server aware of Neovim runtime files
                library = vim.api.nvim_get_runtime_file("", true),
            },
            -- Do not send telemetry data containing a randomized but unique identifier
            telemetry = {
                enable = false,
            }
        }
    },
    on_attach = on_attach,
    capabilities = capabilities
}
-- Nix
default_lsp_setup('rnix')
-- Python
default_lsp_setup('pyright')
-- Typescript
nvim_lsp.tsserver.setup{
    init_options = require("nvim-lsp-ts-utils").init_options,
    on_attach = function(client, bufnr)
        on_attach(client, bufnr)

        client.resolved_capabilities.document_formatting = false
        client.resolved_capabilities.document_range_formatting = false

        local ts_utils = require("nvim-lsp-ts-utils")
        ts_utils.setup({
            enable_import_on_completion = true
        })
        ts_utils.setup_client(client)

        -- Mappings.
        local opts = { noremap=true, silent=true, buffer=true }
        require('legendary').bind_keymaps({
            { 'gto', ':TSLspOrganize<CR>', description = 'LSP: Organize imports', opts = opts },
            { 'gtr', ':TSLspRenameFile<CR>', description = 'LSP: Rename file', opts = opts },
            { 'gti', ':TSLspImportAll<CR>', description = 'LSP: Import missing imports', opts = opts }
        })
    end,
    capabilities = capabilities
}
-- Web
-- ESLint
nvim_lsp.eslint.setup{
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
    capabilities = capabilities
}
-- CSS
default_lsp_setup('cssls')
-- HTML
default_lsp_setup('html')
-- JSON
default_lsp_setup('jsonls')
