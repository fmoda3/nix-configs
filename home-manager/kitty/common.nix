{ config, pkgs, ... }:
{
  programs.kitty = {
    enable = true;
    font = {
      package = pkgs.nerdfonts;
      name = "Inconsolata Nerd Font";
    };
    settings = {
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";
      font_size = 2;
      strip_trailing_spaces = "smart";
      enable_audio_bell = "no";
      term = "xterm-256color";
      macos_titlebar_color = "background";
      macos_option_as_alt = "yes";
      scrollback_lines = 10000;
    };
  };
}
