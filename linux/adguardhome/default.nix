{ config, pkgs, lib, ... }:
with lib;
{
  config = mkIf config.my-linux.adblocker.enable {
    services.adguardhome = {
      enable = config.my-linux.adblocker.enable;
      settings = {
	bind_host = "0.0.0.0";
	bind_port = 80;
        dns = {
          bind_host = "0.0.0.0";
          bind_hosts = [ "0.0.0.0" ];
          bootstrap_dns =
            if config.my-linux.adblocker.useUnbound then [
              "127.0.0.1:5335"
            ] else [
              "1.1.1.1"
              "1.0.0.1"
            ];
          upstream_dns =
            if config.my-linux.adblocker.useUnbound then [
              "127.0.0.1:5335"
            ] else [
              "1.1.1.1"
              "1.0.0.1"
            ];
          enable_dnssec = true;
          ratelimit = 0;
        };
      };
    };

    networking = {
      firewall = {
        allowedTCPPorts = [ 53 80 ];
        allowedUDPPorts = [ 53 ];
      };
    };
  };
}
