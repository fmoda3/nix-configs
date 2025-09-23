{ config, lib, ... }:
{
  homebrew = {
    enable = config.my-darwin.isWork || config.my-darwin.isServer;
    onActivation = {
      cleanup = "uninstall";
    };
    taps = lib.optionals config.my-darwin.isWork [
      {
        name = "toasttab/toast";
        clone_target = "git@github.toasttab.com:toasttab/homebrew-toast";
      }
      {
        name = "snyk/tap";
      }
    ];
    brews =
      lib.optionals config.my-darwin.isWork [
        "libffi"
        "cocoapods"
        "lunchbox"
        "toasttab/toast/braid"
        "snyk"
        "flaggy"
      ] ++
      lib.optionals config.my-darwin.isServer [
        "handbrake"
      ];
    casks = lib.optionals config.my-darwin.isServer [
      "filebot"
    ];
  };
}
