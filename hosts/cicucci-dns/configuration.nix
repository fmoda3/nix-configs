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

  hardware.enableRedistributableFirmware = true;
  networking = {
    hostName = "cicucci-dns";
    networkmanager = {
      enable = true;
    };
  };

  time.timeZone = "America/New_York";

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
