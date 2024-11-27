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

  age.secrets.homelab_tailscale_key.file = ../../secrets/homelab_tailscale_key.age;

  services = {
    homebridge = {
      enable = true;
      openFirewall = true;
      allowInsecure = true;
    };

    home-assistant = {
      enable = true;
      openFirewall = true;
      extraComponents = [
        # List of components required to complete the onboarding
        "default_config"
        "met"
        "esphome"
        "radio_browser"
        "google_translate"
        "isal"
        # Found on network
        "apple_tv"
        "brother"
        "cast"
        "ecobee"
        "homekit"
        "homekit_controller"
        "ipp"
        "lutron_caseta"
        "plex"
        "spotify"
        "tplink"
        # More integrations
        "schlage"
      ];
      config = {
        # Includes dependencies for a basic setup
        # https://www.home-assistant.io/integrations/default_config/
        default_config = { };
        "automation ui" = "!include automations.yaml";
      };
    };

    scrypted = {
      enable = true;
      openFirewall = true;
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 21063 21064 21065 ];
  };

  my-linux = {
    enableNixOptimise = true;
    tailscale = {
      enable = true;
      authkey = config.age.secrets.homelab_tailscale_key.path;
      advertiseExitNode = true;
    };
  };

}
