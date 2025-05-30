local opt = vim.opt
local g = vim.g

-- global options --
opt.incsearch = true -- Find the next match as we type the search
opt.hlsearch = true -- Hilight searches by default
opt.viminfo = "'100,f1" -- Save up to 100 marks, enable capital marks
opt.ignorecase = true -- Ignore case when searching...
opt.smartcase = true -- ...unless we type a capital
opt.autoindent = true
opt.smartindent = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.termguicolors = true
opt.cursorline = true
opt.relativenumber = true
opt.number = true
opt.signcolumn = "yes:2"

-- Set leader key
g.mapleader = ","

-- Color Scheme Settings
vim.cmd.colorscheme("catppuccin-frappe")

-- Movement keybinds
local opts = { noremap = true }
require("legendary").keymaps({
	{ "<C-h>", "<C-w>h", description = "Panes: Move left", opts = opts },
	{ "<C-j>", "<C-w>j", description = "Panes: Move down", opts = opts },
	{ "<C-k>", "<C-w>k", description = "Panes: Move up", opts = opts },
	{ "<C-l>", "<C-w>l", description = "Panes: Move right", opts = opts },
})

vim.diagnostic.config({
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "",
			[vim.diagnostic.severity.WARN] = "",
			[vim.diagnostic.severity.INFO] = "\u{f05a}",
			[vim.diagnostic.severity.HINT] = "",
		},
	},
	virtual_text = true,
})
