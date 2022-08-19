{ config, pkgs, ... }: {
  imports = [
    ../../home/headless.nix
    ../../home/personal.nix
  ];
}
