vim.cmd [[highlight IndentBlanklineIndent1 guifg=#BF616A gui=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent2 guifg=#D08770 gui=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent3 guifg=#EBCB8B gui=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent4 guifg=#A3BE8C gui=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent5 guifg=#5E81AC gui=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent6 guifg=#B48EAD gui=nocombine]]

require("indent_blankline").setup {
    space_char_blankline = " ",
    char_highlight_list = {
        "IndentBlanklineIndent1",
        "IndentBlanklineIndent2",
        "IndentBlanklineIndent3",
        "IndentBlanklineIndent4",
        "IndentBlanklineIndent5",
        "IndentBlanklineIndent6",
    },
}
