{ config, pkgs, lib, ... }:
{
  imports = ["${fetchTarball "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz" }/raspberry-pi/4"];

  # nixos-generate-config should normally set up file systems correctly
  imports = [ ./hardware-configuration.nix ];
  swapDevices = [ { device = "/swapfile"; size = 2048; } ];

  environment.systemPackages = with pkgs; [ vim ];

  services.openssh.enable = true;

  system.stateVersion = "22.05";
}