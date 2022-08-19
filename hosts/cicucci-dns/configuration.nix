{ config, pkgs, lib, ...}:
{
  boot = {
    kernelPackages = pkgs.linuxPackages;
    loader = {
      raspberryPi = {
        enable = true;
        version = 3;
        uboot.enable = true;
      };
      grub.enable = false;
    };
  };

  imports = [
    ./hardware-configuration.nix
    ./openssh
    ./adguardhome
    ./unbound
    ./tailscale
  ];

  hardware.enableRedistributableFirmware = true;
  networking = {
    hostName = "cicucci-dns";
    networkmanager = {
      enable = true;
    };
  };

  nix = {
    package = pkgs.nixFlakes;
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    extraOptions = ''
      experimental-features = nix-command flakes
      min-free = ${toString (100 * 1024 * 1024)}
      max-free = ${toString (1024 * 1024 * 1024)}
    '';
  };

  system.stateVersion = "22.05";
}
