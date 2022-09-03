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
    ../../linux
  ];

  hardware.enableRedistributableFirmware = true;
  networking = {
    hostName = "cicucci-dns";
    networkmanager = {
      enable = true;
    };
  };

  my-linux = {
    enableNixOptimise = true;
    tailscale = {
      enable = true;
      authkey = "tskey-kveqY12CNTRL-wQHntvWh7JgruYi1iwVgy";
      advertiseExitNode = true;
    };
    adblocker = {
      enable = true;
      useUnbound = true;
    };
  };

}
