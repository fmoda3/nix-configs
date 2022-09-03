{ config, pkgs, lib, ...}:
{
  boot = {
    kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_5_15.override {
      argsOverride = rec {
        src = pkgs.fetchurl {
          url = "mirror://kernel/linux/kernel/v5.x/linux-${version}.tar.xz";
          sha256 = "08w2kgc0v0ld7nxbary7d9fr2vxrsmqby7l4fhf7njgi6wsbp9p9";
        };
        version = "5.15.56";
        modDirVersion = "5.15.56";
      };
    });
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
