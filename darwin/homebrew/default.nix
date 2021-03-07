{ config, pkgs, ...}:
{
  # Unused for now, but leaving if it becomes necessary
  homebrew = {
    enable = true;
    autoUpdate = true;
    cleanup = "uninstall";
    casks = [
    ];
  };
}
