local nord = require('nord-colors')
local util = require('util')
util.colorize({
	GitSignsAdd =   { fg = nord.nord14_gui },
    GitSignsAddNr = { fg = nord.nord14_gui },
    GitSignsAddLn = { fg = nord.nord14_gui },
    GitSignsChange =  { fg = nord.nord13_gui },
    GitSignsChangeNr = { fg = nord.nord13_gui },
    GitSignsChangeLn = { fg = nord.nord13_gui },
    GitSignsDelete =  { fg = nord.nord12_gui },
    GitSignsDeleteNr = { fg = nord.nord12_gui },
    GitSignsDeleteLn = { fg = nord.nord12_gui }
})

require('gitsigns').setup()
