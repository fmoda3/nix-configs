{ config, inputs, lib, pkgs, ... }:
{
  imports = [ inputs.hermes-agent.nixosModules.default ];

  config = lib.mkIf config.my-linux.hermes.enable {
    age.secrets.hermes_env.file = ../../secrets/hermes_env.age;

    # Hermes manages downloaded tools; provide their conventional ELF loader.
    # This is host-wide compatibility, enabled only on Hermes hosts.
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        glib
        nspr
        nss
        at-spi2-core
        dbus
        cups
        expat
        libxcb
        libxkbcommon
        libX11
        libXcomposite
        libXdamage
        libXext
        libXfixes
        libXrandr
        libgbm
        cairo
        pango
        alsa-lib
      ];
    };

    # System services do not inherit login-shell session variables.
    systemd.services = lib.genAttrs [ "hermes-agent" "hermes-backend" ] (_: {
      environment = {
        inherit (config.environment.sessionVariables) NIX_LD NIX_LD_LIBRARY_PATH;
      };
    });

    # Rely on the USG and tailnet policy for network-level access restrictions.
    networking.firewall.allowedTCPPorts = [ 9119 ];

    services.hermes-agent = {
      enable = true;
      addToSystemPackages = true;

      extraPlugins = [
        (pkgs.fetchFromGitHub {
          name = "hermes-conduit-notifier";
          owner = "kaishi00";
          repo = "hermes-conduit-notifier";
          # Plugin 0.34.1; pin independently of the Hermes release.
          rev = "9cf64e1bbccbc57914c5ced8b8b1756df0a6e1a1";
          hash = "sha256-Isr1M9ma6gHShr0DLuecUHwDuImPnTe9BRYzYJR4RTI=";
        })
      ];

      environmentFiles = [
        config.age.secrets.hermes_env.path
      ];

      settings = {
        dashboard.theme = "mono";
        plugins.enabled = [ "conduit_push" "disk-cleanup" ];
        # Vendor-hosted MCP servers; anonymous access, no local executables.
        mcp_servers = {
          exa.url = "https://mcp.exa.ai/mcp";
          deepwiki.url = "https://mcp.deepwiki.com/mcp";
          context7.url = "https://mcp.context7.com/mcp";
        };
        model = {
          provider = "openai-codex";
          default = "gpt-6.1-sol";
          persist_switch_by_default = false;
        };
        # Other built-in providers become available once authenticated. Never
        # silently spend on a different provider when the selected one fails.
        fallback_providers = [ ];
        fallback_model = [ ];
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
