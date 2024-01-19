{ config, pkgs, lib, ... }:
{
  boot = {
    kernelPackages = pkgs.linuxPackages;
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  imports = [
    ./hardware-configuration.nix
    ../../linux
  ];

  networking = {
    hostName = "cicucci-homelab";
    networkmanager = {
      enable = true;
    };
  };

  time.timeZone = "America/New_York";

  # age.secrets.dns_tailscale_key.file = ../../secrets/dns_tailscale_key.age;

  services.homebridge.enable = true;

  my-linux = {
    enableNixOptimise = true;
    # tailscale = {
    #   enable = true;
    #   authkey = config.age.secrets.dns_tailscale_key.path;
    #   advertiseExitNode = true;
    # };
  };

}
