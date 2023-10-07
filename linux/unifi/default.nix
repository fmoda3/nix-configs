{ config, pkgs, lib, ... }:
with lib;
{
  config = mkIf config.my-linux.unifi.enable {
    services.unifi = {
      inherit (config.my-linux.unifi) enable;
      unifiPackage = pkgs.unifi7;
      openFirewall = true;
    };
  };
}
