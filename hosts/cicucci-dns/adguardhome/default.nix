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
          "9.9.9.10"
          "149.112.112.10"
          "2620:fe::10"
          "2620:fe::fe:10"
        ];
        upstream_dns = [ "127.0.0.1:5335" ];
        enable_dnssec = true;
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