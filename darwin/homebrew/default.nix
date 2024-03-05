{ config, pkgs, ... }:
{
  homebrew = {
    enable = config.my-darwin.isWork;
    onActivation = {
      cleanup = "uninstall";
    };
    taps = [
      {
        name = "toasttab/toast";
        clone_target = "git@github.com:toasttab/homebrew-toast";
      }
      {
        name = "snyk/tap";
      }
    ];
    brews = [
      "libffi"
      "cocoapods"
      "lunchbox"
      "toasttab/toast/braid"
      "snyk"
      "flaggy"
    ];
  };
}
