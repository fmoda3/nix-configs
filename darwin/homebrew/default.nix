{ config, pkgs, ...}:

{
  homebrew = {
    enable = true;
    autoUpdate = true;
    cleanup = "uninstall";
    casks = [
      "kitty"
    ];
  };
}
