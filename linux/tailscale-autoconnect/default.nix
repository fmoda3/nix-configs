{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.tailscale-autoconnect;
in {
  options.services.tailscale-autoconnect = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        If enabled, will attempt to authenticate to tailscale
      ''
    };

    authkey = mkOption {
      type = types.str;
      default = null;
      example = "tskey-kveqY12CNTRL-wQHntvWh7JgruYi1iwVgy";
      description = ''
        A one-time use tailscale key
      '';
    };

    advertise-exit-node = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Should tailscale advertise as an exit node
      ''
    };
  };

  config = mkIf cfg.enable {
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
        if [ $status != "Running" ]; then # if not, authenticate
          ${tailscale}/bin/tailscale up -authkey ${cfg.authkey}
          sleep 2
        fi

        ${optionalString cfg.advertise-exit-node ''
          ${tailscale}/bin/tailscale up --advertise-exit-node
        ''}

        exit 0
      '';
    };
  };
}
