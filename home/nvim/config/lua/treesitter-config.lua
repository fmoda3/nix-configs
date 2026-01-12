local parser_files = vim.api.nvim_get_runtime_file("parser/*", true)
local installed_parsers = {}
local seen_parsers = {}

for _, parser_file in ipairs(parser_files) do
	local parser = vim.fn.fnamemodify(parser_file, ":t:r")

	if parser ~= "" and not seen_parsers[parser] then
		seen_parsers[parser] = true
		table.insert(installed_parsers, parser)
	end
end

table.sort(installed_parsers)

for _, parser in ipairs(installed_parsers) do
	local filetypes = parser -- In this case, parser is the filetype/language name
	vim.treesitter.language.register(parser, filetypes)

	vim.api.nvim_create_autocmd({ "FileType" }, {
		pattern = filetypes,
		callback = function(event)
			vim.treesitter.start(event.buf, parser)
		end,
	})
end
