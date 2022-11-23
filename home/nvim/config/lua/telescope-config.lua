-- Telescope Settings
local opts = { noremap = true }
require('legendary').keymaps({
    { '<Leader>ff', require('telescope.builtin').find_files, description = 'Telescope: Find files', opts = opts },
    { '<Leader>fg', require('telescope.builtin').live_grep, description = 'Telescope: Live grep', opts = opts },
    { '<Leader>fb', require('telescope.builtin').buffers, description = 'Telescope: Buffers', opts = opts },
    { '<Leader>fh', require('telescope.builtin').help_tags, description = 'Telescope: Help tags', opts = opts }
})
