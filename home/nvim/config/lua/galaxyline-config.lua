 -- This file configures galaxyline, a fast and small statusline for nvim.
 -- The configuration was taken from github.com/siduck76/neovim-dotfiles/ 
 -- All I did was change the colors. Full credit goes to siduck76

local gl = require("galaxyline")
local gls = gl.section

gl.short_line_list = {" "} -- keeping this table { } as empty will show inactive statuslines

vim.api.nvim_command('hi GalaxyLineFillSection guibg=NONE')

local colors = {
    -- Dark
    nord0 = "#2E3440", -- Black
    nord1 = "#3B4252", -- Dark Grey
    nord2 = "#434C5E", -- Grey
    nord3 = "#4C566A", -- Light Grey
    -- Light
    nord4 = "#D8DEE9", -- Darkest White
    nord5 = "#E5E9F0", -- Darker White
    nord6 = "#ECEFF4", -- White
    -- Frost
    nord7 = "#8FBCBB", -- Blue/Green
    nord8 = "#88C0D0", -- Cyan
    nord9 = "#81A1C1", -- Light Blue
    nord10 = "#5E81AC", -- Blue
    -- Aurora
    nord11 = "#BF616A", -- Red
    nord12 = "#D08770", -- Orange
    nord13 = "#EBCB8B", -- Yellow
    nord14 = "#A3BE8C", -- Green
    nord15 = "#B48EAD", -- Purple
}

gls.left[1] = {
    leftRounded = {
        provider = function()
            return ""
        end,
        highlight = {colors.nord5, colors.nord0}
    }
}

gls.left[2] = {
    statusIcon = {
        provider = function()
            return "  "
        end,
        highlight = {colors.nord3, colors.nord5},
        separator = " ",
        separator_highlight = {colors.nord2, colors.nord3}
    }
}

gls.left[3] = {
    FileIcon = {
        provider = "FileIcon",
        condition = buffer_not_empty,
        highlight = {require("galaxyline.provider_fileinfo").get_file_icon_color, colors.nord3}
    }
}

gls.left[4] = {
    FileName = {
        provider = {"FileName", "FileSize"},
        condition = buffer_not_empty,
        highlight = {colors.nord6, colors.nord3}
    }
}

gls.left[5] = {
    teech = {
        provider = function()
            return ""
        end,
        separator = " ",
        highlight = {colors.nord3, colors.nord0}
    }
}

gls.mid[1] = {
    mid_leftRounded = {
        provider = function()
            return ""
        end,
        highlight = {colors.nord3, colors.nord0}
    }
}

gls.mid[2] = {
    lspIcon = {
        provider = function()
            return ""
        end,
        highlight = {colors.nord15, colors.nord3}
    }
}

gls.mid[3] = {
    GetLspClient = {
        provider = "GetLspClient",
        separator = {" ", " "},
        separator_highlight = {colors.nord3, colors.nord3},
        highlight = {colors.nord15, colors.nord3}
    }
}

gls.mid[4] = {
    DiagnosticError = {
        provider = "DiagnosticError",
        icon = " ",
        highlight = {colors.nord11, colors.nord3}
    }
}

gls.mid[5] = {
    DiagnosticWarn = {
        provider = "DiagnosticWarn",
        icon = " ",
        highlight = {colors.nord12, colors.nord3}
    }
}

gls.mid[7] = {
    DiagnosticInfo = {
        provider = "DiagnosticInfo",
        icon = "\u{f05a} ",
        highlight = {colors.nord11, colors.nord3}
    }
}

gls.mid[8] = {
    DiagnosticHint = {
        provider = "DiagnosticHint",
        icon = " ",
        highlight = {colors.nord10, colors.nord3}
    }
}

gls.mid[9] = {
    mid_rightRounded = {
        provider = function()
            return ""
        end,
        highlight = {colors.nord3, colors.nord0}
    }
}

gls.right[1] = {
    GitIcon = {
        provider = function()
            return ""
        end,
        condition = require("galaxyline.provider_vcs").check_git_workspace,
        highlight = {colors.nord10, colors.nord0}
    }
}

gls.right[2] = {
    GitBranch = {
        provider = "GitBranch",
        condition = require("galaxyline.provider_vcs").check_git_workspace,
        separator = " ",
        separator_highlight = {colors.nord0, colors.nord0},
        highlight = {colors.nord10, colors.nord0}
    }
}

gls.right[3] = {
    GitSpace = {
        provider = function()
            return " "
        end,
        condition = require("galaxyline.provider_vcs").check_git_workspace,
        highlight = {colors.nord0, colors.nord0}
    }
}

gls.right[4] = {
    DiffAdd = {
        provider = "DiffAdd",
        condition = hide_in_width,
        icon = " ",
        highlight = {colors.nord14, colors.nord0}
    }
}

gls.right[5] = {
    DiffModified = {
        provider = "DiffModified",
        condition = hide_in_width,
        icon = " ",
        highlight = {colors.nord12, colors.nord0}
    }
}

gls.right[6] = {
    DiffRemove = {
        provider = "DiffRemove",
        condition = hide_in_width,
        icon = " ",
        highlight = {colors.nord13, colors.nord0}
    }
}

gls.right[7] = {
    right_LeftRounded = {
        provider = function()
            return "" 
        end,
        separator = " ",
        separator_highlight = {colors.nord0, colors.nord0},
        highlight = {colors.nord8, colors.nord0}
    }
}

gls.right[8] = {
    ViMode = {
        provider = function()
            local alias = {
                n = "NORMAL",
                i = "INSERT",
                c = "COMMAND",
                V = "VISUAL",
                [""] = "VISUAL",
                v = "VISUAL",
                R = "REPLACE"
            }
            return alias[vim.fn.mode()]
        end,
        highlight = {colors.nord3, colors.nord8}
    }
}

gls.right[9] = {
    PerCent = {
        provider = "LinePercent",
        separator = " ",
        separator_highlight = {colors.nord3, colors.nord8},
        highlight = {colors.nord3, colors.nord5}
    }
}

gls.right[10] = {
    rightRounded = {
        provider = function()
            return ""
        end,
        highlight = {colors.nord5, colors.nord0}
    }
}
