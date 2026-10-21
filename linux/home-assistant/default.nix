{ config, lib, ... }:
{
  config = lib.mkIf config.my-linux.home-assistant.enable {
    services.home-assistant = {
      enable = true;
      openFirewallForComponents = true;
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

    networking.firewall = {
      allowedTCPPorts = [ 8123 21063 21064 21065 ];
    };
  };
}
