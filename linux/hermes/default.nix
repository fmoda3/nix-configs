{ config, inputs, lib, pkgs, ... }:
{
  imports = [ inputs.hermes-agent.nixosModules.default ];

  config = lib.mkIf config.my-linux.hermes.enable {
    age.secrets.hermes_env.file = ../../secrets/hermes_env.age;
    age.secrets.searx_env.file = ../../secrets/searx_env.age;

    services.searx = {
      enable = true;
      package = pkgs.searxng;
      openFirewall = false;
      environmentFile = config.age.secrets.searx_env.path;
      settings = {
        general.debug = false;
        server = {
          bind_address = "127.0.0.1";
          port = 8888;
          # Only local clients; no Redis/bot-protection service needed.
          limiter = false;
        };
        search.formats = [ "html" "json" ];
      };
    };

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
      wants = [ "searx.service" ];
      after = [ "searx.service" ];
      environment = {
        inherit (config.environment.sessionVariables) NIX_LD NIX_LD_LIBRARY_PATH;
      };
    });

    # Rely on the USG and tailnet policy for network-level access restrictions.
    networking.firewall.allowedTCPPorts = [ 9119 ];

    services.hermes-agent = {
      enable = true;
      addToSystemPackages = true;
      environment.SEARXNG_URL = "http://127.0.0.1:8888";

      extraPlugins = [
        (pkgs.fetchFromGitHub {
          name = "hermes-conduit-notifier";
          owner = "kaishi00";
          repo = "hermes-conduit-notifier";
          # Plugin 0.121.0; pin independently of the Hermes release.
          rev = "f6bc1dda0cf7f997f72db23ab5d57206789f3a40";
          hash = "sha256-oRZEnsepb/2JcmB2jRGbE/gZkgctrm4bymDU2m1MCUA=";
        })
      ];

      environmentFiles = [
        config.age.secrets.hermes_env.path
      ];

      settings = {
        dashboard.theme = "mono";
        # Local search with Exa page extraction; MCP servers are independent.
        web = {
          search_backend = "searxng";
          extract_backend = "exa";
        };
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
