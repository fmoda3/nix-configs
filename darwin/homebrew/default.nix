{ config, pkgs, ... }:
{
  homebrew = {
    enable = config.my-darwin.isWork;
    cleanup = "uninstall";
    brews = [
      "libffi"
      "cocoapods"
    ];
    extraConfig = ''
      tap "toasttab/toast", "git@github.com:toasttab/homebrew-toast"
      brew "lunchbox"
    '';
  };
}
