{ config, pkgs, ...}:
{
  # Unused for now, but leaving if it becomes necessary
  homebrew = {
    enable = true;
    cleanup = "uninstall";
    brews = [];
    casks = [];
  };
}
