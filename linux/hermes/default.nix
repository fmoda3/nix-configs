{ config, inputs, lib, ... }:
{
  imports = [ inputs.hermes-agent.nixosModules.default ];

  config = lib.mkIf config.my-linux.hermes.enable {
    age.secrets.hermes_env.file = ../../secrets/hermes_env.age;

    # Rely on the USG and tailnet policy for network-level access restrictions.
    networking.firewall.allowedTCPPorts = [ 9119 ];

    services.hermes-agent = {
      enable = true;
      addToSystemPackages = true;

      environmentFiles = [
        config.age.secrets.hermes_env.path
      ];

      settings = {
        dashboard.theme = "mono";
        model = {
          provider = "openai-codex";
          default = "gpt-6.1-sol";
          persist_switch_by_default = false;
        };
        # Other built-in providers become available once authenticated. Never
        # silently spend on a different provider when the selected one fails.
        fallback_providers = [ ];
        fallback_model = null;
        terminal.backend = "local";
      };

      # Non-loopback binding requires dashboard login credentials in hermes_env.
      # IPv4 only; port 9119 is allowed on all host interfaces.
      backend = {
        mode = "dashboard";
        host = "0.0.0.0";
        port = 9119;
      };
    };
  };
}
