{ config, ... }:
{
  programs.opencode = {
    enable = config.my-home.includeAI;
    settings = {
      update = "disable";
      mcp.servers = {
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
    cli = {
      theme.name = "catppuccin-frappe";
    };
    validateFiles = {
      config = true;
      cli = true;
    };
    context = ./config/AGENT.md;
    agents = ./config/agents;
    commands = ./config/commands;
  };
}
