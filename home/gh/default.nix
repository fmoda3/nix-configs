{ config, pkgs, ... }:
{
  programs.gh = {
    enable = config.my-home.isWork;
    settings = {
      git_protocol = "ssh";
    };
    extensions = [
      pkgs.gh-copilot
    ];
  };
}
