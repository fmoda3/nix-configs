local nord = require('nord-colors')
local util = require('util')
util.colorize({
    NvimTreeRootFolder =        { fg = nord.nord7_gui, style = "bold" },
    NvimTreeGitDirty =          { fg = nord.nord15_gui },
    NvimTreeGitNew =            { fg = nord.nord14_gui },
    NvimTreeImageFile =         { fg = nord.nord15_gui },
    NvimTreeExecFile =          { fg = nord.nord14_gui },
    NvimTreeSpecialFile =       { fg = nord.nord9_gui , style = "underline" },
    NvimTreeFolderName=         { fg = nord.nord10_gui },
    NvimTreeEmptyFolderName=    { fg = nord.nord1_gui },
    NvimTreeFolderIcon=         { fg = nord.nord4_gui },
    NvimTreeIndentMarker =      { fg  = nord.nord1_gui },
})

require'nvim-tree'.setup {
    disable_netrw       = true,
    hijack_netrw        = true,
    open_on_setup       = false,
    ignore_ft_on_setup  = {},

    update_to_buf_dir   = {
        enable = true,
        auto_open = true,
    },

    auto_close          = false,
    open_on_tab         = false,
    hijack_cursor       = false,
    update_cwd          = false,
    diagnostics         = {
        enable = true,
        icons = {
            hint = "",
            info = "",
            warning = "",
            error = "",
        }
    },
    update_focused_file = {
        enable      = false,
        update_cwd  = false,
        ignore_list = {}
    },
    system_open = {
    cmd  = nil,
    args = {}
    },
    view = {
        width = 25,
        height = 30,
        side = 'left',
        auto_resize = true,
        mappings = {
            custom_only = false,
            list = {}
        }
    }
}

require('legendary').bind_keymaps({
    { '<leader>tt', ':NvimTreeToggle<cr>', opts = { silent = true }, description = 'Nvim Tree: Toggle' },
    { '<leader>tr', ':NvimTreeRefresh<cr>', opts = { silent = true }, description = 'Nvim Tree: Refresh' },
    { '<leader>tf', ':NvimTreeFindFile<cr>', opts = { silent = true }, description = 'Nvim Tree: Find file' }
})
