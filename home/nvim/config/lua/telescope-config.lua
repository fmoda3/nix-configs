-- Telescope Settings
vim.api.nvim_set_keymap('n', '<Leader>ff', [[<cmd>lua require('telescope.builtin').find_files()<cr>]], { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>fg', [[<cmd>lua require('telescope.builtin').live_grep()<cr>]], { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>fb', [[<cmd>lua require('telescope.builtin').buffers()<cr>]], { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>fh', [[<cmd>lua require('telescope.builtin').help_tags()<cr>]], { noremap = true })

-- Telescope colors
local nord = require('nord-colors')
local util = require('util')
util.colorize({
    TelescopePromptBorder =   { fg = nord.nord8_gui },
    TelescopeResultsBorder =  { fg = nord.nord9_gui },
    TelescopePreviewBorder =  { fg = nord.nord14_gui },
    TelescopeSelectionCaret = { fg = nord.nord9_gui },
    TelescopeSelection =      { fg = nord.nord9_gui },
    TelescopeMatching =       { fg = nord.nord8_gui },
})
