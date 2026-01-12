local available_parsers = vim.tbl_keys(require("nvim-treesitter.parsers"))

for _, parser in ipairs(available_parsers) do
	local filetypes = parser -- In this case, parser is the filetype/language name
	vim.treesitter.language.register(parser, filetypes)

	vim.api.nvim_create_autocmd({ "FileType" }, {
		pattern = filetypes,
		callback = function(event)
			vim.treesitter.start(event.buf, parser)
		end,
	})
end
