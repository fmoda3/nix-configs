{ config, lib, ... }:
{
  config = lib.mkIf config.my-linux.homebridge.enable {
    services.homebridge = {
      enable = true;
      openFirewall = true;
    };
  };
}
