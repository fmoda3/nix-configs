{
  programs.opencode = {
    enable = true;
    settings = {
      autoupdate = false;
      theme = "system";
      mcp = {
        context7 = {
          type = "remote";
          url = "https://mcp.context7.com/mcp";
        };
        deepwiki = {
          type = "remote";
          url = "https://mcp.deepwiki.com/mcp";
        };
        sequential-thinking = {
          type = "remote";
          url = "https://remote.mcpservers.org/sequentialthinking/mcp";
        };
      };
    };
  };
}
