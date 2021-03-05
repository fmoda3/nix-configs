{ config, pkgs, ... }:
{
  programs.direnv = {
    enable = true;
    enableNixDirenvIntegration = true;
  };
}
