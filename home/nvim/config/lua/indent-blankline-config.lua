local nord = require('nord-colors')
local util = require('util')
util.colorize({
    IndentBlanklineChar =        { fg = nord.nord3_gui },
    IndentBlanklineContextChar = { fg = nord.nord10_gui },
})

require("indent_blankline").setup {
    space_char_blankline = " ",
    show_current_context = true,
    show_current_context_start = true
}
