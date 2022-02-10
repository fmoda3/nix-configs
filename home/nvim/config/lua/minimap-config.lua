local g = vim.g
local nord = require('nord-colors')
local util = require('util')

util.colorize({
    MinimapCurrentCursor = { fg = nord.nord6_gui, bg = nord.nord15_gui },
    MinimapCurrentRange = { fg = nord.nord6_gui, bg = nord.nord3_gui }
})

-- Minimap Settings
g.minimap_width = 10
g.minimap_cursor_color = 'MinimapCurrentCursor'
g.minimap_range_color = 'MinimapCurrentRange'
g.minimap_auto_start = 1
g.minimap_auto_start_win_enter = 1
g.minimap_highlight_range = 1
g.minimap_highlight_search = 1
g.minimap_git_colors = 1

require('legendary').bind_keymaps({
    { '<leader>mm', ':MinimapToggle<cr>', opts = { silent = true }, description = 'Minimap: Toggle' },
    { '<leader>ms', ':Minimap<cr>', opts = { silent = true }, description = 'Minimap: Show' },
    { '<leader>mc', ':MinimapClose<cr>', opts = { silent = true }, description = 'Minimap: Close' },
    { '<leader>mr', ':MinimapRefresh<cr>', opts = { silent = true }, description = 'Minimap: Refresh' },
    { '<leader>mh', ':MinimapUpdateHighlight<cr>', opts = { silent = true }, description = 'Minimap: Update highlight' }
})
