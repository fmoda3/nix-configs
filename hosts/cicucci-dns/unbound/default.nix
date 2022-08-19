{ config, pkgs, lib, ... }:
{
	services.unbound = {
    enable = true;
    settings = {
      server = {
        verbosity = 0;
        interface = [ "127.0.0.1" ];
        port = 5335;
        do-ip4 = "yes";
        do-udp = "yes";
        do-tcp = "yes";
        do-ip6 = "no";
        prefer-ip6 = "no";
        harden-glue = "yes";
        harden-dnssec-stripped = "yes";
        use-caps-for-id = "no";
        edns-buffer-size = 1232;
        prefetch = "yes";
        num-threads = 4;
        so-rcvbuf = "1m";
        private-address = [
          "192.168.0.0/16"
          "169.254.0.0/16"
          "172.16.0.0/12"
          "10.0.0.0/8"
          "fd00::/8"
          "fe80::/10"
        ];
      };
    };
  };
}