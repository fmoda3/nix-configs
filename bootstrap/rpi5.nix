{ pkgs, ... }:
{
  # nixos-generate-config should normally set up file systems correctly
  imports = [
    "${fetchTarball "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz" }/raspberry-pi/5"
    ./hardware-configuration.nix
  ];

  swapDevices = [{ device = "/swapfile"; size = 2048; }];

  environment.systemPackages = with pkgs; [ vim git ];

  services.openssh.enable = true;

  system.stateVersion = "24.11";
}
