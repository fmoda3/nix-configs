{ config, lib, pkgs, ... }:
let
  cfg = config.my-home;

  settings = {
    defaultProvider = "openai-codex";
    defaultModel = "gpt-5.3-codex";
    theme = "catppuccin-frappe";
  };

  extensions = [
    { name = "pi-context"; package = pkgs.piExtensions.pi-context; }
    { name = "pi-notify"; package = pkgs.piExtensions.pi-notify; }
    { name = "pi-powerline-footer"; package = pkgs.piExtensions.pi-powerline-footer; }
    { name = "pi-subagents"; package = pkgs.piExtensions.pi-subagents; }
  ];
in
{
  config = lib.mkIf cfg.includeAI {
    home = {
      packages = [ pkgs.pi-coding-agent ];

      file = {
        ".pi/agent/settings.json" = {
          text = builtins.toJSON settings;
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
            recursive = true;
          };
        })
        extensions);
    };
  };
}
