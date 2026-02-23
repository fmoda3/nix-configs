{ config, lib, pkgs, ... }:
let
  cfg = config.my-home;

  settings = {
    defaultProvider = "openai-codex";
    defaultModel = "gpt-5.3-codex";
    theme = "catppuccin-frappe";
  };
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
      };
    };
  };
}
