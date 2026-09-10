{ config, pkgs, lib, ... }:
{
  programs.nh = {
    enable = true;
  } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
    darwinFlake = config.my-home.flake;
  } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    osFlake = config.my-home.flake;
  };
}
