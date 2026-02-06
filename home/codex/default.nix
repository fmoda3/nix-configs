{ config, ... }:
{
  programs.codex = {
    enable = config.my-home.includeAI;
    settings = {
      mcp_servers = {
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
    custom-instructions = builtins.readFile ./config/AGENT.md;
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
