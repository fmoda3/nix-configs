-- Telescope Settings
local opts = { noremap = true }
require('legendary').bind_keymaps({
    { '<Leader>ff', require('telescope.builtin').find_files, description = 'Telescope: Find files', opts = opts },
    { '<Leader>fg', require('telescope.builtin').live_grep, description = 'Telescope: Live grep', opts = opts },
    { '<Leader>fb', require('telescope.builtin').buffers, description = 'Telescope: Buffers', opts = opts },
    { '<Leader>fh', require('telescope.builtin').help_tags, description = 'Telescope: Help tags', opts = opts }
})

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
