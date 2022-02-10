require("trouble").setup {}

vim.api.nvim_set_keymap('n', '<Leader>xx', [[<cmd>Trouble<cr>]], { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>xw', [[<cmd>Trouble workspace_diagnostics<cr>]], { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>xd', [[<cmd>Trouble document_diagnostics<cr>]], { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>xl', [[<cmd>Trouble loclist<cr>]], { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>xq', [[<cmd>Trouble quickfix<cr>]], { silent = true, noremap = true })
vim.api.nvim_set_keymap('n', 'gR', [[<cmd>Trouble lsp_references<cr>]], { silent = true, noremap = true })
