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
    ../../linux/openssh
    ../../linux/adguardhome
    ../../linux/unbound
    ../../linux/tailscale
    ../../linux/tailscale-autoconnect
  ];

  hardware.enableRedistributableFirmware = true;
  networking = {
    hostName = "cicucci-dns";
    networkmanager = {
      enable = true;
    };
  };

  services.tailscale-autoconnect = {
    enable = true;
    authkey = "tskey-kveqY12CNTRL-wQHntvWh7JgruYi1iwVgy";
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

  programs.zsh = {
    enable = true;
    enableCompletion = false;
    promptInit = "";
  };

  users.defaultUserShell = pkgs.zsh;

  system.stateVersion = "22.05";
}
