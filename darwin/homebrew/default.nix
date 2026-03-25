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
        "toasttab/toast/lunchbox"
        "toasttab/toast/braid"
        "snyk/tap/snyk"
        "toasttab/toast/flaggy"
      ] ++
      lib.optionals config.my-darwin.isServer [
        "handbrake"
      ];
    casks = lib.optionals config.my-darwin.isWork [
      "toasttab/toast/tether"
    ] ++
    lib.optionals config.my-darwin.isServer [
      "filebot"
    ];
  };
}
