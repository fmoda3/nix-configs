{ config, lib, pkgs, ... }:
let
  cfg = config.my-home;

  extraPackages = with pkgs; [
    python3
    sudocode
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
    defaultProvider = if cfg.isWork then "anthropic" else "openai-codex";
    defaultModel = if cfg.isWork then "claude-sonnet-4-6" else "gpt-5.5";
    theme = "catppuccin-frappe";
    terminal = {
      showTerminalProgress = true;
    };
  };

  commonMcpServers = {
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

  keybindings = {
    "tui.input.newLine" = [ "shift+enter" "ctrl+j" ];
    "app.session.new" = "ctrl+shift+n";
    "app.session.tree" = "ctrl+shift+t";
    "app.session.fork" = "ctrl+shift+f";
    "app.session.resume" = "ctrl+shift+r";
    "tui.editor.cursorUp" = [ "up" "alt+k" ];
    "tui.editor.cursorDown" = [ "down" "alt+j" ];
    "tui.editor.cursorLeft" = [ "left" "alt+h" ];
    "tui.editor.cursorRight" = [ "right" "alt+l" ];
    "tui.editor.cursorWordLeft" = [ "alt+left" "alt+b" ];
    "tui.editor.cursorWordRight" = [ "alt+right" "alt+w" ];
  };

  extensions = with pkgs.piExtensions; [
    pi-ask-tool
    pi-context
    pi-direnv
    pi-ghostty
    pi-mcp-adapter
    pi-notify
    pi-plan
    pi-status-dashboard
    pi-processes
    pi-working-indicator
    pi-subagents
    pi-tasks
    pi-teams
  ];

  workModelsConfig = {
    providers = {
      anthropic = {
        baseUrl = "http://localhost:3456";
        apiKey = "toast-bedrock-adapter";
        api = "anthropic-messages";
      };
    };
  };

  workMcpServers = {
    atlassian = {
      url = "https://mcp.atlassian.com/v1/mcp";
      auth = "oauth";
    };
    buffet = {
      command = "npx";
      args = [
        "--registry=https://artifactory.eng.toasttab.com/artifactory/api/npm/toast_npm/"
        "@toasttab/buffet-mcp-server@next"
      ];
    };
    figma = {
      url = "http://127.0.0.1:3845/mcp";
    };
    sudocode = {
      command = "sudocode-mcp";
    };
  };

  mcpConfig = {
    settings = {
      autoAuth = true;
    };
    mcpServers = commonMcpServers // lib.optionalAttrs cfg.isWork workMcpServers;
  };
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
      } // lib.optionalAttrs cfg.isWork {
        ".pi/agent/models.json" = {
          text = builtins.toJSON workModelsConfig;
        };
      } // builtins.listToAttrs (map
        (extension: {
          name = ".pi/agent/extensions/${lib.getName extension}";
          value = {
            source = extension;
          };
        })
        extensions);
    };
  };
}
