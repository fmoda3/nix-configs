{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.homebridge;

  nodeOptions = "--dns-result-order=ipv4first";
in
{
  options.services.homebridge = with types; {
    enable = mkEnableOption "Scrypted: Home Automation";

    configPath = mkOption {
      type = str;
      default = "/var/lib/scrypted";
      description = lib.mdDoc ''
        Path to store scrypted config diles (needs to be writeable).
      '';
    };

    openFirewall = mkOption {
      type = bool;
      default = false;
      description = lib.mdDoc ''
        Open ports in the firewall for the Scrypted web interface.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.scrypted = {
      description = "Scrypted";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      preStart = ''
        mkdir -p ${cfg.configPath}/.scrypted
        chown -R scrypted ${cfg.configPath}/.scrypted
      '';

      serviceConfig = {
        Type = "simple";
        User = "scrypted";
        Group = "scrypted";
        WorkingDirectory = cfg.configPath;
        ExecStart = "${pkgs.scrypted}/bin/scrypted-serve ${args}";
        Restart = "on-failure";
        RestartSec = 3;
        KillMode = "process";
        Environment = "NODE_OPTIONS=${nodeOptions}";
        Environment = "SCRYPTED_INSTALL_ENVIRONMENT=local";
        StandardOutput = null;
        StandardError = null;
      };
    };

    # Create a user whose home folder is the user storage path
    users.users.scrypted = {
      home = cfg.configPath;
      createHome = true;
      group = "scrypted";
      isSystemUser = true;
    };

    users.groups.scrypted = { };

    networking.firewall = {
      allowedTCPPorts = mkIf cfg.openFirewall [ 10443 ];
    };
  };

}
