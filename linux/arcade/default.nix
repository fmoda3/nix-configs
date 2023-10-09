{ config, pkgs, lib, ... }:
with lib;
{
  config = mkIf config.my-linux.arcade.enable {
    sound.enable = true;

    services.xserver = {
      enable = true;
      displayManager = {
        lightdm.enable = true;
        autoLogin = {
          enable = true;
          user = "fmoda3";
        };
      };
      desktopManager = {
        retroarch = {
          enable = true;
          package = pkgs.retroarchFull;
        };
      };
    };
  };
}
