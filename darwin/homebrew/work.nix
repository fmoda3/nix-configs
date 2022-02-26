{ config, pkgs, ...}:
{
  homebrew = {
    enable = true;
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
