{ config, pkgs, lib, ...}:
{
  boot = {
    kernelPackages = pkgs.linuxPackages;
    loader = {
      raspberryPi = {
        enable = true;
        version = 3;
        uboot.enable = true;
      };
      grub.enable = false;
    };
    kernel.sysctl = {
      "net.ipv6.conf.all.forwarding" = true;
      "net.ipv4.ip_forward" = true;
    };
  };

  imports = [ ./hardware-configuration.nix ];

  hardware.enableRedistributableFirmware = true;
  networking = {
    hostName = "cicucci-dns";
    networkmanager = {
      enable = true;
    };
    firewall = {
      allowedTCPPorts = [ 22 53 80 ];
      allowedUDPPorts = [ 53 config.services.tailscale.port ];
      trustedInterfaces = [ "tailscale0" ];
      checkReversePath = "loose";
    };
  };

  nix = {
    package = pkgs.nixFlakes;
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    extraOptions = ''
      experimental-features = nix-command flakes
      min-free = ${toString (100 * 1024 * 1024)}
      max-free = ${toString (1024 * 1024 * 1024)}
    '';
  };

  services.openssh.enable = true;

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
      };
    };
  };

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
        num-threads = 1;
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

  services.tailscale.enable = true;
  # create a oneshot job to authenticate to Tailscale
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    # make sure tailscale is running before trying to connect to tailscale
    after = [ "network-pre.target" "tailscale.service" ];
    wants = [ "network-pre.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];

    # set this service as a oneshot job
    serviceConfig.Type = "oneshot";

    # have the job run this shell script
    script = with pkgs; ''
      # wait for tailscaled to settle
      sleep 2

      # check if we are already authenticated to tailscale
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi

      # otherwise authenticate with tailscale
      ${tailscale}/bin/tailscale up -authkey tskey-kveqY12CNTRL-wQHntvWh7JgruYi1iwVgy
    '';
  };
  
  swapDevices = [ { device = "/swapfile"; size = 2048; } ];

  system.stateVersion = "22.05";
}
