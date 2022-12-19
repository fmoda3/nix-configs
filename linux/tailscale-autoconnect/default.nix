{ config, pkgs, lib, ... }:
with lib;
let 
  advertiseExitNode = optionalString config.my-linux.tailscale.advertiseExitNode "--advertise-exit-node";
in
{
  config = mkIf config.my-linux.tailscale.enable {
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
          ${tailscale}/bin/tailscale up -authkey ${config.my-linux.tailscale.authkey} ${advertiseExitNode}
          sleep 2
        fi

        exit 0
      '';
    };
  };
}
