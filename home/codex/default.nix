{ config, ... }:
{
  programs.codex = {
    enable = config.my-home.includeAI;
    # Let codex write runtime state (e.g. project trust) into config.toml;
    # declared settings are merged in on activation and take precedence.
    mutableSettings = true;
    settings = {
      model = "gpt-6.2-sol";
      model_reasoning_effort = "medium";
      mcp_servers = {
        context7 = {
          url = "https://mcp.context7.com/mcp";
        };
        deepwiki = {
          url = "https://mcp.deepwiki.com/mcp";
        };
      };
    };
    context = builtins.readFile ./config/AGENT.md;
  };

  # Codex prompts and skills are placed as files
  home = {
    file = {
      ".codex/prompts" = {
        source = ./config/prompts;
        recursive = true;
      };
    };
  };
}
