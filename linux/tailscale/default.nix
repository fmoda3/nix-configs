{ config, pkgs, lib, ... }:
with lib;
{
  config = mkIf config.my-linux.tailscale.enable {
    services.tailscale.enable = true;

    networking = {
      firewall = {
        allowedTCPPorts = [ 22 ];
        allowedUDPPorts = [ config.services.tailscale.port ];
        trustedInterfaces = [ "tailscale0" ];
        checkReversePath = "loose";
      };
    };

    boot.kernel.sysctl = {
      "net.ipv6.conf.all.forwarding" = true;
      "net.ipv4.ip_forward" = true;
    };
  };
}
