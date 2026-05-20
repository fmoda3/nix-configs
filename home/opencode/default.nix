{ config, ... }:
{
  programs.opencode = {
    enable = config.my-home.includeAI;
    settings = {
      autoupdate = false;
      mcp = {
        context7 = {
          type = "remote";
          url = "https://mcp.context7.com/mcp";
        };
        deepwiki = {
          type = "remote";
          url = "https://mcp.deepwiki.com/mcp";
        };
      };
    };
    tui = {
      theme = "catppuccin-frappe";
    };
    context = ./config/AGENT.md;
    agents = ./config/agents;
    commands = ./config/commands;
  };
}
