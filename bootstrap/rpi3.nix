{ config, pkgs, lib, ... }:
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
      generic-extlinux-compatible.enable = true;
    };
  };

  # nixos-generate-config should normally set up file systems correctly
  imports = [ ./hardware-configuration.nix ];
  swapDevices = [ { device = "/swapfile"; size = 2048; } ];

  environment.systemPackages = with pkgs; [ vim ];

  services.openssh.enable = true;
  
  system.stateVersion = "22.05";
}