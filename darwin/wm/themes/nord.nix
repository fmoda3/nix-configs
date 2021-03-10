{config, pkgs, ...}:
{
  imports = [ ../common.nix ];

  services.yabai.config = {
      external_bar               = "all:26:0";  # let simple-bar handle bar
      active_window_border_color = "0xFF5E81AC";
      normal_window_border_color = "0xFF4C566A";
      insert_window_border_color = "0xFFBF616A";
  };

  services.spacebar.config = {
    text_font          = ''"TerminessTTF Nerd Font:Medium:12.0"'';
    icon_font          = ''"TerminessTTF Nerd Font:Medium:12.0"'';
    background_color   = "0xff2e3440";
    foreground_color   = "0xff5e81ac";
    space_icon_color   = "0xffbf616a";
    power_icon_color   = "0xffd08770";
    battery_icon_color = "0xffebcb8b";
    dnd_icon_color     = "0xffa3be8c";
    clock_icon_color   = "0xffb48ead";
  };
}
