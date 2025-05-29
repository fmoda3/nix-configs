{ pkgs, ... }:
{
  programs.kitty = {
    enable = true;
    font = {
      package = pkgs.nerdfonts;
      name = "SauceCodePro Nerd Font Mono";
    };
    settings = {
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";
      font_size = 12;
      strip_trailing_spaces = "smart";
      enable_audio_bell = "no";
      term = "xterm-256color";
      macos_option_as_alt = "yes";
      scrollback_lines = 10000;
      window_padding_width = 4;

      # Catppuccin Colorscheme for Kitty
      foreground = "#c6d0f5";
      background = "#303446";
      selection_foreground = "#303446";
      selection_background = "#f2d5cf";
      url_color = "#f2d5cf";
      cursor = "#f2d5cf";
      cursor_text_color = "#303446";

      active_border_color = "#babbf1";
      inactive_border_color = "#737994";
      bell_border_color = "#e5c890";

      wayland_titlebar_color = "system";
      macos_titlebar_color = "system";

      active_tab_foreground = "#232634";
      active_tab_background = "#ca9ee6";
      inactive_tab_foreground = "#c6d0f5";
      inactive_tab_background = "#292c3c";
      tab_bar_background = "#232634";

      mark1_foreground = "#303446";
      mark1_background = "#babbf1";
      mark2_foreground = "#303446";
      mark2_background = "#ca9ee6";
      mark3_foreground = "#303446";
      mark3_background = "#85c1dc";

      # black
      color0 = "#51576d";
      color8 = "#626880";

      # red
      color1 = "#e78284";
      color9 = "#e78284";

      # green
      color2 = "#a6d189";
      color10 = "#a6d189";

      # yellow
      color3 = "#e5c890";
      color11 = "#e5c890";

      # blue
      color4 = "#8caaee";
      color12 = "#8caaee";

      # magenta
      color5 = "#f4b8e4";
      color13 = "#f4b8e4";

      # cyan
      color6 = "#81c8be";
      color14 = "#81c8be";

      # white
      color7 = "#b5bfe2";
      color15 = "#a5adce";
    };
  };
}
