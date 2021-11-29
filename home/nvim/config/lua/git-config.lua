local nord = require('nord-colors')
local util = require('util')
util.colorize({
    diffAdded =     { fg = nord.nord14_gui },
    diffRemoved =   { fg = nord.nord11_gui },
    diffChanged =   { fg = nord.nord15_gui },
    diffOldFile =   { fg = nord.nord13_gui },
    diffNewFile =   { fg = nord.nord12_gui },
    diffFile =      { fg = nord.nord7_gui },
    diffLine =      { fg = nord.nord3_gui },
    diffIndexLine = { fg = nord.nord9_gui },
})

util.colorize({
    GitGutterAdd =    { fg = nord.nord14_gui }, -- diff mode: Added line |diff.txt|
    GitGutterChange = { fg = nord.nord15_gui }, -- diff mode: Changed line |diff.txt|
    GitGutterDelete = { fg = nord.nord11_gui }, -- diff mode: Deleted line |diff.txt|
})
