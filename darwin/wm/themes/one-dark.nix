{ config, pkgs, ... }:
{
  imports = [ ../common.nix ];

  services.yabai.config = {
    external_bar = "all:10:0"; # let simple-bar handle bar
    active_window_border_color = "0xFF8877FF";
    normal_window_border_color = "0xFF282828";
    insert_window_border_color = "0xFFBF616A";
  };

  services.spacebar.config = {
    text_font = ''"TerminessTTF Nerd Font:Medium:12.0"'';
    icon_font = ''"TerminessTTF Nerd Font:Medium:12.0"'';
    background_color = "0x002e3440";
    foreground_color = "0xff8877ff";
    space_icon_color = "0xff56b6c2";
    power_icon_color = "0xff8877ff";
    battery_icon_color = "0xff8877ff";
    dnd_icon_color = "0xff8877ff";
    clock_icon_color = "0xff8877ff";
  };
}
