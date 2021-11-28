-- Autocompletion setup
vim.o.completeopt = "menu,menuone,noselect"

local has_words_before = function()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end
      
local feedkey = function(key, mode)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
end

local cmp = require'cmp'
local lspkind = require('lspkind')
cmp.setup({
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
	['<CR>'] = cmp.mapping.confirm({ select = true }),
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
--     sources = cmp.config.sources({
-- 	{ name = 'path' }
--     }, {
-- 	{ name = 'cmdline' }
--     })
-- })
    
-- Setup lspconfig.
local nvim_lsp = require('lspconfig')
-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
    local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end
      
    -- Enable completion triggered by <c-x><c-o>
    buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')
      
    -- Mappings.
    local opts = { noremap=true, silent=true }
      
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
    buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
    buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
    buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
    buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
    buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
    buf_set_keymap('n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
end


local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
-- Enable Language Servers
-- Nix
require'lspconfig'.rnix.setup{
    on_attach = on_attach,
    capabilities = capabilities
}
-- Java
require'lspconfig'.java_language_server.setup{
    cmd = { 'java-language-server' },
    on_attach = on_attach,
    capabilities = capabilities
}
-- Python
require'lspconfig'.pyright.setup{
    on_attach = on_attach,
    capabilities = capabilities
}
-- Elixir
require'lspconfig'.elixirls.setup{
    cmd = { 'elixir-ls' },
    on_attach = on_attach,
    capabilities = capabilities
}
