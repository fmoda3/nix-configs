{ config, ... }:
{
  programs.codex = {
    enable = config.my-home.includeAI;
    settings = {
      model = "gpt-5.5";
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
