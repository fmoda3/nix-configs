{ config, pkgs, lib, ... }:
{
  # Bootloader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
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

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # age.secrets.dns_tailscale_key.file = ../../secrets/dns_tailscale_key.age;

  services.homebridge = {
    enable = true;
    openFirewall = true;
    allowInsecure = true;
  };

  my-linux = {
    enableNixOptimise = true;
    # tailscale = {
    #   enable = true;
    #   authkey = config.age.secrets.dns_tailscale_key.path;
    #   advertiseExitNode = true;
    # };
  };

}
