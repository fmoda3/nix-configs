-- Setup lightbulb sign to indicate a code action is available
vim.cmd([[autocmd CursorHold,CursorHoldI * lua require'nvim-lightbulb'.update_lightbulb()]])

-- Change to yellow lightbulb icon
util.colorize({
	LightBulbSignColor = { fg = colors.yellow },
})
vim.fn.sign_define("LightBulbSign", { text = "", texthl = "LightBulbSignColor", linehl = "", numhl = "" })
