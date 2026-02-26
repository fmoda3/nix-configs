{ config, lib, pkgs, ... }:
let
  cfg = config.my-home;

  extraPackages = with pkgs; [
    python3
  ];

  wrappedPi = pkgs.symlinkJoin {
    name = "pi-coding-agent-wrapped";
    paths = [ pkgs.pi-coding-agent ];
    buildInputs = [ pkgs.makeBinaryWrapper ];
    postBuild = ''
      wrapProgram $out/bin/pi \
        --prefix PATH : ${pkgs.lib.makeBinPath extraPackages} \
        --set POWERLINE_NERD_FONTS 1
    '';
  };

  settings = {
    defaultProvider = "openai-codex";
    defaultModel = "gpt-5.3-codex";
    theme = "catppuccin-frappe";
  };

  mcpConfig = {
    mcpServers = {
      context7 = {
        url = "https://mcp.context7.com/mcp";
      };
      deepwiki = {
        url = "https://mcp.deepwiki.com/mcp";
      };
      sequential-thinking = {
        url = "https://remote.mcpservers.org/sequentialthinking/mcp";
      };
    };
  };

  keybindings = {
    newLine = [ "shift+enter" "ctrl+j" ];
    newSession = "ctrl+shift+n";
    tree = "ctrl+shift+t";
    fork = "ctrl+shift+f";
    resume = "ctrl+shift+r";
    cursorUp = [ "up" "alt+k" ];
    cursorDown = [ "down" "alt+j" ];
    cursorLeft = [ "left" "alt+h" ];
    cursorRight = [ "right" "alt+l" ];
    cursorWordLeft = [ "alt+left" "alt+b" ];
    cursorWordRight = [ "alt+right" "alt+w" ];
  };

  extensions = [
    { name = "pi-ask-tool"; package = pkgs.piExtensions.pi-ask-tool; }
    { name = "pi-context"; package = pkgs.piExtensions.pi-context; }
    { name = "pi-direnv"; package = pkgs.piExtensions.pi-direnv; }
    { name = "pi-ghostty"; package = pkgs.piExtensions.pi-ghostty; }
    { name = "pi-mcp-adapter"; package = pkgs.piExtensions.pi-mcp-adapter; }
    { name = "pi-notify"; package = pkgs.piExtensions.pi-notify; }
    { name = "pi-plan"; package = pkgs.piExtensions.pi-plan; }
    { name = "pi-powerline-footer"; package = pkgs.piExtensions.pi-powerline-footer; }
    { name = "pi-subagents"; package = pkgs.piExtensions.pi-subagents; }
  ];
in
{
  config = lib.mkIf cfg.includeAI {
    home = {
      packages = [ wrappedPi ];

      file = {
        ".pi/agent/settings.json" = {
          text = builtins.toJSON settings;
        };
        ".pi/agent/mcp.json" = {
          text = builtins.toJSON mcpConfig;
        };
        ".pi/agent/keybindings.json" = {
          text = builtins.toJSON keybindings;
        };
        ".pi/agent/AGENTS.md" = {
          source = ./config/AGENT.md;
        };
        ".pi/agent/prompts" = {
          source = ./config/prompts;
          recursive = true;
        };
        ".pi/agent/themes" = {
          source = ./config/themes;
          recursive = true;
        };
        ".pi/agent/agents" = {
          source = ./config/agents;
          recursive = true;
        };
      } // builtins.listToAttrs (map
        (ext: {
          name = ".pi/agent/extensions/${ext.name}";
          value = {
            source = ext.package;
          };
        })
        extensions);
    };
  };
}
