{ config, pkgs, lib, ... }:
{
  boot = {
    kernelPackages = pkgs.linuxPackages;
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  # nixos-generate-config should normally set up file systems correctly
  imports = [ ./hardware-configuration.nix ];
  swapDevices = [{ device = "/swapfile"; size = 2048; }];

  environment.systemPackages = with pkgs; [ vim git ];

  services.openssh.enable = true;

  system.stateVersion = "22.05";
}
