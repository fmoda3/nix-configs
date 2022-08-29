{ config, pkgs, lib, ... }:
{
  services.adguardhome = {
    enable = true;
    host = "0.0.0.0";
    port = 80;
    settings = {
      dns = {
        bind_host = "0.0.0.0";
        bind_hosts = [ "0.0.0.0" ];
        bootstrap_dns = [
          "1.1.1.1"
          "1.0.0.1"
        ];
        upstream_dns = [
          "1.1.1.1"
          "1.0.0.1"
        ];
        # bootstrap_dns [ "127.0.0.1:5335" ];
        # upstream_dns = [ "127.0.0.1:5335" ];
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
}
