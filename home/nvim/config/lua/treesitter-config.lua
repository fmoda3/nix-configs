local nord = require("nord-colors")
local util = require("util")
util.colorize({
    TSAnnotation =        { fg = nord.nord12_gui },    -- For C++/Dart attributes, annotations thatcan be attached to the code to denote some kind of meta information.
    TSCharacter=          { fg = nord.nord14_gui },    -- For characters.
    TSConstructor =       { fg = nord.nord9_gui }, -- For constructor calls and definitions: `=                                                                          { }` in Lua, and Java constructors.
    TSConstant =          { fg = nord.nord13_gui },    -- For constants
    TSFloat =             { fg = nord.nord15_gui },    -- For floats
    TSNumber =            { fg = nord.nord15_gui },    -- For all number
    TSString =            { fg = nord.nord14_gui },    -- For strings.
    
    TSAttribute =         { fg = nord.nord15_gui },    -- (unstable) TODO: docs
    TSBoolean=            { fg = nord.nord9_gui },    -- For booleans.
    TSConstBuiltin =      { fg = nord.nord7_gui },    -- For constant that are built in the language: `nil` in Lua.
    TSConstMacro =        { fg = nord.nord7_gui },    -- For constants that are defined by macros: `NULL` in C.
    TSError =             { fg = nord.nord11_gui },    -- For syntax/parser errors.
    TSException =         { fg = nord.nord15_gui },    -- For exception related keywords.
    TSField =             { fg = nord.nord4_gui }, -- For fields.
    TSFunction =          { fg = nord.nord8_gui },    -- For fuction (calls and definitions).
    TSComment =           { fg = nord.nord3_gui_bright },
    TSConditional =       { fg = nord.nord9_gui },   -- For keywords related to conditionnals.
    TSFuncBuiltin =       { fg = nord.nord8_gui },
    TSFuncMacro =         { fg = nord.nord7_gui },    -- For macro defined fuctions (calls and definitions): each `macro_rules` in Rust.
    TSInclude =           { fg = nord.nord9_gui },    -- For includes: `#include` in C, `use` or `extern crate` in Rust, or `require` in Lua.
    TSKeyword =           { fg = nord.nord9_gui }, -- For keywords that don't fall in previous categories.
    TSKeywordFunction =   { fg = nord.nord8_gui },
    TSLabel =             { fg = nord.nord15_gui }, -- For labels: `label:` in C and `:label:` in Lua.
    TSMethod =            { fg = nord.nord7_gui },    -- For method calls and definitions.
    TSNamespace =         { fg = nord.nord4_gui},    -- For identifiers referring to modules and namespaces.
    TSOperator =          { fg = nord.nord9_gui }, -- For any operator: `+`, but also `->` and `*` in C.
    TSParameter =         { fg = nord.nord10_gui }, -- For parameters of a function.
    TSParameterReference= { fg = nord.nord10_gui },    -- For references to parameters of a function.
    TSProperty =          { fg = nord.nord10_gui }, -- Same as `TSField`.
    TSPunctDelimiter =    { fg = nord.nord8_gui }, -- For delimiters ie: `.`
    TSPunctBracket =      { fg = nord.nord8_gui }, -- For brackets and parens.
    TSPunctSpecial =      { fg = nord.nord8_gui }, -- For special punctutation that does not fall in the catagories before.
    TSRepeat =            { fg = nord.nord9_gui },    -- For keywords related to loops.
    TSStringRegex =       { fg = nord.nord7_gui }, -- For regexes.
    TSStringEscape =      { fg = nord.nord15_gui }, -- For escape characters within a string.
    TSSymbol =            { fg = nord.nord15_gui },    -- For identifiers referring to symbols or atoms.
    TSType =              { fg = nord.nord9_gui},    -- For types.
    TSTypeBuiltin =       { fg = nord.nord9_gui},    -- For builtin types.
    TSTag =               { fg = nord.nord4_gui },    -- Tags like html tag names.
    TSTagDelimiter =      { fg = nord.nord15_gui },    -- Tag delimiter like `<` `>` `/`
    TSText =              { fg = nord.nord4_gui },    -- For strings considenord11_gui text in a markup language.
    TSTextReference =     { fg = nord.nord15_gui }, -- FIXME
    TSVariable =          { fg = nord.nord4_gui }, -- Any variable name that does not have another highlight.
    TSVariableBuiltin =   { fg = nord.nord4_gui },
    TSEmphasis =          { fg = nord.nord10_gui },    -- For text to be represented with emphasis.
    TSUnderline =         { fg = nord.nord4_gui, bg = nord.none, style = 'underline' },    -- For text to be represented with an underline.
    TSTitle =             { fg = nord.nord10_gui, bg = nord.none, style = 'bold' },    -- Text that is part of a title.
    TSLiteral =           { fg = nord.nord4_gui },    -- Literal text.
    TSURI =               { fg = nord.nord14_gui },    -- Any URI like a link or email.        TSAnnotation =                                                                  { fg = nord.nord11_gui },    -- For C++/Dart attributes, annotations that can be attached to the code to denote some kind of meta information.
})

-- Treesitter
require'nvim-treesitter.configs'.setup {
    highlight = {
	    enable = true
    }
}