{ config, pkgs, ... }: {
  imports = [
    ../../home
  ];

  my-home = {
    includeFonts = true;
    useNeovim = true;
  };

  wayland.windowManager.hyprland.enable = true;
}
