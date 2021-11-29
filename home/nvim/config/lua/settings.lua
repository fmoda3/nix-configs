local opt = vim.opt
local fn = vim.fn
local env = vim.env
local g = vim.g

-- global options --
opt.incsearch = true    -- Find the next match as we type the search
opt.hlsearch = true     -- Hilight searches by default
opt.viminfo = "'100,f1" -- Save up to 100 marks, enable capital marks
opt.ignorecase = true   -- Ignore case when searching...
opt.smartcase = true    -- ...unless we type a capital
opt.autoindent = true
opt.smartindent = true
opt.expandtab = true
opt.termguicolors = true
opt.cursorline = true
opt.relativenumber = true
opt.number = true

-- Color Scheme Settings
vim.cmd("syntax enable")
vim.cmd("colorscheme nord")
opt.background="dark"

-- Minimap Settings
g.minimap_width = 10
vim.cmd [[hi MinimapCurrentRange ctermfg=5 guibg=#2e333f guifg=#b48dac]]
g.minimap_range_color = 'MinimapCurrentRange'
g.minimap_auto_start = 1
g.minimap_auto_start_win_enter = 1
g.minimap_highlight_range = 1
g.minimap_highlight_search = 1
g.minimap_git_colors = 1

-- Telescope Settings
vim.api.nvim_set_keymap('n', '<Leader>ff', [[<cmd>lua require('telescope.builtin').find_files()<cr>]], { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>fg', [[<cmd>lua require('telescope.builtin').live_grep()<cr>]], { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>fb', [[<cmd>lua require('telescope.builtin').buffers()<cr>]], { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>fh', [[<cmd>lua require('telescope.builtin').help_tags()<cr>]], { noremap = true })
