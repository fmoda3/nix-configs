{ config, pkgs, ... }:
{
  imports = [ ../common.nix ];

  programs.kitty = {
    settings = {
      # One Dark Colorscheme for Kitty
      foreground           = "#EEEEEE";
      background           = "#292C33";
      # selection_foreground = "#000000";
      # selection_background = "#FFFACD";
      # url_color            = "#0087BD";
      # cursor               = "#81A1C1";
      
      # black
      color0   = "#282828";
      color8   = "#1D1D1D";
      
      # red
      color1   = "#F43753";
      color9   = "#F43753";
      
      # green
      color2   = "#C9D05C";
      color10  = "#C9D05C";
      
      # yellow
      color3   = "#FFC24B";
      color11  = "#FFC24B";
      
      # blue
      color4  = "#B3DEEF";
      color12 = "#B3DEEF";
      
      # magenta
      color5   = "#D3B987";
      color13  = "#D3B987";
      
      # cyan
      color6   = "#73CEf4";
      color14  = "#73CEf4";
      
      # white
      color7   = "#EEEEEE";
      color15  = "#FFFFFF";
    };
  };
}
