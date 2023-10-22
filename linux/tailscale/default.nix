{ config, pkgs, lib, ... }:
with lib;
let
  advertiseExitNode = optionals config.my-linux.tailscale.advertiseExitNode [ "--advertise-exit-node" ];
in
{
  config = mkIf config.my-linux.tailscale.enable {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "both";
      authKeyFile = config.my-linux.tailscale.authkey;
      extraUpFlags = advertiseExitNode;
    };
  };
}
