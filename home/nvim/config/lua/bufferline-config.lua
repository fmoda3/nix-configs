require("bufferline").setup{
    options = {
        always_show_bufferline = false
    }
}

local opts = { silent = true, noremap = true }
require('legendary').bind_keymaps({
    { '[b', '<cmd>BufferLineCycleNext<cr>', description = 'BufferLine: Next buffer', opts = opts },
    { ']b', '<cmd>BufferLineCyclePrev<cr>', description = 'BufferLine: Previous buffer', opts = opts },
    { '<Leader>be', '<cmd>TroubleClose<cr>', description = 'BufferLine: Organize by extension', opts = opts },
    { '<Leader>bd', '<cmd>TroubleRefresh<cr>', description = 'BufferLine: Organize by directory', opts = opts }
})
