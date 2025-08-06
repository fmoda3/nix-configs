{ config, pkgs, lib, ... }:
{
  programs.nh = {
    enable = true;
  } // lib.optionalAttrs pkgs.stdenv.isDarwin {
    darwinFlake = config.my-home.flake;
  } // lib.optionalAttrs pkgs.stdenv.isLinux {
    osFlake = config.my-home.flake;
  };
}
